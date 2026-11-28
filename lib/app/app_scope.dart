import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/application/client_link_controller.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/data/password_prompt_store.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/notifications/application/notifications_controller.dart';
import '../features/notifications/data/supabase_notifications_repository.dart';
import '../features/notifications/domain/notifications_repository.dart';
import '../features/requests/application/created_batch.dart';
import '../features/requests/data/supabase_request_email_sender.dart';
import '../features/requests/data/supabase_requests_repository.dart';
import '../features/requests/domain/request_email_sender.dart';
import '../features/requests/domain/requests_repository.dart';
import 'connectivity.dart';

/// Serviços partilhados da app, acessíveis por `AppScope.of(context)`.
class AppServices {
  AppServices({
    required this.auth,
    PasswordPromptStore? prompts,
    SessionController? session,
    AppConnectivity? connectivity,
    ClientLinkController? clientLink,
    ClientLinkController? passwordReset,
    this._requests,
    this._requestEmail,
    NotificationsRepository? notifications,
  }) : connectivity = connectivity ?? AppConnectivity(probe: auth.isReachable),
       session = session ?? SessionController(auth, prompts: prompts),
       _notificationsRepo = notifications {
    this.clientLink =
        clientLink ?? ClientLinkController(auth, this.connectivity);
    this.passwordReset =
        passwordReset ??
        ClientLinkController.passwordReset(auth, this.connectivity);
    _userId = this.session.session?.userId;
    this.session.addListener(_onSession);
  }

  final AuthRepository auth;
  final SessionController session;
  final AppConnectivity connectivity;
  late final ClientLinkController clientLink;

  /// "Recuperar palavra-passe": vive fora do ecrã para o bloqueio de 60 s
  /// sobreviver a "Voltar a entrar" e a voltar a abrir o ecrã.
  late final ClientLinkController passwordReset;

  // ---- 002: pedidos e notificações ----------------------------------------
  // Sem fake, usam o Supabase já inicializado em `main.dart` (criados só
  // quando um ecrã os pede; os testes passam fakes).

  RequestsRepository? _requests;
  RequestEmailSender? _requestEmail;
  final NotificationsRepository? _notificationsRepo;
  NotificationsController? _notifications;
  String? _userId;

  /// Pedidos, catálogo e leituras do mediador e do cliente.
  RequestsRepository get requests =>
      _requests ??= SupabaseRequestsRepository(Supabase.instance.client);

  /// Envio e reenvio do email do pedido (`send-request-email`).
  RequestEmailSender get requestEmail =>
      _requestEmail ??= SupabaseRequestEmailSender(Supabase.instance.client);

  /// Passagem do Novo pedido para a ficha do cliente.
  final CreatedRequestsHandoff requestsHandoff = CreatedRequestsHandoff();

  /// Sino e lista de notificações: um só por sessão, partilhado por todos os
  /// ecrãs do cliente. Esquecido quando a sessão acaba ou muda de pessoa.
  NotificationsController get notifications =>
      _notifications ??= NotificationsController(
        _notificationsRepo ??
            SupabaseNotificationsRepository(Supabase.instance.client),
        connectivity,
      );

  void _onSession() {
    final id = session.status == SessionStatus.signedIn
        ? session.session?.userId
        : null;
    if (id == _userId) return;
    _userId = id;
    _notifications?.reset();
    requestsHandoff.clear();
  }

  void dispose() {
    session.removeListener(_onSession);
    _notifications?.dispose();
    clientLink.dispose();
    passwordReset.dispose();
    session.dispose();
    connectivity.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope em falta');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope old) => services != old.services;
}
