import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';

/// Número de etapas de um pedido.
const int kStageCount = 4;

/// Trilho de etapas (002): 4 segmentos de `segmentoEtapa` x `AppStroke.etapa`
/// com `s4` entre eles (feitos a `tinta`, os outros a `regua`) e a palavra
/// ao lado, nunca só o trilho. Sem animação.
///
/// [stage] é a etapa atual (1 a 4; os segmentos 1..stage ficam cheios).
/// [label] é a palavra visível ("Criado"). A leitura de ecrã é uma só frase,
/// [semanticsLabel] ou "Etapa {stage} de 4: {label}"; os segmentos ficam
/// excluídos.
class StageTrack extends StatelessWidget {
  const StageTrack({
    super.key,
    required this.stage,
    required this.label,
    this.semanticsLabel,
    this.stacked = false,
  }) : assert(stage >= 0 && stage <= kStageCount);

  final int stage;
  final String label;
  final String? semanticsLabel;

  /// A palavra fica sempre por baixo dos segmentos (colunas estreitas, para
  /// a posição não depender do comprimento da palavra).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticsLabel ?? 'Etapa $stage de $kStageCount: $label',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final segments = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < kStageCount; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.s4),
                Container(
                  key: ValueKey('segmento-$i'),
                  width: AppSize.segmentoEtapa,
                  height: AppStroke.etapa,
                  color: i < stage ? AppColors.tinta : AppColors.regua,
                ),
              ],
            ],
          );
          const trackWidth =
              kStageCount * AppSize.segmentoEtapa +
              (kStageCount - 1) * AppSpace.s4;
          final painter = TextPainter(
            text: TextSpan(text: label, style: AppType.corpoPequeno),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          // Se a palavra não cabe numa linha ao lado dos segmentos, desce
          // para baixo deles (nunca parte a meio ao lado do trilho).
          final below =
              stacked ||
              c.hasBoundedWidth &&
                  trackWidth + AppSpace.s8 + painter.width > c.maxWidth;
          final text = Text(label, style: AppType.corpoPequeno);
          if (below) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                segments,
                const SizedBox(height: AppSpace.s4),
                text,
              ],
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              segments,
              const SizedBox(width: AppSpace.s8),
              Flexible(child: text),
            ],
          );
        },
      ),
    );
  }
}
