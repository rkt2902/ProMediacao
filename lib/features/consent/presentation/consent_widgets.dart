import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../domain/consent_models.dart';
import 'consent_copy.dart';

/// Texto de consentimento de uma versão, tal como está na base de dados
/// (`consent_texts.content`): parágrafos separados por linha em branco, em
/// `corpo` com `s16` entre eles, selecionável. `{escritório}` é trocado pelo
/// nome do escritório. No fim, `registo` "Versão do texto: …".
class ConsentTextView extends StatelessWidget {
  const ConsentTextView({
    super.key,
    required this.text,
    required this.officeName,
    this.beforeVersion,
  });

  final ConsentText text;
  final String officeName;

  /// Entre o texto e a versão (ex.: linha de apoio em altura baixa).
  final Widget? beforeVersion;

  static List<String> paragraphs(String content, String office) => content
      .replaceAll('\r\n', '\n')
      .replaceAll('{escritório}', office)
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final parts = paragraphs(text.content, officeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s16),
                Text(parts[i], style: AppType.corpo),
              ],
            ],
          ),
        ),
        if (beforeVersion != null) ...[
          const SizedBox(height: AppSpace.s24),
          beforeVersion!,
        ],
        const SizedBox(height: AppSpace.s24),
        Text(
          ConsentCopy.version(text.version),
          style: AppType.registo.copyWith(color: AppColors.tintaTenue),
        ),
      ],
    );
  }
}

/// Carimbo + data, na mesma linha; a data desce se não couber.
class StampWithDate extends StatelessWidget {
  const StampWithDate({super.key, required this.stamp, required this.date});

  final Widget stamp;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s12,
      runSpacing: AppSpace.s4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        stamp,
        Text(
          date,
          style: AppType.registo.copyWith(color: AppColors.tintaTenue),
        ),
      ],
    );
  }
}

/// Blocos `esqueleto` que pulsam (opacidade 1.0 a `pulsarMinimo`, ida e
/// volta em `pulsar`); estáticos com "reduzir movimento". Para skeletons com
/// forma própria (consentimento). Anunciado como "A carregar".
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
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
      _controller.value = 0;
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
        child: FadeTransition(opacity: opacity, child: widget.child),
      ),
    );
  }
}

/// Um bloco `esqueleto` com [widthFactor] da largura e [height].
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.widthFactor,
    required this.height,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.esqueleto,
          borderRadius: AppRadius.controloBorda,
        ),
      ),
    );
  }
}
