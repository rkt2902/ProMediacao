import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_pressable.dart';

enum _ButtonKind { primary, secondary, destructive }

/// Corpo comum dos botões cheios/contornados: altura mínima por alvo,
/// spinner só aqui dentro (cross-fade, a largura não muda) e razão do
/// estado desativado escrita por baixo.
class _AppButton extends StatelessWidget {
  const _AppButton({
    required this.kind,
    required this.label,
    required this.onPressed,
    required this.loading,
    required this.loadingLabel,
    required this.principal,
    required this.expand,
    required this.disabledReason,
    this.labelColor,
  });

  final _ButtonKind kind;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool principal;
  final bool expand;
  final String? disabledReason;

  /// Só o botão secundário "Retirar acesso" usa `erro` no texto.
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !loading;
    final height = principal ? AppSize.alvoPrincipal : AppSize.alvoMinimo;
    final dur = AppMotion.resolve(context, AppMotion.rapido);

    final button = AppPressable(
      onPressed: active ? onPressed : null,
      semanticsLabel: loading ? (loadingLabel ?? label) : null,
      builder: (context, s) {
        final filled = kind != _ButtonKind.secondary;
        final base = kind == _ButtonKind.destructive
            ? AppColors.erro
            : AppColors.tinta;
        // Desativado/a carregar: o botão mantém o aspeto "cheio" mas mais
        // claro; o texto continua legível (contraste >= 3 no contorno).
        final Color bg;
        final Color fg;
        final Color border;
        if (filled) {
          // Hover e pressão escurecem para `tintaMedia`; o destrutivo
          // mantém sempre o vermelho-lacre.
          bg = !s.enabled && !loading
              ? AppColors.regua
              : (s.pressed || s.hovered) && kind == _ButtonKind.primary
              ? AppColors.tintaMedia
              : base;
          fg = !s.enabled && !loading
              ? AppColors.tintaMedia
              : AppColors.sobreTinta;
          border = bg;
        } else {
          bg = s.pressed || s.hovered ? AppColors.realce : AppColors.nenhuma;
          fg = !s.enabled && !loading
              ? AppColors.tintaTenue
              : (labelColor ?? AppColors.tinta);
          border = !s.enabled && !loading
              ? AppColors.regua
              : AppColors.reguaForte;
        }
        final style =
            (kind == _ButtonKind.secondary
                    ? AppType.rotulo.copyWith(
                        fontSize: AppType.botao.fontSize,
                        height: AppType.botao.height,
                      )
                    : AppType.botao)
                .copyWith(color: fg);

        return AnimatedContainer(
          duration: dur,
          curve: AppMotion.mudar,
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.controloBorda,
            border: Border.all(color: border, width: AppStroke.controlo),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: dur,
                curve: AppMotion.mudar,
                opacity: loading ? 0 : 1,
                child: Text(label, style: style, textAlign: TextAlign.center),
              ),
              AnimatedOpacity(
                duration: dur,
                curve: AppMotion.mudar,
                opacity: loading ? 1 : 0,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: AppSize.iconePequeno,
                        height: AppSize.iconePequeno,
                        child: CircularProgressIndicator(
                          strokeWidth: AppStroke.controlo,
                          color: fg,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Text(loadingLabel ?? label, style: style),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final showReason = onPressed == null && !loading && disabledReason != null;
    final content = Column(
      crossAxisAlignment: expand
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        if (showReason) ...[
          const SizedBox(height: AppSpace.s8),
          Text(
            disabledReason!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ],
    );
    return expand ? content : IntrinsicWidth(child: content);
  }
}

/// Botão cheio a `tinta`: a ação principal do ecrã. O spinner só existe aqui.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.principal = false,
    this.expand = false,
    this.disabledReason,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  /// Ação principal do cliente: `alvoPrincipal` (56) em vez de 48.
  final bool principal;
  final bool expand;

  /// Razão escrita por baixo quando `onPressed` é nulo.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) => _AppButton(
    kind: _ButtonKind.primary,
    label: label,
    onPressed: onPressed,
    loading: loading,
    loadingLabel: loadingLabel,
    principal: principal,
    expand: expand,
    disabledReason: disabledReason,
  );
}

/// Botão com contorno `reguaForte` de 1.5.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.principal = false,
    this.expand = false,
    this.disabledReason,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool principal;
  final bool expand;
  final String? disabledReason;

  /// Texto em `erro` (ex.: "Retirar acesso" na linha da lista).
  final bool danger;

  @override
  Widget build(BuildContext context) => _AppButton(
    kind: _ButtonKind.secondary,
    label: label,
    onPressed: onPressed,
    loading: loading,
    loadingLabel: loadingLabel,
    principal: principal,
    expand: expand,
    disabledReason: disabledReason,
    labelColor: danger ? AppColors.erro : null,
  );
}

/// Botão cheio a `erro`: só para ações destrutivas ("Retirar acesso").
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.principal = false,
    this.expand = false,
    this.disabledReason,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool principal;
  final bool expand;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) => _AppButton(
    kind: _ButtonKind.destructive,
    label: label,
    onPressed: onPressed,
    loading: loading,
    loadingLabel: loadingLabel,
    principal: principal,
    expand: expand,
    disabledReason: disabledReason,
  );
}

/// Ação de linha sublinhada. Alvo mínimo de 48 de altura. Se estiver
/// desativada, `disabledReason` vai para o tooltip e para a leitura de ecrã.
class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.disabledReason,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final String? disabledReason;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null && !loading;
    final dur = AppMotion.resolve(context, AppMotion.rapido);

    Widget action = AppPressable(
      onPressed: active ? onPressed : null,
      semanticsLabel: loading
          ? (loadingLabel ?? label)
          : (!active && disabledReason != null
                ? '$label. $disabledReason'
                : null),
      builder: (context, s) {
        final color = !s.enabled && !loading
            ? AppColors.tintaTenue
            : (danger ? AppColors.erro : AppColors.tinta);
        final style = AppType.corpoPequeno.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationThickness: s.hovered || s.pressed
              ? AppStroke.foco
              : AppStroke.fino,
        );
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.alvoMinimo),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
              child: AnimatedSwitcher(
                duration: dur,
                switchInCurve: AppMotion.mudar,
                child: loading
                    ? Row(
                        key: const ValueKey('loading'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: AppSize.iconePequeno,
                            height: AppSize.iconePequeno,
                            child: CircularProgressIndicator(
                              strokeWidth: AppStroke.controlo,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s8),
                          Text(
                            loadingLabel ?? label,
                            style: style.copyWith(
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      )
                    : Text(label, key: const ValueKey('label'), style: style),
              ),
            ),
          ),
        );
      },
    );

    if (!active && !loading && disabledReason != null) {
      action = Tooltip(message: disabledReason!, child: action);
    }
    return action;
  }
}
