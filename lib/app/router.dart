import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/create_password_page.dart';
import '../features/auth/presentation/entry_page.dart';
import '../features/auth/presentation/expired_link_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/session_gate_page.dart';
import '../features/auth/presentation/set_password_page.dart';
import '../features/mediator/presentation/create_client_form.dart';
import 'page_transition.dart';
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

/// Link do email do pedido: `/pedidos` e `/pedidos/{id}`.
bool _isEmailLink(String path) =>
    path == AppRoutes.emailRequests ||
    path.startsWith('${AppRoutes.emailRequests}/');

/// Para onde vai o link do email com sessão: o cliente vai aos seus pedidos
/// (ou ao pedido indicado); os outros papéis ao seu ecrã inicial.
String _emailLinkTarget(AppRole role, String path) {
  if (role != AppRole.cliente) return homeFor(role);
  final rest = path.substring(AppRoutes.emailRequests.length);
  final id = rest.startsWith('/') ? Uri.decodeComponent(rest.substring(1)) : '';
  return id.isEmpty ? AppRoutes.client : AppRoutes.clientRequest(id);
}

/// Destino de `?de=` depois de entrar: só caminhos desta app (nunca outro
/// site), e nunca Entrar ou o arranque.
String? safeReturnPath(String? value) {
  if (value == null || !value.startsWith('/') || value.startsWith('//')) {
    return null;
  }
  if (value.contains(r'\')) return null;
  final u = Uri.tryParse(value);
  if (u == null || u.hasScheme || u.hasAuthority) return null;
  if (u.path == '/' || u.path == AppRoutes.entry || u.path == AppRoutes.gate) {
    return null;
  }
  return value;
}

const _publicPaths = {
  AppRoutes.entry,
  AppRoutes.recover,
  AppRoutes.expiredLink,
};

/// `true` se o URL de retorno do Supabase traz um erro de link (expirado,
/// já usado ou inválido). Em web o erro vem no fragmento (`#error=...`, fluxo
/// implícito) ou na query (`?error=...`). `main.dart` lê-o em `Uri.base`
/// antes de `Supabase.initialize`, que limpa o fragmento.
bool hasLinkError(Uri uri) {
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

  if (hasLinkError(uri) && path != AppRoutes.expiredLink) {
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
      // O erro do link já foi lido (e limpo do URL) antes de o router
      // arrancar: mostra a explicação e o pedido de link novo.
      if (session.linkFailed && path != AppRoutes.expiredLink) {
        return AppRoutes.expiredLink;
      }
      if (path == AppRoutes.gate) {
        final back = uri.queryParameters['de'];
        return back != null && back != '/' ? back : AppRoutes.entry;
      }
      if (path == AppRoutes.setPassword) {
        return '${AppRoutes.expiredLink}?tipo=palavra-passe';
      }
      if (_publicPaths.contains(path)) return null;
      // O link do email passa por Entrar e volta ao destino depois.
      if (_isEmailLink(path)) {
        final back = Uri(
          path: path,
          query: uri.hasQuery ? uri.query : null,
        ).toString();
        return '${AppRoutes.entry}?de=${Uri.encodeComponent(back)}';
      }
      return AppRoutes.entry;

    case SessionStatus.signedIn:
      final role = session.role!;
      final home = homeFor(role);
      if (path == AppRoutes.gate) {
        final back = uri.queryParameters['de'];
        return back != null && back != '/' ? back : home;
      }
      if (session.recovering || session.needsPasswordSetup) {
        return path == AppRoutes.setPassword ? null : AppRoutes.setPassword;
      }
      if (path == AppRoutes.setPassword) return null;
      if (path == AppRoutes.entry) {
        final back = safeReturnPath(uri.queryParameters['de']);
        if (back != null) return back;
      }
      if (_isEmailLink(path)) return _emailLinkTarget(role, path);
      final owner = _ownerOf(path);
      if (owner == null) return home; // entrada, "/" e rotas desconhecidas
      if (owner != role) return home; // rota de outro perfil: não existe
      if (role == AppRole.cliente) {
        // Entrada por link com um pedido pendente: a primeira paragem é o
        // pedido (03-design, ecrã 1c e fluxo 1). Uma só vez por entrada; ao
        // voltar ao ecrã inicial ("Os meus pedidos" desde a 002) aparece o
        // convite.
        final pending = session.pendingRequestId;
        if (path == AppRoutes.client && pending != null) {
          session.consumePendingRequest();
          return AppRoutes.consentFor(pending);
        }
        // O convite para criar palavra-passe vem antes do ecrã inicial,
        // nunca antes nem durante o consentimento (o pedido tem rota própria
        // e não passa por aqui).
        if (path == AppRoutes.client && session.offerPassword) {
          return AppRoutes.clientCreatePassword;
        }
        if (path == AppRoutes.clientCreatePassword && !session.offerPassword) {
          return AppRoutes.client;
        }
      }
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
        pageBuilder: (c, s) => fadePage(c, s, const SessionGatePage()),
      ),
      GoRoute(
        path: AppRoutes.gate,
        pageBuilder: (c, s) => fadePage(c, s, const SessionGatePage()),
      ),
      GoRoute(
        path: AppRoutes.entry,
        pageBuilder: (c, s) => fadePage(c, s, const EntryPage()),
      ),
      GoRoute(
        path: AppRoutes.recover,
        pageBuilder: (c, s) => fadePage(c, s, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        pageBuilder: (c, s) => fadePage(c, s, const SetPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.expiredLink,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          ExpiredLinkPage(
            forPassword: s.uri.queryParameters['tipo'] == 'palavra-passe',
          ),
        ),
      ),
      // Link do email do pedido: o redirect leva sempre a outro sítio.
      GoRoute(
        path: AppRoutes.emailRequests,
        pageBuilder: (c, s) => fadePage(c, s, const SessionGatePage()),
        routes: [
          GoRoute(
            path: ':requestId',
            pageBuilder: (c, s) => fadePage(c, s, const SessionGatePage()),
          ),
        ],
      ),
      // 002: rotas de topo (não filhas de /mediador nem de /cliente), antes
      // das iniciais. Cada `go` constrói o ecrã de novo: a ficha que se abre
      // depois de criar não fica com o estado de antes por baixo.
      GoRoute(
        path: AppRoutes.mediatorNewRequest,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          Builder(
            builder: (c) => builders.newRequest(
              c,
              NewRequestArgs(
                clientId: _param(s.uri.queryParameters['cliente']),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.mediatorClientNewRequestPattern,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          Builder(
            builder: (c) => builders.newRequest(
              c,
              NewRequestArgs(
                clientId: s.pathParameters['clientId'],
                fromClientFile: true,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.mediatorRequestPattern,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          Builder(
            builder: (c) => builders.mediatorRequest(
              c,
              s.pathParameters['clientId'] ?? '',
              s.pathParameters['requestId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.mediatorClientPattern,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          Builder(
            builder: (c) =>
                builders.clientFile(c, s.pathParameters['clientId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientSharing,
        pageBuilder: (c, s) =>
            fadePage(c, s, Builder(builder: builders.clientSharing)),
      ),
      GoRoute(
        path: AppRoutes.clientRequestPattern,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          Builder(
            builder: (c) =>
                builders.clientRequest(c, s.pathParameters['requestId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientNotifications,
        pageBuilder: (c, s) =>
            fadePage(c, s, Builder(builder: builders.notifications)),
      ),
      GoRoute(
        path: AppRoutes.admin,
        pageBuilder: (c, s) =>
            fadePage(c, s, Builder(builder: builders.adminHome)),
      ),
      GoRoute(
        path: AppRoutes.mediator,
        pageBuilder: (c, s) =>
            fadePage(c, s, Builder(builder: builders.mediatorHome)),
        routes: [
          // "Criar cliente" em ecrã inteiro (telemóvel). Só abre a partir de
          // Clientes (precisa do estado da lista em `extra`).
          GoRoute(
            path: 'novo-cliente',
            redirect: (c, s) =>
                s.extra is CreateClientArgs ? null : AppRoutes.mediator,
            pageBuilder: (c, s) =>
                fadePage(c, s, (s.extra! as CreateClientArgs).page()),
          ),
        ],
      ),
      // Rotas de topo (não filhas de /cliente): sem o ecrã inicial por baixo,
      // que ficaria com o estado antigo ao voltar.
      GoRoute(
        path: AppRoutes.clientCreatePassword,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          const CreatePasswordPage(mode: CreatePasswordMode.prompt),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientPassword,
        pageBuilder: (c, s) => fadePage(
          c,
          s,
          const CreatePasswordPage(mode: CreatePasswordMode.account),
        ),
      ),
      GoRoute(
        path: AppRoutes.client,
        pageBuilder: (c, s) =>
            fadePage(c, s, Builder(builder: builders.clientHome)),
        routes: [
          GoRoute(
            path: 'pedido/:grantId',
            pageBuilder: (c, s) => fadePage(
              c,
              s,
              Builder(
                builder: (c) =>
                    builders.consent(c, s.pathParameters['grantId'] ?? ''),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

String? _param(String? v) => v == null || v.trim().isEmpty ? null : v;
