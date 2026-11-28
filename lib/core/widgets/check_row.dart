import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

/// Linha de verificação (002): caixa própria de `icone` 24 + texto, alvo de
/// 48 na linha toda. Sem `Checkbox` nem `CheckboxListTile` do Material.
/// Pensada para ir dentro de uma `RuledList` (as réguas são da lista).
///
/// - [label] é o texto principal (e o nome falado); [description] é um apoio
///   opcional em `corpoPequeno`; [trailing] um widget à direita (ex.: um
///   [TagLabel]); [below] conteúdo por baixo do texto (ex.: um aviso).
/// - `onChanged == null` desativa (caixa a `esqueleto`, texto `tintaTenue`).
/// - Semântica: uma caixa de verificação, lida uma só vez (o texto visual
///   fica excluído; [description] entra na leitura).
/// - Foco de teclado: anel `foco` na caixa; Espaço e Enter alternam.
class CheckRow extends StatefulWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.description,
    this.trailing,
    this.below,
    this.autofocus = false,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? description;
  final Widget? trailing;
  final Widget? below;
  final bool autofocus;

  @override
  State<CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<CheckRow> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  void _toggle() => widget.onChanged?.call(!widget.checked);

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.resolve(context, AppMotion.rapido);
    final textColor = _enabled ? AppColors.tinta : AppColors.tintaTenue;
    final spoken = widget.description == null
        ? widget.label
        : '${widget.label}. ${widget.description}';

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.alvoMinimo),
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.mudar,
        color: _hovered && _enabled ? AppColors.realce : AppColors.nenhuma,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Box(
              checked: widget.checked,
              enabled: _enabled,
              focused: _focused,
              duration: dur,
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: (widget.checked ? AppType.corpoForte : AppType.corpo)
                        .copyWith(color: textColor),
                  ),
                  if (widget.description != null)
                    Text(
                      widget.description!,
                      style: AppType.corpoPequeno.copyWith(
                        color: _enabled
                            ? AppColors.tintaMedia
                            : AppColors.tintaTenue,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: AppSpace.s12),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          checked: widget.checked,
          enabled: _enabled,
          label: spoken,
          onTap: _enabled ? _toggle : null,
          child: ExcludeSemantics(
            child: FocusableActionDetector(
              enabled: _enabled,
              autofocus: widget.autofocus,
              mouseCursor: _enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onShowHoverHighlight: (v) => setState(() => _hovered = v),
              onShowFocusHighlight: (v) => setState(() => _focused = v),
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _toggle();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _enabled ? _toggle : null,
                child: row,
              ),
            ),
          ),
        ),
        ?widget.below,
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.checked,
    required this.enabled,
    required this.focused,
    required this.duration,
  });

  final bool checked;
  final bool enabled;
  final bool focused;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    const ring = AppStroke.foco + AppStroke.focoAfastamento;
    final Color fill;
    final Color border;
    if (!enabled) {
      fill = AppColors.esqueleto;
      border = AppColors.regua;
    } else if (checked) {
      fill = AppColors.tinta;
      border = AppColors.tinta;
    } else {
      fill = AppColors.folha;
      border = AppColors.reguaForte;
    }
    return SizedBox(
      width: AppSize.icone,
      height: AppSize.icone,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              key: const ValueKey('caixa'),
              duration: duration,
              curve: AppMotion.mudar,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadius.carimboBorda,
                border: Border.all(color: border, width: AppStroke.controlo),
              ),
              child: checked
                  ? Icon(
                      Icons.check,
                      size: AppSize.iconePequeno,
                      color: enabled
                          ? AppColors.sobreTinta
                          : AppColors.tintaTenue,
                    )
                  : null,
            ),
          ),
          Positioned(
            left: -ring,
            right: -ring,
            top: -ring,
            bottom: -ring,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.mudar,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.carimbo + ring),
                  border: Border.all(
                    color: focused ? AppColors.foco : AppColors.nenhuma,
                    width: AppStroke.foco,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
