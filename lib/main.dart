import 'package:flutter/widgets.dart';
// flutter_web_plugins é do SDK mas falta no pubspec (ver handoff).
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'app/config_error_app.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/entry_tab_store.dart';
import 'features/auth/data/supabase_auth_repository.dart';

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
  runApp(
    ProMediacaoApp(
      services: AppServices(auth: auth, tabStore: SharedPrefsEntryTabStore()),
    ),
  );
}
