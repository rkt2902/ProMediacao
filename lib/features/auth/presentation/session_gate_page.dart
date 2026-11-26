import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/session_controller.dart';
import 'auth_copy.dart';

/// Ecrã de passagem enquanto se confirma a sessão (skeleton, sem spinner de
/// página) ou quando não foi possível confirmá-la.
class SessionGatePage extends StatelessWidget {
  const SessionGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => PageFrame(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpace.s32),
          child: session.status == SessionStatus.failed
              ? InlineNotice(
                  kind: NoticeKind.erro,
                  message: AuthCopy.networkError,
                  actionLabel: AuthCopy.retry,
                  onAction: session.retry,
                )
              : const SkeletonRows(count: 3),
        ),
      ),
    );
  }
}
