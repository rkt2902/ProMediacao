import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/session_controller.dart';
import 'auth_copy.dart';

/// Ecrã de arranque enquanto se confirma a sessão (DESIGN.md, "Colofão"):
/// `papel` vazio com o colofão sem sessão no fundo, sem nada ao centro e sem
/// animação. Se não for possível confirmar, aviso com "Tentar de novo".
class SessionGatePage extends StatelessWidget {
  const SessionGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => PageFrame(
        maxWidth: AppSize.larguraFormulario,
        colophon: const Colophon.signedOut(),
        child: session.status == SessionStatus.failed
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpace.s32),
                child: InlineNotice(
                  kind: NoticeKind.erro,
                  message: AuthCopy.networkError,
                  actionLabel: AuthCopy.retry,
                  onAction: session.retry,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
