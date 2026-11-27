import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/mediator/presentation/new_request_page.dart';
import 'package:promediacao/features/mediator/presentation/new_request_sections.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../auth/auth_test_helpers.dart';
import '../requests/fake_requests_repository.dart';
import 'request_test_helpers.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _check(WidgetTester tester, String type) async {
  await _tap(tester, find.byKey(ValueKey('tipo-$type')));
  await tester.pumpAndSettle();
}

Future<void> _create(WidgetTester tester) async {
  final b = find.byType(PrimaryButton);
  await _tap(tester, b);
  await tester.pumpAndSettle();
}

void main() {
  const preselected = NewRequestPage(clientId: 'c-maria', fromClientFile: true);

  for (final e in testSizes.entries) {
    testWidgets('com cliente da ficha, sem tipos, ${e.key}', (tester) async {
      await pumpPage(tester, preselected, size: e.value);
      expect(tester.takeException(), isNull);
      expect(find.text('Novo pedido'), findsOneWidget);
      expect(find.text('Maria do Carmo Figueiredo'), findsWidgets);
      expect(find.text('Mudar'), findsOneWidget);
      expect(find.text('Automóvel'), findsOneWidget);
      expect(find.text('Vida'), findsOneWidget);
      // Folha vazia tracejada e botão desativado com a razão escrita.
      expect(
        find.textContaining('Escolha pelo menos um tipo de seguro para'),
        findsOneWidget,
      );
      expect(
        find.text('Escolha pelo menos um tipo de seguro.'),
        findsOneWidget,
      );
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Criar pedido'),
      );
      expect(button.onPressed, isNull);
      // Regresso à ficha com o nome do cliente.
      expect(find.text('Maria do Carmo Figueiredo'), findsWidgets);
    });

    testWidgets('dois tipos: folhas, barra e criar, ${e.key}', (tester) async {
      final h = await pumpPage(tester, preselected, size: e.value);
      await _check(tester, 'automovel');
      await _check(tester, 'vida');
      expect(tester.takeException(), isNull);
      expect(find.text('Criar 2 pedidos'), findsOneWidget);
      expect(
        find.text('2 pedidos para Maria do Carmo Figueiredo'),
        findsOneWidget,
      );
      expect(find.text('Pedido 1 de 2'), findsOneWidget);
      expect(find.text('Pedido 2 de 2'), findsOneWidget);
      expect(find.text('O cliente vai receber'), findsOneWidget);
      expect(find.textContaining('Se o condutor habitual'), findsOneWidget);

      await _create(tester);
      final call = h.repo.createCalls.single;
      expect(call.clientId, 'c-maria');
      expect(
        [for (final r in call.requests) r.typeCode],
        ['automovel', 'vida'],
      );
      expect(call.allowPolicyConditions, isFalse);
      // Navega para a ficha e o resultado fica na passagem.
      expect(find.text('FICHA c-maria'), findsOneWidget);
    });
  }

  testWidgets('tirar, repor e acrescentar item livre', (tester) async {
    final h = await pumpPage(tester, preselected);
    await _check(tester, 'automovel');
    expect(find.text('Cartão de Cidadão'), findsOneWidget);

    await _tap(
      tester,
      find.bySemanticsLabel('Tirar Cartão de Cidadão do pedido de Automóvel'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cartão de Cidadão'), findsNothing);
    expect(find.text('1 item tirado · '), findsOneWidget);

    await _tap(tester, find.text('Repor lista'));
    await tester.pumpAndSettle();
    expect(find.text('Cartão de Cidadão'), findsOneWidget);
    expect(find.text('1 item tirado · '), findsNothing);

    // Acrescentar: vazio dá erro; Dado a preencher; Enter acrescenta.
    await _tap(tester, find.text('Acrescentar item'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(SecondaryButton, 'Acrescentar'));
    await tester.pumpAndSettle();
    expect(find.text('Escreva o item a pedir.'), findsOneWidget);
    await _tap(tester, find.text('Dado a preencher'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AddItemBox),
        matching: find.byType(TextField),
      ),
      'Matrícula anterior',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Matrícula anterior'), findsOneWidget);
    expect(find.text('Acrescentado neste pedido'), findsOneWidget);

    // Esc cancela a caixa.
    await _tap(tester, find.text('Acrescentar item'));
    await tester.pumpAndSettle();
    expect(find.text('Novo item'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Novo item'), findsNothing);

    await _create(tester);
    final items = h.repo.createCalls.single.requests.single.items;
    expect(items.whereType<CatalogDraftItem>(), hasLength(3));
    final free = items.whereType<FreeDraftItem>().single;
    expect(free.label, 'Matrícula anterior');
    expect(free.kind, ItemKind.data);
  });

  testWidgets('lista vazia: erro na folha e criar desativado', (tester) async {
    await pumpPage(tester, preselected);
    await _check(tester, 'vida');
    await _tap(
      tester,
      find.bySemanticsLabel('Tirar Cartão de Cidadão do pedido de Vida'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('A lista de Vida está vazia.'), findsWidgets);
    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Criar 1 pedido'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('condições particulares e mensagem com contador de 500', (
    tester,
  ) async {
    final h = await pumpPage(tester, preselected);
    await _check(tester, 'vida');
    expect(
      find.textContaining('Pode enviar as condições particulares'),
      findsNothing,
    );
    await _tap(tester, find.text('Permitir condições particulares'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Pode enviar as condições particulares'),
      findsOneWidget,
    );
    expect(find.textContaining('· com condições particulares'), findsOneWidget);

    expect(find.text('0 / 500'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Bom dia');
    await tester.pump();
    expect(find.text('7 / 500'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'x' * 501);
    await tester.pumpAndSettle();
    expect(find.text('501 / 500'), findsOneWidget);
    expect(
      find.text('Encurte a mensagem para 500 caracteres.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Criar 1 pedido'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).last, 'Bom dia');
    await tester.pump();
    await _create(tester);
    expect(h.repo.createCalls.single.allowPolicyConditions, isTrue);
    expect(h.repo.createCalls.single.message, 'Bom dia');
  });

  testWidgets('pedido repetido: aviso, confirmação e envio', (tester) async {
    final repo = FakeRequestsRepository();
    repo.openTypes['c-maria'] = [
      OpenType(
        typeCode: 'automovel',
        typeName: 'Automóvel',
        openCount: 1,
        firstCreatedAt: DateTime(2026, 11, 20, 16, 40),
        lastCreatedAt: DateTime(2026, 11, 20, 16, 40),
        maxStage: RequestStage.created,
      ),
    ];
    await pumpPage(tester, preselected, repo: repo);
    expect(find.text('Em curso desde 20 nov 2026'), findsOneWidget);

    await _check(tester, 'automovel');
    expect(
      find.text('Já existe um pedido de Automóvel em curso.'),
      findsOneWidget,
    );
    expect(find.text('À espera da sua confirmação'), findsOneWidget);
    expect(find.text('Automóvel à espera de confirmação'), findsOneWidget);
    expect(
      find.text('Confirme o pedido repetido ou tire esse tipo.'),
      findsOneWidget,
    );

    await _tap(tester, find.text('Criar outro na mesma'));
    await tester.pumpAndSettle();
    expect(
      find.text('Vai ser criado um segundo pedido de Automóvel.'),
      findsOneWidget,
    );
    await _create(tester);
    expect(repo.createCalls.single.requests.single.confirmRepeat, isTrue);
  });

  testWidgets('"Tirar este tipo" desfaz a escolha do tipo repetido', (
    tester,
  ) async {
    final repo = FakeRequestsRepository();
    repo.openTypes['c-maria'] = [
      OpenType(
        typeCode: 'vida',
        typeName: 'Vida',
        openCount: 1,
        firstCreatedAt: DateTime(2026, 11, 20),
        lastCreatedAt: DateTime(2026, 11, 20),
        maxStage: RequestStage.created,
      ),
    ];
    await pumpPage(tester, preselected, repo: repo);
    await _check(tester, 'vida');
    await _tap(tester, find.text('Tirar este tipo'));
    await tester.pumpAndSettle();
    expect(find.text('Já existe um pedido de Vida em curso.'), findsNothing);
    expect(find.text('Escolha pelo menos um tipo de seguro.'), findsOneWidget);
  });

  testWidgets('falha ao criar: nada criado e a escolha mantém-se', (
    tester,
  ) async {
    final repo = FakeRequestsRepository()
      ..createFailure = const RequestFailure(RequestFailureKind.unknown);
    await pumpPage(tester, preselected, repo: repo);
    await _check(tester, 'vida');
    await _create(tester);
    expect(find.textContaining('Nada foi criado.'), findsOneWidget);
    expect(find.text('FICHA c-maria'), findsNothing);
    // Mantém-se e pode tentar de novo.
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Criar 1 pedido'),
          )
          .onPressed,
      isNotNull,
    );
    repo.createFailure = null;
    await _create(tester);
    expect(find.text('FICHA c-maria'), findsOneWidget);
    expect(repo.createCalls, hasLength(2));
  });

  testWidgets('a concessão deixou de estar ativa', (tester) async {
    final repo = FakeRequestsRepository()
      ..createFailure = const RequestFailure(
        RequestFailureKind.clientNotAvailable,
      );
    await pumpPage(tester, preselected, repo: repo);
    await _check(tester, 'vida');
    await _create(tester);
    expect(
      find.text('Este cliente já não partilha dados consigo.'),
      findsWidgets,
    );
    expect(find.textContaining('Nenhum pedido foi criado.'), findsOneWidget);
    await _tap(tester, find.text('Voltar a Clientes'));
    await tester.pumpAndSettle();
    expect(find.text('LISTA DE CLIENTES'), findsOneWidget);
  });

  testWidgets('offline: tudo editável, criar desativado com a razão', (
    tester,
  ) async {
    final h = await pumpPage(tester, preselected);
    await _check(tester, 'vida');
    h.connectivity.reportNetworkFailure();
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
    expect(
      find.textContaining('A sua escolha fica guardada neste ecrã'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'Criar 1 pedido'),
          )
          .onPressed,
      isNull,
    );
    // Continua editável.
    await _check(tester, 'automovel');
    expect(find.text('Criar 2 pedidos'), findsOneWidget);
  });

  testWidgets('a criar: botão com "A criar…" e sem duplicar', (tester) async {
    final repo = FakeRequestsRepository();
    final gate = Completer<void>();
    final h = await pumpPage(tester, preselected, repo: repo);
    await _check(tester, 'vida');
    repo.gate = gate;
    await _tap(tester, find.widgetWithText(PrimaryButton, 'Criar 1 pedido'));
    await tester.pump();
    expect(find.text('A criar…'), findsOneWidget);
    await tester.tap(find.text('A criar…'), warnIfMissed: false);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(repo.createCalls, hasLength(1));
    expect(h.location, '/mediador/clientes/c-maria');
  });

  testWidgets('catálogo a carregar e erro com "Tentar de novo"', (
    tester,
  ) async {
    final repo = FakeRequestsRepository()
      ..failNext = const RequestFailure(RequestFailureKind.unknown);
    await pumpPage(tester, preselected, repo: repo);
    expect(
      find.textContaining('Não foi possível carregar os tipos'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Automóvel'), findsOneWidget);
  });

  testWidgets('a carregar: skeleton e depois os tipos', (tester) async {
    final repo = FakeRequestsRepository();
    final gate = Completer<void>();
    repo.gate = gate;
    await pumpPage(tester, preselected, repo: repo, settle: false);
    await tester.pump();
    expect(find.byType(SkeletonRows), findsWidgets);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Automóvel'), findsOneWidget);
  });

  group('escolher o cliente', () {
    const page = NewRequestPage();

    testWidgets('lista os ativos, pesquisa e escolhe; "Mudar" volta', (
      tester,
    ) async {
      await pumpPage(tester, page);
      expect(find.text('Procurar por nome ou email'), findsOneWidget);
      expect(find.text('Maria do Carmo Figueiredo'), findsOneWidget);
      expect(find.text('João Lima'), findsOneWidget);
      expect(
        find.textContaining('Só aparecem clientes que aceitaram'),
        findsOneWidget,
      );
      expect(
        find.text('Escolha o cliente e pelo menos um tipo.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, 'joão');
      await tester.pumpAndSettle();
      expect(find.text('Maria do Carmo Figueiredo'), findsNothing);
      await _tap(tester, find.text('João Lima'));
      await tester.pumpAndSettle();
      expect(find.text('Mudar'), findsOneWidget);
      expect(find.text('joao.lima@exemplo.pt'), findsOneWidget);

      await _tap(tester, find.text('Mudar'));
      await tester.pumpAndSettle();
      expect(find.text('Procurar por nome ou email'), findsOneWidget);
    });

    testWidgets('teclado: setas, Enter escolhe e Esc fecha', (tester) async {
      await pumpPage(tester, page);
      await _tap(tester, find.byType(TextField).first);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('João Lima'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('João Lima'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('joao.lima@exemplo.pt'), findsOneWidget);
      expect(find.text('Mudar'), findsOneWidget);
    });

    testWidgets('sem clientes ativos: estado vazio', (tester) async {
      await pumpPage(tester, page, repo: FakeRequestsRepository(clients: []));
      expect(
        find.text('Ainda não tem clientes com acesso ativo'),
        findsOneWidget,
      );
      expect(find.text('Criar cliente'), findsOneWidget);
      expect(find.text('Ver clientes pendentes'), findsOneWidget);
      expect(find.byType(CheckRow), findsNothing);
    });
  });

  group('cliente pré-escolhido sem acesso', () {
    testWidgets('pendente: motivo e "Reenviar pedido de partilha"', (
      tester,
    ) async {
      final repo = FakeRequestsRepository(
        headers: {
          'c-ana': ClientHeader(
            clientId: 'c-ana',
            access: ClientAccess.pending,
            grantId: 'g-ana',
            fullName: 'Ana Pendente',
            email: 'ana@exemplo.pt',
            since: DateTime(2026, 11, 26, 15, 4),
          ),
        },
      );
      await pumpPage(
        tester,
        const NewRequestPage(clientId: 'c-ana'),
        repo: repo,
      );
      expect(
        find.text('Não é possível criar pedidos para este cliente.'),
        findsOneWidget,
      );
      expect(
        find.text('Ainda não aceitou. Reenvie o pedido de partilha.'),
        findsOneWidget,
      );
      expect(find.text('Reenviar pedido de partilha'), findsOneWidget);
      expect(find.text('PENDENTE'), findsOneWidget);
      expect(find.byType(CheckRow), findsNothing);
    });

    testWidgets('recusada e inexistente', (tester) async {
      final repo = FakeRequestsRepository(
        headers: {
          'c-rita': ClientHeader(
            clientId: 'c-rita',
            access: ClientAccess.declined,
            fullName: 'Rita',
            email: 'rita@exemplo.pt',
          ),
        },
      );
      await pumpPage(
        tester,
        const NewRequestPage(clientId: 'c-rita'),
        repo: repo,
      );
      expect(
        find.text('Recusou a partilha. Não é possível criar pedidos.'),
        findsOneWidget,
      );
      expect(find.text('Reenviar pedido de partilha'), findsNothing);
    });

    testWidgets('outro escritório ou inexistente: "Sem acesso"', (
      tester,
    ) async {
      await pumpPage(tester, const NewRequestPage(clientId: 'c-x'));
      expect(find.text('Sem acesso'), findsOneWidget);
      await _tap(tester, find.text('Voltar a Clientes'));
      await tester.pumpAndSettle();
      expect(find.text('LISTA DE CLIENTES'), findsOneWidget);
    });
  });
}
