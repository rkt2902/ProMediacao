import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import 'request_copy.dart';

/// Navega para [location] (sem router, p. ex. num teste de widget isolado,
/// não faz nada).
void goTo(BuildContext context, String location) =>
    GoRouter.maybeOf(context)?.go(location);

/// Ligação de texto sublinhada (nome de cliente, tipo de pedido):
/// `corpoForte` com sublinhado `reguaForte` 1 sempre visível, que passa a
/// `tinta` (e mais grosso) no hover e no foco. Alvo mínimo de 48.
class NameLink extends StatelessWidget {
  const NameLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
    this.maxLines,
    this.minHeight = AppSize.alvoMinimo,
    this.detail,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final int? maxLines;
  final double minHeight;

  /// Linha por baixo do nome (ex.: o email) que faz parte do alvo, sem
  /// sublinhado: o alvo passa os 48 sem acrescentar espaço entre os dois.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      builder: (context, s) {
        final strong = s.hovered || s.focused || s.pressed;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: AppType.corpoForte.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: strong
                        ? AppColors.tinta
                        : AppColors.reguaForte,
                    decorationThickness: strong
                        ? AppStroke.foco
                        : AppStroke.fino,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    maxLines: maxLines,
                    overflow: maxLines == null ? null : TextOverflow.ellipsis,
                    style: AppType.corpoPequeno.copyWith(
                      color: AppColors.tintaMedia,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Entra com opacidade e altura (`lento` / `entrar`) ao ser criado.
class Entering extends StatelessWidget {
  const Entering({super.key, required this.child, this.enabled = true});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.lento),
      curve: AppMotion.entrar,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// "Sem acesso": cliente inexistente, de outro escritório ou que retirou o
/// acesso (nunca se distingue). Usado na ficha e no pedido aberto.
class NoAccessBlock extends StatelessWidget {
  const NoAccessBlock({
    super.key,
    this.title = RequestCopy.noAccessTitle,
    this.body = RequestCopy.noAccessBody,
    required this.onBack,
  });

  final String title;
  final String body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          autofocus: !compact,
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(body, style: AppType.corpo.copyWith(color: AppColors.tintaMedia)),
        const SizedBox(height: AppSpace.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SecondaryButton(
            label: RequestCopy.backToClients,
            principal: compact,
            expand: compact,
            onPressed: onBack,
          ),
        ),
      ],
    );
  }
}

/// Caixa de contorno tracejado `reguaForte` 1: marca o lugar vazio onde a
/// folha vai aparecer (única exceção ao contorno contínuo).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: Padding(padding: const EdgeInsets.all(AppSpace.s24), child: child),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.reguaForte
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.fino;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.superficie),
        ),
      );
    const dash = AppSpace.s8;
    const gap = AppSpace.s4;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => false;
}

/// Caixa `folha` com régua e raio `controlo` (cliente escolhido).
class PaperBox extends StatelessWidget {
  const PaperBox({super.key, required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.folha,
        borderRadius: AppRadius.controloBorda,
        border: Border.all(
          color: borderColor ?? AppColors.regua,
          width: AppStroke.fino,
        ),
      ),
      child: child,
    );
  }
}

/// Cabeçalho de secção: título em `subtitulo` e, à direita, um `registo`.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.s12,
      children: [
        Semantics(header: true, child: Text(title, style: AppType.subtitulo)),
        if (trailing != null) Text(trailing!, style: AppType.registo),
      ],
    );
  }
}
