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
  }) : connectivity = connectivity ?? AppConnectivity(probe: auth.isReachable),
       session = session ?? SessionController(auth, prompts: prompts) {
    this.clientLink =
        clientLink ?? ClientLinkController(auth, this.connectivity);
  }

  final AuthRepository auth;
  final SessionController session;
  final AppConnectivity connectivity;
  late final ClientLinkController clientLink;

  void dispose() {
    clientLink.dispose();
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
