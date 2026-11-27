import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import '../core/design/tokens.dart';
import '../core/design/typography.dart';
import '../core/widgets/widgets.dart';

/// Ecrã mostrado quando faltam SUPABASE_URL ou SUPABASE_ANON_KEY.
/// Em desenvolvimento diz também quais.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, this.missing = const []});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProDossier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => PageFrame(
          tabLabel: 'Acesso',
          maxWidth: AppSize.larguraFormulario,
          colophon: const Colophon.signedOut(),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpace.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não foi possível abrir a aplicação',
                  style: AppType.tituloPara(
                    AppBreakpoints.fromContext(context),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Text(
                  'A ligação ao servidor não está configurada. Contacte a '
                  'administração.',
                  style: AppType.corpo,
                ),
                if (kDebugMode && missing.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    'Em falta (--dart-define): ${missing.join(', ')}',
                    style: AppType.registo,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
