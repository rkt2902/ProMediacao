import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/motion.dart';

/// Transição de página (03-design.md, "Transições entre ecrãs"): cross-fade
/// `base`, o ecrã novo entra em `entrar` e o antigo sai em `sair`. Nada
/// desliza. Com "reduzir movimento", corte seco.
Page<void> fadePage(BuildContext context, GoRouterState state, Widget child) {
  final duration = AppMotion.resolve(context, AppMotion.base);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondary, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entrar,
        reverseCurve: AppMotion.sair,
      );
      final fadeOut = CurvedAnimation(
        parent: secondary,
        curve: AppMotion.sair,
        reverseCurve: AppMotion.entrar,
      );
      return FadeTransition(
        opacity: fadeIn,
        child: FadeTransition(opacity: ReverseAnimation(fadeOut), child: child),
      );
    },
  );
}
