import 'package:material_ui/material_ui.dart';

import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/design/typography.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/auth/presentation/client_account_section.dart';
import 'package:promediacao/features/auth/presentation/session_colophon.dart';
import 'package:promediacao/app/app_scope.dart';

/// MARCADOR TEMPORÁRIO: "Com quem partilho" é da tarefa 5. Já tem a moldura
/// final (separador, "Sair", colofão do cliente), o aviso que chega de outro
/// ecrã (ex.: "Palavra-passe criada…") e a secção "A sua conta", que a
/// tarefa 5 reutiliza (`ClientAccountSection`).
class ClientHomePlaceholder extends StatefulWidget {
  const ClientHomePlaceholder({super.key});

  @override
  State<ClientHomePlaceholder> createState() => _ClientHomePlaceholderState();
}

class _ClientHomePlaceholderState extends State<ClientHomePlaceholder> {
  String? _notice;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _notice = AppScope.of(context).session.takeNotice();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return PageFrame(
      tabLabel: 'Os meus dados',
      maxWidth: AppSize.larguraLeitura,
      onSignOut: services.session.signOut,
      colophon: const SessionColophon(),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_notice != null) ...[
              InlineNotice(message: _notice!),
              const SizedBox(height: AppSpace.s24),
            ],
            Text(
              'Com quem partilho',
              style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
            ),
            const SizedBox(height: AppSpace.s48),
            const ClientAccountSection(),
          ],
        ),
      ),
    );
  }
}
