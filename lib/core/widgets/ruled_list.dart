import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import 'app_pressable.dart';
import 'folder_tab.dart';

/// Lista separada por réguas finas (sem cartões, sem sombras, sem raio).
class RuledList extends StatelessWidget {
  const RuledList({
    super.key,
    required this.children,
    this.topRule = true,
    this.bottomRule = true,
  });

  final List<Widget> children;
  final bool topRule;
  final bool bottomRule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topRule) const AppRule(),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1 || bottomRule) const AppRule(),
        ],
      ],
    );
  }
}

/// Linha de uma [RuledList]. Só é clicável se houver [onTap] (linhas sem
/// ação não têm hover nem seta). [highlight] faz o fundo `realce`
/// desvanecer em `AppMotion.realce` quando a linha é criada ou alterada.
class RuledRow extends StatelessWidget {
  const RuledRow({
    super.key,
    required this.child,
    this.onTap,
    this.highlight = false,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpace.s16),
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Linha acabada de criar/alterar: começa em `realce` e desvanece.
  final bool highlight;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (highlight) {
      content = TweenAnimationBuilder<Color?>(
        key: ValueKey(highlight),
        tween: ColorTween(begin: AppColors.realce, end: AppColors.nenhuma),
        duration: AppMotion.resolve(context, AppMotion.realce),
        curve: AppMotion.mudar,
        builder: (context, color, child) =>
            ColoredBox(color: color ?? AppColors.nenhuma, child: child),
        child: content,
      );
    }

    if (onTap != null) {
      content = AppPressable(
        onPressed: onTap,
        borderRadius: BorderRadius.zero,
        semanticsLabel: semanticsLabel,
        builder: (context, s) => ColoredBox(
          color: s.hovered ? AppColors.realce : AppColors.nenhuma,
          child: content,
        ),
      );
    } else if (semanticsLabel != null) {
      content = Semantics(
        container: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: content,
      );
    }
    return content;
  }
}

/// Linhas-esqueleto para listas a carregar. Opacidade 1.0 a 0.55 (ida e
/// volta), nunca shimmer. Com "reduzir movimento" fica estático.
class SkeletonRows extends StatefulWidget {
  const SkeletonRows({super.key, this.count = 3});

  final int count;

  @override
  State<SkeletonRows> createState() => _SkeletonRowsState();
}

class _SkeletonRowsState extends State<SkeletonRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulsar ~/ 2,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AppMotion.reduced(context);
    if (reduced && _started) {
      _controller.stop();
      _started = false;
    } else if (!reduced && !_started) {
      _controller.repeat(reverse: true);
      _started = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = Tween<double>(
      begin: 1,
      end: AppMotion.pulsarMinimo,
    ).chain(CurveTween(curve: AppMotion.mudar)).animate(_controller);
    return Semantics(
      label: 'A carregar',
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: opacity,
          child: RuledList(
            children: [
              for (var i = 0; i < widget.count; i++)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(widthFactor: 0.6, height: AppSpace.s24),
                      SizedBox(height: AppSpace.s12),
                      _Block(widthFactor: 0.35, height: AppSpace.s16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.esqueleto,
          borderRadius: AppRadius.carimboBorda,
        ),
      ),
    );
  }
}
