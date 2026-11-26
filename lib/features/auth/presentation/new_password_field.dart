import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/password_rules.dart';
import 'auth_copy.dart';

/// Campo "Nova palavra-passe" com "Mostrar" e as 5 regras sempre visíveis
/// por baixo (03-design.md, 1d). As regras mudam em tempo real; com
/// [showErrors] (depois de tentar guardar com regras por cumprir) o campo
/// fica a `erro` e as regras em falta passam a `error_outline`.
/// Serve Definir, Criar e Alterar palavra-passe.
class NewPasswordField extends StatefulWidget {
  const NewPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.showErrors = false,
    this.readOnly = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool showErrors;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  State<NewPasswordField> createState() => _NewPasswordFieldState();
}

class _NewPasswordFieldState extends State<NewPasswordField> {
  bool _obscure = true;
  FocusNode? _ownFocus;
  String _summary = '';

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(NewPasswordField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.removeListener(_focusChanged);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  /// A leitura de ecrã ouve o total só ao sair do campo, não a cada tecla.
  void _focusChanged() {
    if (_focus.hasFocus) return;
    final met = PasswordCheck(widget.controller.text).met.length;
    setState(() => _summary = AuthCopy.rulesSummary(met));
  }

  @override
  Widget build(BuildContext context) {
    final check = PasswordCheck(widget.controller.text);
    final weak = widget.showErrors && !check.ok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledField(
          label: AuthCopy.newPassword,
          controller: widget.controller,
          focusNode: _focus,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: weak ? AuthCopy.weak(check.missing.length) : null,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          trailing: TextAction(
            label: _obscure ? AuthCopy.show : AuthCopy.hide,
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(
          AuthCopy.rulesHeader,
          style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s8),
        for (final rule in PasswordRule.values) ...[
          if (rule != PasswordRule.values.first)
            const SizedBox(height: AppSpace.s4),
          _RuleRow(
            text: AuthCopy.rule(rule),
            state: check.met.contains(rule)
                ? _RuleState.met
                : (widget.showErrors ? _RuleState.error : _RuleState.unmet),
          ),
        ],
        Semantics(
          liveRegion: true,
          label: _summary,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

enum _RuleState { unmet, met, error }

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.text, required this.state});

  final String text;
  final _RuleState state;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String spoken) = switch (state) {
      _RuleState.unmet => (
        Icons.circle_outlined,
        AppColors.tintaMedia,
        AuthCopy.ruleUnmet,
      ),
      _RuleState.met => (Icons.check_circle, AppColors.tinta, AuthCopy.ruleMet),
      _RuleState.error => (
        Icons.error_outline,
        AppColors.erro,
        AuthCopy.ruleMissing,
      ),
    };
    final style = AppType.corpoPequeno.copyWith(
      color: color,
      fontWeight: state == _RuleState.error ? FontWeight.w600 : null,
    );
    return Semantics(
      label: '$spoken: $text.',
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.rapido),
            switchInCurve: AppMotion.mudar,
            switchOutCurve: AppMotion.mudar,
            child: Icon(
              icon,
              key: ValueKey(state),
              size: AppSize.iconePequeno,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
