import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/admin/domain/admin_models.dart';
import 'package:promediacao/features/admin/presentation/admin_forms.dart';
import 'package:promediacao/features/admin/presentation/admin_home_page.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import '../auth/auth_test_helpers.dart';
import 'fake_admin_repository.dart';

const _sizes = <String, Size>{
  'desktop': Size(1280, 800),
  'tablet': Size(768, 1024),
  'telemóvel': Size(390, 844),
};

const _admin = AppSession(
  userId: 'u-admin',
  role: AppRole.admin,
  email: 'admin@exemplo.pt',
  fullName: 'Nome Que Nunca Aparece',
  method: SignInMethod.password,
);

Future<AppConnectivity> _pump(
  WidgetTester tester,
  FakeAdminRepository repo, {
  Size size = const Size(1280, 800),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final connectivity = AppConnectivity();
  final services = AppServices(
    auth: FakeAuthRepository(session: _admin),
    connectivity: connectivity,
  );
  await services.session.start();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AppScope(services: services, child: child!),
      home: Scaffold(body: AdminHomePage(repository: repo)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    services.dispose();
  });
  return connectivity;
}

/// Nenhum nome ou email de pessoa no ecrã.
void _expectNoPersonalData(WidgetTester tester) {
  expect(find.textContaining('@'), findsNothing);
  expect(find.textContaining('Nome Que Nunca Aparece'), findsNothing);
  expect(find.textContaining('Rui Costa'), findsNothing);
}

void main() {
  for (final e in _sizes.entries) {
    testWidgets('populado em ${e.key}: contagens, lista e colofão', (
      tester,
    ) async {
      await _pump(tester, FakeAdminRepository(), size: e.value);
      expect(find.text('Plataforma'), findsOneWidget);
      expect(find.text('Escritórios'), findsNWidgets(2)); // rótulo + secção
      expect(find.text('Mediadores'), findsOneWidget);
      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.textContaining('Só contagens'), findsOneWidget);
      expect(find.text('3 mediadores'), findsOneWidget);
      expect(find.text('1 mediador'), findsOneWidget);
      expect(find.text('Sem mediadores'), findsOneWidget);
      expect(find.text('Convidar mediador'), findsNWidgets(3));
      expect(find.text('Criar escritório'), findsOneWidget);
      expect(
        find.text('Administração da plataforma', skipOffstage: false),
        findsOneWidget,
      );
      _expectNoPersonalData(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vazio em ${e.key}', (tester) async {
      await _pump(
        tester,
        FakeAdminRepository(
          offices: [],
          counts: const AdminCounts(
            offices: 0,
            mediators: 0,
            clients: 0,
            requests: 0,
          ),
        ),
        size: e.value,
      );
      expect(find.text('Ainda não há escritórios.'), findsOneWidget);
      expect(find.textContaining('Crie o primeiro escritório'), findsOneWidget);
      expect(find.text('Criar escritório'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('erro em ${e.key} e tentar de novo', (tester) async {
      final repo = FakeAdminRepository()
        ..loadFailure = const AdminFailure(AdminFailureKind.unknown);
      await _pump(tester, repo, size: e.value);
      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
      expect(find.text('3 mediadores'), findsNothing);
      repo.loadFailure = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('3 mediadores'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offline em ${e.key}: dados ficam, ações bloqueadas', (
      tester,
    ) async {
      final repo = FakeAdminRepository();
      final conn = await _pump(tester, repo, size: e.value);
      conn.reportNetworkFailure();
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
      expect(find.textContaining('Criar e convidar ficam'), findsOneWidget);
      expect(find.text('3 mediadores'), findsOneWidget);
      await tester.tap(find.text('Criar escritório'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(CreateOfficeForm), findsNothing);
      await tester.tap(
        find.text('Convidar mediador').first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(InviteMediatorForm), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a carregar: blocos no lugar dos números, nunca "0"', (
    tester,
  ) async {
    final repo = FakeAdminRepository()..gate = Completer<void>();
    await _pump(tester, repo, settle: false);
    expect(find.text('0'), findsNothing);
    expect(find.text('12'), findsNothing);
    expect(find.byType(SkeletonRows), findsOneWidget);
    expect(find.text('Plataforma'), findsOneWidget);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.byType(SkeletonRows), findsNothing);
  });

  testWidgets('criar escritório (desktop): folha lateral e sucesso', (
    tester,
  ) async {
    final repo = FakeAdminRepository();
    await _pump(tester, repo);
    await tester.tap(find.text('Criar escritório'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateOfficeForm), findsOneWidget);
    // Folha à direita, 440 de largura.
    final panel = tester.getRect(find.byType(CreateOfficeForm));
    expect(panel.width, 440);
    expect(panel.right, 1280);
    // Desativado até haver nome, com a razão escrita.
    expect(find.text('Escreva o nome do escritório.'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(TextField),
      ),
      '  Mediação Douro Exemplo, Lda.  ',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.created, ['Mediação Douro Exemplo, Lda.']);
    expect(find.byType(CreateOfficeForm), findsNothing);
    expect(
      find.text('Escritório criado. Convide agora o primeiro mediador.'),
      findsOneWidget,
    );
    expect(find.text('Mediação Douro Exemplo, Lda.'), findsOneWidget);
    expect(find.text('4'), findsNWidgets(2)); // escritórios e mediadores
    expect(find.text('Sem mediadores'), findsNWidgets(2));
    _expectNoPersonalData(tester);
  });

  testWidgets('criar escritório: nome repetido e falha de ligação', (
    tester,
  ) async {
    final repo = FakeAdminRepository();
    final conn = await _pump(tester, repo);
    await tester.tap(find.text('Criar escritório'));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byType(CreateOfficeForm),
      matching: find.byType(TextField),
    );
    final submit = find.descendant(
      of: find.byType(CreateOfficeForm),
      matching: find.byType(PrimaryButton),
    );
    await tester.enterText(field, 'ribeira seguros');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Já existe um escritório com este nome.'), findsOneWidget);
    expect(repo.created, isEmpty);

    repo.createFailure = const AdminFailure(AdminFailureKind.network);
    await tester.enterText(field, 'Outro Escritório');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível ligar'), findsOneWidget);
    expect(conn.online, isFalse);
    expect(find.byType(CreateOfficeForm), findsOneWidget);
  });

  testWidgets('criar escritório (telemóvel): ecrã inteiro sem colofão', (
    tester,
  ) async {
    final repo = FakeAdminRepository();
    await _pump(tester, repo, size: const Size(390, 844));
    await tester.tap(find.text('Criar escritório'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateOfficeForm), findsOneWidget);
    expect(find.byType(Colophon), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(TextField),
      ),
      'Escritório Novo',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.created, ['Escritório Novo']);
    expect(find.byType(CreateOfficeForm), findsNothing);
    expect(find.text('Escritório Novo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final e in _sizes.entries) {
    testWidgets('convidar mediador em ${e.key}: o email não fica no ecrã', (
      tester,
    ) async {
      final repo = FakeAdminRepository();
      await _pump(tester, repo, size: e.value);
      await tester.ensureVisible(find.text('Convidar mediador').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convidar mediador').first);
      await tester.pumpAndSettle();
      expect(find.byType(InviteMediatorForm), findsOneWidget);
      expect(find.textContaining('O mediador recebe um email'), findsOneWidget);
      // O escritório vem preenchido (só leitura).
      final fields = find.descendant(
        of: find.byType(InviteMediatorForm),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(fields.at(2)).controller!.text,
        'Ribeira Seguros',
      );
      await tester.enterText(fields.at(0), 'Rui Costa');
      await tester.enterText(fields.at(1), 'rui.costa@exemplo.pt');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(InviteMediatorForm),
          matching: find.byType(PrimaryButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.invites, hasLength(1));
      expect(repo.invites.single.officeId, 'o1');
      expect(repo.invites.single.email, 'rui.costa@exemplo.pt');
      expect(repo.invites.single.fullName, 'Rui Costa');
      expect(find.byType(InviteMediatorForm), findsNothing);
      expect(find.text('Convite enviado.'), findsOneWidget);
      _expectNoPersonalData(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('convidar: email inválido bloqueia; email já usado dá erro', (
    tester,
  ) async {
    final repo = FakeAdminRepository()
      ..inviteFailure = const AdminFailure(AdminFailureKind.cannotInvite);
    await _pump(tester, repo);
    await tester.tap(find.text('Convidar mediador').first);
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(InviteMediatorForm),
      matching: find.byType(TextField),
    );
    final submit = find.descendant(
      of: find.byType(InviteMediatorForm),
      matching: find.byType(PrimaryButton),
    );
    await tester.enterText(fields.at(0), 'Rui Costa');
    await tester.enterText(fields.at(1), 'sem-arroba');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repo.invites, isEmpty);
    expect(
      find.text('Escreva um email completo, por exemplo nome@exemplo.pt.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(1), 'rui.costa@exemplo.pt');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Não foi possível convidar este email'),
      findsOneWidget,
    );
    expect(find.byType(InviteMediatorForm), findsOneWidget);
  });

  testWidgets('criado: "Convidar mediador" no aviso abre o convite', (
    tester,
  ) async {
    final repo = FakeAdminRepository(offices: []);
    await _pump(tester, repo);
    await tester.tap(find.text('Criar escritório'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(TextField),
      ),
      'Primeiro Escritório',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(CreateOfficeForm),
        matching: find.byType(PrimaryButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(InlineNotice),
        matching: find.text('Convidar mediador'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InviteMediatorForm), findsOneWidget);
    expect(find.text('Primeiro Escritório'), findsWidgets);
  });
}
