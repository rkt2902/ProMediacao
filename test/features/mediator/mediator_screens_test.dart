import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';
import 'package:promediacao/features/mediator/domain/mediator_models.dart';
import 'package:promediacao/features/mediator/domain/mediator_repository.dart';
import 'package:promediacao/features/mediator/presentation/clients_list.dart';
import 'package:promediacao/features/mediator/presentation/mediator_home_page.dart';

import '../auth/auth_test_helpers.dart';

/// Repositório de teste: tudo controlável, sem rede.
class FakeMediatorRepository implements MediatorRepository {
  FakeMediatorRepository(this.clock, [List<OfficeClient>? items])
    : items = items ?? [];

  final DateTime Function() clock;
  final List<OfficeClient> items;
  Completer<void>? gate;
  MediatorFailure? listFailure;
  MediatorFailure? createFailure;
  MediatorFailure? resendFailure;
  final List<({String name, String email})> created = [];
  final List<String> resent = [];
  final List<({int limit, int offset})> listCalls = [];

  @override
  Future<List<OfficeClient>> listClients({
    required int limit,
    required int offset,
  }) async {
    listCalls.add((limit: limit, offset: offset));
    if (gate != null) await gate!.future;
    if (listFailure != null) throw listFailure!;
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<void> createClient({
    required String fullName,
    required String email,
  }) async {
    if (createFailure != null) throw createFailure!;
    created.add((name: fullName, email: email));
    items.add(
      OfficeClient(
        grantId: 'g-new-${created.length}',
        fullName: fullName,
        email: email,
        status: ClientStatus.pendente,
        updatedAt: clock(),
      ),
    );
  }

  @override
  Future<void> resendRequest(String grantId) async {
    if (resendFailure != null) throw resendFailure!;
    resent.add(grantId);
    final i = items.indexWhere((c) => c.grantId == grantId);
    final c = items[i];
    items[i] = OfficeClient(
      grantId: c.grantId,
      fullName: c.fullName,
      email: c.email,
      status: c.status,
      updatedAt: clock(),
    );
  }
}

OfficeClient client(
  String id,
  String name,
  String email,
  ClientStatus status,
  DateTime at,
) => OfficeClient(
  grantId: id,
  fullName: name,
  email: email,
  status: status,
  updatedAt: at,
);

/// Fixtures do 03-design.md.
List<OfficeClient> fixtures() => [
  client(
    'g1',
    'João Pedro Albuquerque de Vasconcelos Sampaio',
    'joao.pedro.albuquerque.vasconcelos@correio-exemplo.pt',
    ClientStatus.pendente,
    DateTime(2026, 11, 26, 15, 4),
  ),
  client(
    'g2',
    'Construções Teixeira & Irmão, Unipessoal Lda.',
    'geral@construcoes-teixeira-exemplo.pt',
    ClientStatus.pendente,
    DateTime(2026, 11, 25, 15, 4),
  ),
  client(
    'g3',
    'Rita Fonseca (exemplo)',
    'rita.fonseca@exemplo.pt',
    ClientStatus.recusado,
    DateTime(2026, 11, 20, 9, 12),
  ),
  client(
    'g4',
    'Maria do Carmo Figueiredo',
    'maria.figueiredo@exemplo.pt',
    ClientStatus.ativo,
    DateTime(2026, 11, 12, 10, 4),
  ),
];

final _mediator = AppSession(
  userId: 'u-med',
  role: AppRole.mediador,
  email: 'ana@ribeira.pt',
  fullName: 'Ana Martins',
  createdAt: DateTime.utc(2026, 11, 3),
  method: SignInMethod.password,
  officeName: 'Ribeira Seguros',
  officeJoinedAt: DateTime.utc(2026, 11, 3),
);

class Harness {
  Harness(this.repo, this.connectivity, this.clock);
  final FakeMediatorRepository repo;
  final AppConnectivity connectivity;
  DateTime Function() clock;
}

Future<Harness> pumpMediator(
  WidgetTester tester,
  FakeMediatorRepository repo, {
  Size size = const Size(1280, 800),
  double textScale = 1.0,
  DateTime Function()? clock,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository(session: _mediator);
  final connectivity = AppConnectivity(probe: auth.isReachable);
  final services = AppServices(
    auth: auth,
    prompts: MemoryPasswordPromptStore(),
    connectivity: connectivity,
  );
  await services.session.start();
  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
        home: MediatorHomePage(repository: repo, now: clock),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    services.dispose();
  });
  return Harness(repo, connectivity, clock ?? DateTime.now);
}

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 11, 26, 15, 4, 10));

  FakeMediatorRepository repoWith([List<OfficeClient>? items]) =>
      FakeMediatorRepository(clock, items ?? fixtures());

  group('lista nos três tamanhos', () {
    for (final e in {
      ...testSizes,
      'telemóvel estreito': const Size(320, 640),
    }.entries) {
      testWidgets('populado, sem overflow, ${e.key}', (tester) async {
        await pumpMediator(tester, repoWith(), size: e.value, clock: clock);
        expect(tester.takeException(), isNull);
        expect(find.text('Clientes'), findsOneWidget);
        expect(
          find.text('4 clientes · 2 pendentes · 1 recusado'),
          findsOneWidget,
        );
        expect(find.text('Maria do Carmo Figueiredo'), findsOneWidget);
        expect(find.text('ATIVO'), findsOneWidget);
        expect(find.text('PENDENTE'), findsNWidgets(2));
        expect(find.text('RECUSADO'), findsOneWidget);
        // Só os pendentes têm "Reenviar pedido".
        expect(find.text('Reenviar pedido'), findsNWidgets(2));
        expect(find.text('Desde 12 nov 2026'), findsOneWidget);
        expect(find.text('Enviado a 26 nov 2026, 15:04'), findsOneWidget);
        expect(find.text('Recusado a 20 nov 2026, 09:12'), findsOneWidget);
        // Colofão do mediador.
        expect(
          find.textContaining(
            'Ana Martins, Ribeira Seguros',
            findRichText: true,
          ),
          findsOneWidget,
        );
        // Sem scroll horizontal.
        expect(tester.getSize(find.byType(PageFrame)).width, e.value.width);
      });
    }

    testWidgets('desktop: tabela de 4 colunas com cabeçalhos', (tester) async {
      await pumpMediator(tester, repoWith(), clock: clock);
      for (final h in ['Cliente', 'Estado', 'Data']) {
        expect(find.text(h), findsOneWidget);
      }
      // "Criar cliente" na linha do título, à direita.
      final title = tester.getTopLeft(find.text('Clientes')).dy;
      final button = tester.getRect(
        find.widgetWithText(PrimaryButton, 'Criar cliente'),
      );
      expect(button.top - title, lessThan(60));
      expect(button.height, AppSize.alvoMinimo);
    });

    testWidgets('tablet: 3 colunas (Estado e data juntos, sem coluna Data)', (
      tester,
    ) async {
      await pumpMediator(
        tester,
        repoWith(),
        size: const Size(768, 1024),
        clock: clock,
      );
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Data'), findsNothing);
      final stamp = tester.getRect(find.text('ATIVO'));
      final date = tester.getRect(find.text('Desde 12 nov 2026'));
      expect(date.top, greaterThan(stamp.bottom - 1));
    });

    testWidgets(
      'telemóvel: empilhado, sem cabeçalhos, botão a toda a largura',
      (tester) async {
        await pumpMediator(
          tester,
          repoWith(),
          size: const Size(390, 844),
          clock: clock,
        );
        expect(find.text('Cliente'), findsNothing);
        expect(find.text('Estado'), findsNothing);
        final button = tester.getRect(
          find.widgetWithText(PrimaryButton, 'Criar cliente'),
        );
        expect(button.height, AppSize.alvoPrincipal);
        expect(button.width, 390 - 2 * AppSpace.s16);
      },
    );

    test('regra dos 240: desce um nível quando a coluna Cliente é curta', () {
      ClientsLayout l(double w, Breakpoint b, [double s = 1]) =>
          chooseClientsLayout(width: w, breakpoint: b, textScale: s);
      expect(l(1040, Breakpoint.largo), ClientsLayout.table4);
      expect(l(1040, Breakpoint.largo, 1.3), ClientsLayout.table4);
      expect(l(900, Breakpoint.largo, 1.3), ClientsLayout.table3);
      expect(l(704, Breakpoint.medio), ClientsLayout.table3);
      expect(l(576, Breakpoint.medio), ClientsLayout.stacked);
      expect(l(704, Breakpoint.medio, 1.3), ClientsLayout.stacked);
      expect(l(358, Breakpoint.compacto), ClientsLayout.stacked);
    });

    testWidgets('escala de texto 1.3 no tablet não parte o layout', (
      tester,
    ) async {
      await pumpMediator(
        tester,
        repoWith(),
        size: const Size(768, 1024),
        textScale: 1.3,
        clock: clock,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Reenviar pedido'), findsNWidgets(2));
    });
  });

  group('estados', () {
    testWidgets('vazio: só o botão do estado vazio', (tester) async {
      await pumpMediator(tester, repoWith([]), clock: clock);
      expect(find.text('Ainda não tem clientes'), findsOneWidget);
      expect(find.textContaining('Ribeira Seguros.'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Criar cliente'),
        findsOneWidget,
      );
    });

    testWidgets('a carregar: skeleton com título e botão visíveis', (
      tester,
    ) async {
      final repo = repoWith()..gate = Completer<void>();
      await pumpMediator(tester, repo, clock: clock, settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SkeletonRows), findsOneWidget);
      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('Criar cliente'), findsOneWidget);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonRows), findsNothing);
      expect(find.text('Maria do Carmo Figueiredo'), findsOneWidget);
    });

    testWidgets('erro: mensagem sem texto técnico e Tentar de novo', (
      tester,
    ) async {
      final repo = repoWith()
        ..listFailure = const MediatorFailure(MediatorFailureKind.unknown);
      await pumpMediator(tester, repo, clock: clock);
      expect(
        find.text('Não foi possível carregar os clientes. Tente de novo.'),
        findsOneWidget,
      );
      repo.listFailure = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Maria do Carmo Figueiredo'), findsOneWidget);
    });

    testWidgets('offline: faixa e ações bloqueadas com a razão escrita', (
      tester,
    ) async {
      final h = await pumpMediator(tester, repoWith(), clock: clock);
      h.connectivity.reportNetworkFailure();
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
      expect(
        find.text('Precisa de ligação.'),
        findsNWidgets(3),
      ); // criar + 2 reenvios
      await tester.tap(find.text('Criar cliente'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsNothing);
      h.connectivity.dispose();
    });

    testWidgets('paginação: 25 por página e "Mostrar mais 25"', (tester) async {
      final many = [
        for (var i = 0; i < 30; i++)
          client(
            'x$i',
            'Cliente $i',
            'c$i@exemplo.pt',
            ClientStatus.ativo,
            DateTime(2026, 10, 1).add(Duration(hours: i)),
          ),
      ];
      final repo = repoWith(many);
      await pumpMediator(
        tester,
        repo,
        size: const Size(1280, 4000),
        clock: clock,
      );
      expect(find.text('Mostrar mais 25'), findsOneWidget);
      expect(find.textContaining('Cliente '), findsNWidgets(25));
      await tester.tap(find.text('Mostrar mais 25'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar mais 25'), findsNothing);
      expect(repo.listCalls.last.offset, 25);
    });
  });

  group('reenviar pedido (bloqueio de 60 s)', () {
    for (final e in testSizes.entries) {
      testWidgets('bloqueia 60 s com a razão escrita, ${e.key}', (
        tester,
      ) async {
        final repo = repoWith();
        await pumpMediator(tester, repo, size: e.value, clock: clock);
        // O pedido g2 (25 nov) pode ser reenviado.
        await tester.tap(find.text('Reenviar pedido').last);
        await tester.pumpAndSettle();
        expect(repo.resent, ['g2']);
        expect(
          find.text(
            'Pedido reenviado a geral@construcoes-teixeira-exemplo.pt.',
          ),
          findsOneWidget,
        );
        // 15:04:10 + 60 s = 15:05:10, mostra o minuto seguinte.
        expect(find.text('Pode reenviar às 15:06'), findsOneWidget);
        expect(find.text('Reenviar pedido'), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        // O outro continua ativo; este está desativado.
        repo.resent.clear();
        await tester.tap(
          find.text('Pode reenviar às 15:06'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(repo.resent, isEmpty);

        // Passados 61 s volta a estar ativo.
        now = now.add(const Duration(seconds: 61));
        await tester.pump(const Duration(seconds: 61));
        await tester.pumpAndSettle();
        expect(find.textContaining('Pode reenviar às'), findsNothing);
        await tester.tap(find.text('Reenviar pedido').first);
        await tester.pumpAndSettle();
        expect(repo.resent, hasLength(1));
      });
    }

    testWidgets('too_soon do servidor mostra o bloqueio sem erro', (
      tester,
    ) async {
      final repo = repoWith()
        ..resendFailure = const MediatorFailure(
          MediatorFailureKind.tooSoon,
          retryAfterSeconds: 30,
        );
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Reenviar pedido').last);
      await tester.pumpAndSettle();
      expect(find.text('Pode reenviar às 15:05'), findsNWidgets(2));
      expect(find.textContaining('Não foi possível'), findsNothing);
    });

    testWidgets('pedido enviado há menos de 60 s já nasce bloqueado', (
      tester,
    ) async {
      final repo = repoWith([
        client(
          'g9',
          'Luís Almeida',
          'luis@exemplo.pt',
          ClientStatus.pendente,
          DateTime(2026, 11, 26, 15, 4, 0),
        ),
      ]);
      await pumpMediator(tester, repo, clock: clock);
      expect(find.text('Pode reenviar às 15:05'), findsOneWidget);
    });

    testWidgets('falha de envio mostra erro sem texto técnico', (tester) async {
      final repo = repoWith()
        ..resendFailure = const MediatorFailure(MediatorFailureKind.sendFailed);
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Reenviar pedido').last);
      await tester.pumpAndSettle();
      expect(
        find.text('O pedido não seguiu. Tente Reenviar pedido daqui a pouco.'),
        findsOneWidget,
      );
    });
  });

  group('criar cliente', () {
    testWidgets('desktop: folha lateral de 440, valida, envia e fecha', (
      tester,
    ) async {
      final repo = repoWith();
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsOneWidget);
      final sheet = tester.getRect(
        find
            .ancestor(
              of: find.text('Nome completo'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(sheet.width, lessThanOrEqualTo(AppSize.folhaLateral));
      expect(tester.getTopRight(find.byType(PageFrame)).dx, 1280);

      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Escreva o nome do cliente.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '  Maria Teste ');
      await tester.enterText(find.byType(EditableText).last, 'sem-arroba');
      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escreva um email completo, por exemplo nome@exemplo.pt.'),
        findsOneWidget,
      );
      expect(repo.created, isEmpty);

      await tester.enterText(
        find.byType(EditableText).last,
        'maria.teste@exemplo.pt',
      );
      await tester.testTextInput.receiveAction(
        TextInputAction.done,
      ); // Enter submete
      await tester.pumpAndSettle();
      expect(repo.created.single, (
        name: 'Maria Teste',
        email: 'maria.teste@exemplo.pt',
      ));
      expect(find.text('Nome completo'), findsNothing);
      expect(
        find.text(
          'Pedido enviado a maria.teste@exemplo.pt. O acesso fica pendente até o cliente aceitar.',
        ),
        findsOneWidget,
      );
      expect(find.text('Maria Teste'), findsOneWidget);
    });

    testWidgets('Esc fecha a folha sem criar nada', (tester) async {
      final repo = repoWith();
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsNothing);
      expect(repo.created, isEmpty);
    });

    testWidgets('tablet: folha lateral também', (tester) async {
      await pumpMediator(
        tester,
        repoWith(),
        size: const Size(768, 1024),
        clock: clock,
      );
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      expect(find.text('Criar e enviar pedido'), findsOneWidget);
      expect(
        find.text('Clientes'),
        findsOneWidget,
      ); // a lista fica por trás do véu
    });

    testWidgets('telemóvel: ecrã inteiro com botões no fluxo e "voltar"', (
      tester,
    ) async {
      final repo = repoWith();
      await pumpMediator(
        tester,
        repo,
        size: const Size(390, 844),
        clock: clock,
      );
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      // Sem colofão no ecrã inteiro.
      expect(find.byType(Colophon), findsNothing);
      final submit = tester.getRect(
        find.widgetWithText(PrimaryButton, 'Criar e enviar pedido'),
      );
      expect(submit.width, 390 - 2 * AppSpace.s16);
      expect(submit.height, AppSize.alvoPrincipal);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsNothing);
      expect(find.text('Clientes'), findsOneWidget);
    });

    testWidgets('email que já é cliente: erro no campo, sem texto técnico', (
      tester,
    ) async {
      final repo = repoWith()
        ..createFailure = const MediatorFailure(
          MediatorFailureKind.alreadyClient,
        );
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Maria');
      await tester.enterText(
        find.byType(EditableText).last,
        'maria@exemplo.pt',
      );
      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pumpAndSettle();
      expect(
        find.text('Este email já é cliente da Ribeira Seguros.'),
        findsOneWidget,
      );
      expect(
        find.text('Nome completo'),
        findsOneWidget,
      ); // a folha continua aberta
    });

    testWidgets('pedido criado mas email não seguiu: aviso e a linha existe', (
      tester,
    ) async {
      final repo = repoWith()..createFailure = null;
      await pumpMediator(tester, repo, clock: clock);
      // Simula send_failed depois de criar: o fake cria e lança.
      final failing = _CreateThenSendFail(repo);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpMediator(tester, failing, clock: clock);
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Rui Novo');
      await tester.enterText(find.byType(EditableText).last, 'rui@exemplo.pt');
      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'O cliente foi criado, mas o pedido não seguiu. Tente Reenviar pedido daqui a pouco.',
        ),
        findsOneWidget,
      );
      expect(find.text('Rui Novo'), findsOneWidget);
    });

    testWidgets('sem ligação a meio: erro de ligação e texto preservado', (
      tester,
    ) async {
      final repo = repoWith()
        ..createFailure = const MediatorFailure(MediatorFailureKind.network);
      await pumpMediator(tester, repo, clock: clock);
      await tester.tap(find.text('Criar cliente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Maria');
      await tester.enterText(
        find.byType(EditableText).last,
        'maria@exemplo.pt',
      );
      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Não foi possível ligar. Verifique a ligação e tente de novo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Maria'), findsOneWidget);
    });
  });
}

class _CreateThenSendFail extends FakeMediatorRepository {
  _CreateThenSendFail(FakeMediatorRepository base)
    : super(base.clock, [...base.items]);

  @override
  Future<void> createClient({
    required String fullName,
    required String email,
  }) async {
    await super.createClient(fullName: fullName, email: email);
    throw const MediatorFailure(MediatorFailureKind.sendFailed);
  }
}
