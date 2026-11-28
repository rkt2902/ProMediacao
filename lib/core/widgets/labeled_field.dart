import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

/// Campo com rótulo por cima (nunca só placeholder) e erro por baixo com
/// ícone. Altura `campo` (52), contorno `reguaForte` 1.5, foco `foco` 2.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
    this.optional = false,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Se não for nulo, o campo fica em erro e a mensagem aparece por baixo.
  final String? errorText;
  final String? helperText;
  final bool obscureText;

  /// A carregar: campo só de leitura.
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Ação dentro do campo (ex.: `TextAction` "Mostrar" / "Ocultar").
  final Widget? trailing;
  final bool autofocus;

  /// Acrescenta " (opcional)" ao rótulo, a 400 `tintaMedia`.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, optional: optional),
        const SizedBox(height: AppSpace.s8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.campo),
          child: Semantics(
            label: label,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              // Sem foco automático em compacto (abriria o teclado virtual).
              autofocus:
                  autofocus &&
                  AppBreakpoints.fromContext(context) != Breakpoint.compacto,
              obscureText: obscureText,
              readOnly: readOnly,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppType.corpo,
              cursorColor: AppColors.tinta,
              decoration: InputDecoration(
                // O erro é desenhado por baixo, com ícone; aqui só o contorno.
                error: hasError ? const SizedBox.shrink() : null,
                suffixIcon: trailing == null
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpace.s8,
                        ),
                        child: trailing,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minHeight: AppSize.alvoMinimo,
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.resolve(context, AppMotion.base),
          curve: AppMotion.entrar,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s8),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: AppSize.iconePequeno,
                          color: AppColors.erro,
                        ),
                        const SizedBox(width: AppSpace.s8),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: AppType.corpoPequeno.copyWith(
                              color: AppColors.erro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : (helperText != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpace.s8),
                        child: Text(
                          helperText!,
                          style: AppType.corpoPequeno.copyWith(
                            color: AppColors.tintaMedia,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity)),
        ),
      ],
    );
  }
}

/// Rótulo de campo (`rotulo`); com [optional] leva " (opcional)" a 400
/// `tintaMedia`.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    if (!optional) return Text(text, style: AppType.rotulo);
    return Text.rich(
      TextSpan(
        style: AppType.rotulo,
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' (opcional)',
            style: AppType.rotulo.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.tintaMedia,
            ),
          ),
        ],
      ),
    );
  }
}
