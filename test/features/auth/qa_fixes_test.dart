// Regressão dos bugs do qa da 001 (05-qa.md) do lado da app: 2
// (recuperação), 3 (link expirado), 4 (pedido antes do convite) e 6 (sessão
// por link de mediador ou admin).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/router.dart';
import 'package:promediacao/app/routes.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/auth/application/session_controller.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import 'auth_test_helpers.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabeledField)),
  matching: find.byType(EditableText),
);

Future<void> _tap(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

/// Como `pumpAuthApp`, mas com o [SessionController] montado pelo teste.
Future<AppServices> _pump(
  WidgetTester tester,
  FakeAuthRepository repo,
  SessionController session, {
  String? location,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(auth: repo, session: session);
  await tester.pumpWidget(
    ProMediacaoApp(
      services: services,
      initialLocation: location,
      builders: stubRouteBuilders,
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return services;
}

AppSession _staff(AppRole role, SignInMethod method) => AppSession(
  userId: 'u-${role.name}',
  role: role,
  email: '${role.name}@exemplo.pt',
  method: method,
);

const _recoverSent =
    'Se houver uma conta com este email, o link chega dentro de alguns '
    'minutos. Veja também a pasta de spam.';

void main() {
  group('bug 2: recuperar palavra-passe', () {
    testWidgets('conta existente (Auth responde 429): a mesma confirmação', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..nextFailure = const AuthFailure(AuthFailureKind.tooSoon);
      await pumpAuthApp(tester, repo, location: AppRoutes.recover);
      await tester.enterText(_field('Email'), 'mediador@exemplo.pt');
      await _tap(tester, 'Enviar link');
      expect(find.text(_recoverSent), findsOneWidget);
      expect(find.textContaining('Não foi possível'), findsNothing);
    });

    testWidgets('bloqueio de 60 s depois de cada envio, mesmo ao voltar', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      await pumpAuthApp(tester, repo, location: AppRoutes.recover);
      await tester.enterText(_field('Email'), 'ninguem@exemplo.pt');
      await _tap(tester, 'Enviar link');
      expect(repo.resets, ['ninguem@exemplo.pt']);
      expect(find.text(_recoverSent), findsOneWidget);

      // Voltar a entrar e pedir de novo antes de 60 s: bloqueado, com razão.
      await _tap(tester, 'Voltar a entrar');
      await tester.enterText(_field('Email'), 'ninguem@exemplo.pt');
      await _tap(tester, 'Esqueci-me da palavra-passe');
      expect(find.text('Enviar link'), findsOneWidget);
      expect(
        find.text('Pode enviar outra vez daqui a 1 minuto.'),
        findsOneWidget,
      );
      await _tap(tester, 'Enviar link');
      expect(repo.resets, hasLength(1));

      // Passado o minuto, volta a poder enviar.
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      await _tap(tester, 'Enviar link');
      expect(repo.resets, hasLength(2));
      expect(find.text(_recoverSent), findsOneWidget);
    });
  });

  group('bug 3: link expirado no URL de retorno', () {
    test('erro no fragmento ou na query', () {
      expect(
        hasLinkError(
          Uri.parse(
            'https://app.exemplo.pt/#error=access_denied'
            '&error_code=otp_expired&error_description=x',
          ),
        ),
        isTrue,
      );
      expect(
        hasLinkError(Uri.parse('https://app.exemplo.pt/?error=access_denied')),
        isTrue,
      );
      expect(
        hasLinkError(Uri.parse('https://app.exemplo.pt/#access_token=abc')),
        isFalse,
      );
      expect(hasLinkError(Uri.parse('https://app.exemplo.pt/')), isFalse);
    });

    testWidgets('lido antes do arranque (URL já limpo): ecrã "Link '
        'expirado" com pedido de link novo', (tester) async {
      final repo = FakeAuthRepository();
      final session = SessionController(repo)..markLinkFailed();
      await _pump(tester, repo, session, location: '/');
      expect(find.text('Este link já não é válido'), findsOneWidget);
      expect(find.text('Enviar link novo'), findsOneWidget);
      // Depois de explicado, pode seguir para Entrar.
      await _tap(tester, 'Já tem palavra-passe? Entrar com ela');
      expect(find.text('Esqueci-me da palavra-passe'), findsOneWidget);
    });

    testWidgets('sinal do Auth depois do arranque também leva ao ecrã', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      final session = SessionController(repo);
      await _pump(tester, repo, session, location: AppRoutes.entry);
      repo.signalsController.add(AuthSignal.linkFailed);
      await tester.pumpAndSettle();
      expect(find.text('Este link já não é válido'), findsOneWidget);
    });

    test('com sessão válida, o erro antigo não prende ninguém', () async {
      final session = SessionController(
        FakeAuthRepository(session: _staff(AppRole.admin, SignInMethod.password)),
      )..markLinkFailed();
      await session.start();
      addTearDown(session.dispose);
      expect(session.linkFailed, isFalse);
      expect(redirectFor(session, Uri.parse(AppRoutes.admin)), isNull);
    });
  });

  group('bug 4: pedido pendente antes de "Criar palavra-passe"', () {
    test('a primeira paragem é o pedido; ao voltar, o convite', () async {
      var lookups = 0;
      final session = SessionController(
        FakeAuthRepository(session: linkClient()),
        pendingRequest: () async {
          lookups++;
          return 'g1';
        },
      );
      await session.start();
      addTearDown(session.dispose);
      expect(
        redirectFor(session, Uri.parse(AppRoutes.client)),
        AppRoutes.consentFor('g1'),
      );
      expect(redirectFor(session, Uri.parse(AppRoutes.consentFor('g1'))), isNull);
      // Depois de responder ("Ver com quem partilho") ou de sair do pedido.
      expect(
        redirectFor(session, Uri.parse(AppRoutes.client)),
        AppRoutes.clientCreatePassword,
      );
      // Recarregar a mesma entrada não volta a procurar.
      await session.refresh();
      expect(lookups, 1);
    });

    test('sem pedido pendente, ou se a procura falhar: o convite', () async {
      for (final lookup in <PendingRequestLookup>[
        () async => null,
        () async => throw Exception('rede'),
      ]) {
        final session = SessionController(
          FakeAuthRepository(session: linkClient()),
          pendingRequest: lookup,
        );
        await session.start();
        expect(
          redirectFor(session, Uri.parse(AppRoutes.client)),
          AppRoutes.clientCreatePassword,
        );
        session.dispose();
      }
    });

    test('quem já tem palavra-passe ou disse "Agora não" não é desviado', () async {
      var lookups = 0;
      Future<String?> lookup() async {
        lookups++;
        return 'g1';
      }

      final withPassword = SessionController(
        FakeAuthRepository(
          session: linkClient(passwordSetAt: DateTime.utc(2026, 11, 20)),
        ),
        pendingRequest: lookup,
      );
      await withPassword.start();
      addTearDown(withPassword.dispose);
      expect(redirectFor(withPassword, Uri.parse(AppRoutes.client)), isNull);
      expect(lookups, 0);

      final prompts = MemoryPasswordPromptStore();
      final dismissed = SessionController(
        FakeAuthRepository(session: linkClient()),
        prompts: prompts,
        pendingRequest: lookup,
      );
      await dismissed.start();
      addTearDown(dismissed.dispose);
      await dismissed.dismissPasswordPrompt();
      expect(dismissed.pendingRequestId, isNull);
      expect(redirectFor(dismissed, Uri.parse(AppRoutes.client)), isNull);
    });

    testWidgets('entrar por link abre o pedido, não o convite', (tester) async {
      final repo = FakeAuthRepository(session: linkClient());
      final session = SessionController(
        repo,
        pendingRequest: () async => 'g1',
      );
      await _pump(tester, repo, session, location: '/');
      expect(find.text('Pedido de acesso'), findsWidgets);
      expect(find.text('Agora não'), findsNothing);
    });
  });

  group('bug 6: mediador ou admin com sessão por link', () {
    for (final role in [AppRole.mediador, AppRole.admin]) {
      test('${role.name}: a sessão termina, sem revelar o papel', () async {
        final repo = FakeAuthRepository(
          session: _staff(role, SignInMethod.link),
        );
        final session = SessionController(repo);
        await session.start();
        addTearDown(session.dispose);
        expect(session.status, SessionStatus.signedOut);
        expect(session.session, isNull);
        expect(session.sessionEnded, isTrue);
        expect(repo.signOuts, 1);
        // Nem o email fica para preencher Entrar.
        expect(session.lastEmail, isEmpty);
        expect(
          redirectFor(session, Uri.parse(homeFor(role))),
          AppRoutes.entry,
        );
      });
    }

    test('convite, recuperação e palavra-passe continuam a entrar', () async {
      for (final method in [
        SignInMethod.password,
        SignInMethod.invite,
        SignInMethod.recovery,
      ]) {
        final repo = FakeAuthRepository(
          session: _staff(AppRole.mediador, method),
        );
        final session = SessionController(repo);
        await session.start();
        expect(session.status, SessionStatus.signedIn, reason: '$method');
        expect(repo.signOuts, 0);
        session.dispose();
      }
    });

    test('o cliente por link continua a entrar', () async {
      final repo = FakeAuthRepository(session: linkClient());
      final session = SessionController(repo);
      await session.start();
      addTearDown(session.dispose);
      expect(session.status, SessionStatus.signedIn);
    });

    testWidgets('Entrar mostra só a mensagem genérica de sessão terminada', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: _staff(AppRole.mediador, SignInMethod.link),
      );
      await _pump(tester, repo, SessionController(repo), location: '/');
      expect(find.text('Esqueci-me da palavra-passe'), findsOneWidget);
      expect(
        find.text('A sua sessão terminou. Entre de novo para continuar.'),
        findsOneWidget,
      );
      expect(find.textContaining('mediador'), findsNothing);
      expect(find.textContaining('Clientes'), findsNothing);
    });
  });
}
