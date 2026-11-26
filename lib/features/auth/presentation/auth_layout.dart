import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Larguras da coluna dos ecrãs de autenticação (03-design.md, ecrã 1).
const double authColumnWidth = 400;

/// Estrutura comum de entrada, recuperação e link expirado: `PageFrame`,
/// faixa offline e coluna de 400 (a 1/3 da largura em largo, a toda a
/// largura em compacto).
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.tabs,
    required this.children,
    this.offlineMessage,
  });

  /// `FolderTabs` ou `FolderTab` no topo da coluna.
  final Widget tabs;
  final List<Widget> children;
  final String? offlineMessage;

  @override
  Widget build(BuildContext context) {
    final connectivity = AppScope.of(context).connectivity;
    final width = MediaQuery.sizeOf(context).width;
    final bp = AppBreakpoints.of(width);
    final margin = AppBreakpoints.margin(bp);
    final offset = bp == Breakpoint.largo
        ? (width / 3 - margin).clamp(0.0, double.infinity)
        : 0.0;
    final top = bp == Breakpoint.largo ? AppSpace.s72 : AppSpace.s32;

    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => PageFrame(
        banner: offlineMessage == null
            ? null
            : OfflineBar(
                visible: !connectivity.online,
                message: offlineMessage!,
              ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: offset,
            top: top,
            bottom: AppSpace.s48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: authColumnWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [tabs, ...children],
            ),
          ),
        ),
      ),
    );
  }
}
