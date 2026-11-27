// QA 001 (tarefa 8): isolamento por rota e passagem pelo convite de
// palavra-passe, testados sobre `redirectFor` (lógica pura do router).
//
// A RLS é a barreira real (supabase/tests/001_isolation_matrix.sql); aqui
// confirma-se que a app nunca abre o ecrã de outro perfil nem ecrãs com sessão
// sem sessão.
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/router.dart';
import 'package:promediacao/app/routes.dart';
import 'package:promediacao/features/auth/application/session_controller.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import 'auth_test_helpers.dart';

Future<SessionController> _session(AppSession? s) async {
  final c = SessionController(FakeAuthRepository(session: s));
  await c.start();
  addTearDown(c.dispose);
  return c;
}

AppSession _as(AppRole role, {SignInMethod method = SignInMethod.password}) =>
    AppSession(userId: 'u-${role.name}', role: role, method: method);

String? _go(SessionController s, String location) =>
    redirectFor(s, Uri.parse(location));

void main() {
  group('sem sessão', () {
    test('qualquer rota com sessão leva a Entrar', () async {
      final s = await _session(null);
      expect(s.status, SessionStatus.signedOut);
      for (final path in [
        AppRoutes.admin,
        AppRoutes.mediator,
        AppRoutes.client,
        '${AppRoutes.client}/pedido/abc',
        AppRoutes.clientPassword,
        '/qualquer-coisa',
      ]) {
        expect(_go(s, path), AppRoutes.entry, reason: path);
      }
    });

    test(
      'rotas públicas abrem; definir palavra-passe vai a link inválido',
      () async {
        final s = await _session(null);
        expect(_go(s, AppRoutes.entry), isNull);
        expect(_go(s, AppRoutes.recover), isNull);
        expect(_go(s, AppRoutes.expiredLink), isNull);
        expect(
          _go(s, AppRoutes.setPassword),
          '${AppRoutes.expiredLink}?tipo=palavra-passe',
        );
      },
    );

    test('link com erro no fragmento leva a "link inválido"', () async {
      final s = await _session(null);
      expect(
        _go(s, '/#error=access_denied&error_code=otp_expired'),
        AppRoutes.expiredLink,
      );
    });
  });

  group('cada perfil só abre as suas rotas', () {
    const others = {
      AppRole.admin: [AppRoutes.mediator, AppRoutes.client],
      AppRole.mediador: [
        AppRoutes.admin,
        AppRoutes.client,
        '${AppRoutes.client}/pedido/abc',
      ],
      AppRole.cliente: [AppRoutes.admin, AppRoutes.mediator],
    };
    for (final role in AppRole.values) {
      test('${role.name}: rotas de outro perfil voltam ao início', () async {
        final s = await _session(_as(role));
        final home = homeFor(role);
        expect(_go(s, home), isNull);
        expect(_go(s, AppRoutes.entry), home);
        for (final path in others[role]!) {
          expect(_go(s, path), home, reason: path);
        }
      });
    }
  });

  group('palavra-passe', () {
    test('mediador convidado sem palavra-passe tem de a definir', () async {
      final s = await _session(
        _as(AppRole.mediador, method: SignInMethod.invite),
      );
      expect(s.needsPasswordSetup, isTrue);
      expect(_go(s, AppRoutes.mediator), AppRoutes.setPassword);
      expect(_go(s, AppRoutes.setPassword), isNull);
    });

    test('cliente por link sem palavra-passe: convite antes de "Com quem '
        'partilho", nunca no pedido', () async {
      final s = await _session(linkClient());
      expect(s.offerPassword, isTrue);
      expect(_go(s, AppRoutes.client), AppRoutes.clientCreatePassword);
      // O pedido de consentimento não passa pelo convite.
      expect(_go(s, '${AppRoutes.client}/pedido/g1'), isNull);
    });

    test('cliente com palavra-passe nunca vê o convite', () async {
      final s = await _session(
        linkClient(passwordSetAt: DateTime.utc(2026, 11, 20)),
      );
      expect(s.offerPassword, isFalse);
      expect(_go(s, AppRoutes.client), isNull);
      expect(_go(s, AppRoutes.clientCreatePassword), AppRoutes.client);
    });

    test('"Agora não" deixa passar logo, sem bloqueio', () async {
      final s = await _session(linkClient());
      await s.dismissPasswordPrompt();
      expect(_go(s, AppRoutes.client), isNull);
    });
  });
}
