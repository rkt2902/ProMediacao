import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// Estado de interação passado ao `builder` de [AppPressable].
class PressState {
  const PressState({
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
    this.enabled = true,
  });

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool enabled;
}

/// Base partilhada de botões, separadores e ações: foco por teclado (Tab,
/// Enter, Espaço), hover, pressão e o anel de foco `foco` (2 de espessura,
/// 2 de afastamento). Sem ondas de Material.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.builder,
    required this.onPressed,
    this.borderRadius = AppRadius.controloBorda,
    this.semanticsLabel,
    this.selected,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget Function(BuildContext context, PressState state) builder;

  /// `null` desativa.
  final VoidCallback? onPressed;
  final BorderRadius borderRadius;
  final String? semanticsLabel;

  /// Não nulo marca o controlo como escolhível (separadores).
  final bool? selected;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final state = PressState(
      hovered: _hovered && _enabled,
      pressed: _pressed && _enabled,
      focused: _focused && _enabled,
      enabled: _enabled,
    );
    const ringOut = AppStroke.focoAfastamento;

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.selected == null ? null : true,
      label: widget.semanticsLabel,
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
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
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _enabled ? _activate : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.builder(context, state),
              Positioned(
                left: -(AppStroke.foco + ringOut),
                right: -(AppStroke.foco + ringOut),
                top: -(AppStroke.foco + ringOut),
                bottom: -(AppStroke.foco + ringOut),
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: AppMotion.resolve(context, AppMotion.rapido),
                    curve: AppMotion.mudar,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius.topLeft.x +
                            AppStroke.foco +
                            ringOut,
                      ),
                      border: Border.all(
                        color: state.focused
                            ? AppColors.foco
                            : AppColors.nenhuma,
                        width: AppStroke.foco,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
