import 'package:material_ui/material_ui.dart';

import '../features/auth/application/client_link_controller.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/data/password_prompt_store.dart';
import '../features/auth/domain/auth_repository.dart';
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
  }) : connectivity = connectivity ?? AppConnectivity(probe: auth.isReachable),
       session = session ?? SessionController(auth, prompts: prompts) {
    this.clientLink =
        clientLink ?? ClientLinkController(auth, this.connectivity);
    this.passwordReset =
        passwordReset ??
        ClientLinkController.passwordReset(auth, this.connectivity);
  }

  final AuthRepository auth;
  final SessionController session;
  final AppConnectivity connectivity;
  late final ClientLinkController clientLink;

  /// "Recuperar palavra-passe": vive fora do ecrã para o bloqueio de 60 s
  /// sobreviver a "Voltar a entrar" e a voltar a abrir o ecrã.
  late final ClientLinkController passwordReset;

  void dispose() {
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
