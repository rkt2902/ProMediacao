import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import 'folder_tab.dart';
import 'ruled_list.dart';
import 'stage_track.dart';

/// Uma etapa da [StageStrip]: nome e data já formatada (null se não há data).
class StageStripStep {
  const StageStripStep({required this.name, this.date});

  final String name;

  /// Texto da data de conclusão (ex.: "27 nov 2026, 10:14"). Só conta se a
  /// etapa estiver feita.
  final String? date;
}

/// Faixa de etapas (002): 4 colunas com réguas (médio/largo) ou 4 linhas
/// empilhadas (compacto). Barra de `AppStroke.etapa` a `tinta` nas etapas
/// feitas, `regua` nas outras. Etapas 1..[current] estão feitas.
///
/// Semântica: lista de 4 itens, "Etapa 1, Criado, feita a ..." ou
/// "..., por fazer"; o conteúdo visual fica excluído (lido uma só vez).
class StageStrip extends StatelessWidget {
  const StageStrip({super.key, required this.steps, required this.current})
    : assert(steps.length == kStageCount);

  final List<StageStripStep> steps;
  final int current;

  String _spoken(int i) {
    final s = steps[i];
    final done = i < current;
    final state = !done
        ? 'por fazer'
        : (s.date == null ? 'feita' : 'feita a ${s.date}');
    return 'Etapa ${i + 1}, ${s.name}, $state';
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final items = [
      for (var i = 0; i < kStageCount; i++)
        Semantics(
          container: true,
          label: _spoken(i),
          excludeSemantics: true,
          child: compact
              ? _Row(index: i, step: steps[i], done: i < current)
              : _Column(
                  index: i,
                  step: steps[i],
                  done: i < current,
                  first: i == 0,
                ),
        ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: compact
          ? RuledList(children: items)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRule(),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const AppRule(vertical: true),
                        Expanded(child: items[i]),
                      ],
                    ],
                  ),
                ),
                const AppRule(),
              ],
            ),
    );
  }
}

class _When extends StatelessWidget {
  const _When({required this.step, required this.done});

  final StageStripStep step;
  final bool done;

  @override
  Widget build(BuildContext context) {
    if (!done) {
      return Text(
        'Por fazer',
        style: AppType.registo.copyWith(color: AppColors.tintaMedia),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          size: AppSize.iconePequeno,
          color: AppColors.tinta,
        ),
        if (step.date != null) ...[
          const SizedBox(width: AppSpace.s4),
          Flexible(child: Text(step.date!, style: AppType.registo)),
        ],
      ],
    );
  }
}

TextStyle _nameStyle(bool done) => done
    ? AppType.corpoPequeno.copyWith(fontWeight: FontWeight.w600)
    : AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia);

TextStyle _numberStyle(bool done) => done
    ? AppType.subtitulo
    : AppType.subtitulo.copyWith(color: AppColors.tintaTenue);

class _Column extends StatelessWidget {
  const _Column({
    required this.index,
    required this.step,
    required this.done,
    required this.first,
  });

  final int index;
  final StageStripStep step;
  final bool done;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('etapa-$index'),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: done ? AppColors.tinta : AppColors.regua,
            width: AppStroke.etapa,
          ),
        ),
      ),
      padding: EdgeInsetsDirectional.only(
        start: first ? 0 : AppSpace.s16,
        end: AppSpace.s16,
        top: AppSpace.s16,
        bottom: AppSpace.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}', style: _numberStyle(done)),
          const SizedBox(height: AppSpace.s4),
          Text(step.name, style: _nameStyle(done)),
          const SizedBox(height: AppSpace.s8),
          _When(step: step, done: done),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, required this.step, required this.done});

  final int index;
  final StageStripStep step;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      key: ValueKey('etapa-$index'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de 4 à esquerda só nas etapas feitas; o espaço mantém-se.
          Container(
            width: AppStroke.etapa,
            color: done ? AppColors.tinta : AppColors.nenhuma,
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSpace.s24,
                    child: Text('${index + 1}', style: _numberStyle(done)),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.name, style: _nameStyle(done)),
                        const SizedBox(height: AppSpace.s4),
                        _When(step: step, done: done),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
