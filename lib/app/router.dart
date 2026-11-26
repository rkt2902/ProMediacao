import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/entry_page.dart';
import '../features/auth/presentation/expired_link_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/session_gate_page.dart';
import '../features/auth/presentation/set_password_page.dart';
import 'route_builders.dart';
import 'routes.dart';

String homeFor(AppRole role) => switch (role) {
  AppRole.admin => AppRoutes.admin,
  AppRole.mediador => AppRoutes.mediator,
  AppRole.cliente => AppRoutes.client,
};

/// Rota que cada papel pode abrir (prefixo).
AppRole? _ownerOf(String path) {
  bool under(String base) => path == base || path.startsWith('$base/');
  if (under(AppRoutes.admin)) return AppRole.admin;
  if (under(AppRoutes.mediator)) return AppRole.mediador;
  if (under(AppRoutes.client)) return AppRole.cliente;
  return null;
}

const _publicPaths = {
  AppRoutes.entry,
  AppRoutes.recover,
  AppRoutes.expiredLink,
};

bool _hasLinkError(Uri uri) {
  // Em web o Supabase devolve o erro no fragmento (#error=...) ou na query.
  final fragment = uri.fragment.contains('=')
      ? Uri.splitQueryString(uri.fragment.replaceFirst(RegExp(r'^[^?]*\?'), ''))
      : const <String, String>{};
  return uri.queryParameters.containsKey('error_code') ||
      uri.queryParameters.containsKey('error') ||
      fragment.containsKey('error_code') ||
      fragment.containsKey('error');
}

/// Lógica de redirecionamento (pura, testável).
String? redirectFor(SessionController session, Uri uri) {
  final path = uri.path;

  if (_hasLinkError(uri) && path != AppRoutes.expiredLink) {
    return session.status == SessionStatus.signedIn
        ? homeFor(session.role!)
        : AppRoutes.expiredLink;
  }

  switch (session.status) {
    case SessionStatus.restoring:
    case SessionStatus.failed:
      if (path == AppRoutes.gate) return null;
      final back = Uri.encodeComponent(uri.toString());
      return '${AppRoutes.gate}?de=$back';

    case SessionStatus.signedOut:
      if (path == AppRoutes.gate) {
        final back = uri.queryParameters['de'];
        return back != null && back != '/' ? back : AppRoutes.entry;
      }
      if (path == AppRoutes.setPassword) {
        return '${AppRoutes.expiredLink}?tipo=palavra-passe';
      }
      if (_publicPaths.contains(path)) return null;
      return AppRoutes.entry;

    case SessionStatus.signedIn:
      final role = session.role!;
      final home = homeFor(role);
      if (path == AppRoutes.gate) {
        final back = uri.queryParameters['de'];
        return back != null && back != '/' ? back : home;
      }
      if (session.recovering) {
        return path == AppRoutes.setPassword ? null : AppRoutes.setPassword;
      }
      if (path == AppRoutes.setPassword) return null;
      final owner = _ownerOf(path);
      if (owner == null) return home; // entrada, "/" e rotas desconhecidas
      if (owner != role) return home; // rota de outro perfil: não existe
      return null;
  }
}

GoRouter buildRouter(
  SessionController session, {
  RouteBuilders builders = const RouteBuilders(),
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) => redirectFor(session, state.uri),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => null,
        builder: (context, state) => const SessionGatePage(),
      ),
      GoRoute(
        path: AppRoutes.gate,
        builder: (context, state) => const SessionGatePage(),
      ),
      GoRoute(
        path: AppRoutes.entry,
        builder: (context, state) => const EntryPage(),
      ),
      GoRoute(
        path: AppRoutes.recover,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (context, state) => const SetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.expiredLink,
        builder: (context, state) => ExpiredLinkPage(
          forPassword: state.uri.queryParameters['tipo'] == 'palavra-passe',
        ),
      ),
      GoRoute(path: AppRoutes.admin, builder: (c, s) => builders.adminHome(c)),
      GoRoute(
        path: AppRoutes.mediator,
        builder: (c, s) => builders.mediatorHome(c),
      ),
      GoRoute(
        path: AppRoutes.client,
        builder: (c, s) => builders.clientHome(c),
        routes: [
          GoRoute(
            path: 'pedido/:grantId',
            builder: (c, s) =>
                builders.consent(c, s.pathParameters['grantId'] ?? ''),
          ),
        ],
      ),
    ],
  );
}
