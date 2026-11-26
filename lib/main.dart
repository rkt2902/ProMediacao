import 'package:flutter/widgets.dart';
// flutter_web_plugins é do SDK mas falta no pubspec (ver handoff).
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'app/config_error_app.dart';
import 'app/router.dart';
import 'core/config/app_config.dart';
import 'features/auth/application/session_controller.dart';
import 'features/auth/data/password_prompt_store.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/consent/data/supabase_consent_repository.dart';
import 'features/consent/domain/consent_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpos em web (sem #): os links mágicos e de recuperação abrem no
  // navegador e o Supabase lê o fragmento da sessão sem conflito com o router.
  usePathUrlStrategy();

  const config = AppConfig.environment;
  if (!config.isValid) {
    runApp(ConfigErrorApp(missing: config.problems));
    return;
  }

  // O Supabase lê e limpa o fragmento do URL dentro de `initialize`: um
  // link expirado (#error=...&error_code=otp_expired) tem de ser lido antes.
  final linkError = hasLinkError(Uri.base);

  try {
    await Supabase.initialize(
      url: config.supabaseUrl.trim(),
      publishableKey: config.supabaseAnonKey.trim(),
    );
  } on Object {
    runApp(const ConfigErrorApp());
    return;
  }

  final auth = SupabaseAuthRepository(
    Supabase.instance.client,
    passwordRedirectUrl: config.authRedirectUrl.isEmpty
        ? null
        : config.authRedirectUrl,
  );
  final prompts = SharedPrefsPasswordPromptStore();
  final consent = SupabaseConsentRepository(Supabase.instance.client);
  final session = SessionController(
    auth,
    prompts: prompts,
    pendingRequest: () async {
      final grants = await consent.myConsents();
      for (final g in grants) {
        if (g.status == GrantStatus.pendente) return g.id;
      }
      return null;
    },
  );
  if (linkError) session.markLinkFailed();
  runApp(
    ProMediacaoApp(
      services: AppServices(auth: auth, prompts: prompts, session: session),
    ),
  );
}
