import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_buttons.dart';
import 'inline_notice.dart';

/// Conteúdo de uma confirmação: título, texto e dois botões. Usar com
/// [showConfirmSheet], que o apresenta como folha inferior em compacto e
/// como diálogo (480) em médio/largo.
///
/// Se [confirmLabel] for nulo, é uma folha só de leitura (um botão de
/// fechar); nesse caso passar `readOnly: true` a [showConfirmSheet] (diálogo
/// de 640, folha alta em compacto). O foco inicial fica em "Cancelar"/"Fechar".
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.loadingLabel,
    this.loading = false,
    this.errorMessage,
    this.destructive = true,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String? message;

  /// Conteúdo livre (ex.: texto de consentimento), com scroll.
  final Widget? body;
  final String? confirmLabel;
  final String cancelLabel;
  final String? loadingLabel;
  final bool loading;

  /// Falha ao confirmar: aparece dentro da folha e a ação mantém-se.
  final String? errorMessage;
  final bool destructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final cancel = onCancel ?? () => Navigator.of(context).maybePop();

    final cancelButton = SecondaryButton(
      label: cancelLabel,
      onPressed: loading ? null : cancel,
      autofocus: true,
      expand: compact,
      principal: compact,
    );
    final confirmButton = confirmLabel == null
        ? null
        : (destructive
              ? DestructiveButton(
                  label: confirmLabel!,
                  loadingLabel: loadingLabel,
                  loading: loading,
                  onPressed: onConfirm,
                  expand: compact,
                  principal: compact,
                )
              : PrimaryButton(
                  label: confirmLabel!,
                  loadingLabel: loadingLabel,
                  loading: loading,
                  onPressed: onConfirm,
                  expand: compact,
                  principal: compact,
                ));

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: title,
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s24,
                AppSpace.s16,
                AppSpace.s24,
              )
            : const EdgeInsets.all(AppSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Texto com scroll; os botões ficam fixos em baixo.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppType.subtitulo),
                    if (message != null) ...[
                      const SizedBox(height: AppSpace.s12),
                      Text(message!, style: AppType.corpo),
                    ],
                    if (body != null) ...[
                      const SizedBox(height: AppSpace.s12),
                      body!,
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppSpace.s16),
                      InlineNotice(
                        message: errorMessage!,
                        kind: NoticeKind.erro,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s24),
            if (compact)
              // Destrutivo em cima, empilhados.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?confirmButton,
                  if (confirmButton != null)
                    const SizedBox(height: AppSpace.s12),
                  cancelButton,
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpace.s12,
                runSpacing: AppSpace.s12,
                children: [cancelButton, ?confirmButton],
              ),
          ],
        ),
      ),
    );
  }
}

/// Apresenta [builder] (normalmente um [ConfirmSheet]) como folha inferior
/// em compacto (entra `lento`, sai `base`) e como diálogo de 480 em
/// médio/largo (entra `base` com escala 0.98 a 1.0, sai `rapido`).
///
/// [readOnly] (texto aceite): diálogo de `larguraLeitura` 640 e, em compacto,
/// folha alta (janela menos `s48`). Em altura baixa a folha ocupa a janela
/// menos `s16`. Ao fechar, o foco volta ao controlo que a abriu. A folha é
/// uma rota do `Navigator`: Esc, véu e "voltar" fecham-na.
Future<T?> showConfirmSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool readOnly = false,
}) async {
  final origin = FocusManager.instance.primaryFocus;
  final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
  final height = MediaQuery.sizeOf(context).height;
  final low = height < AppBreakpoints.alturaBaixa;
  final inset = low ? AppSpace.s16 : AppSpace.s48;

  final Future<T?> result;
  if (compact) {
    result = showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: barrierDismissible,
      enableDrag: false,
      constraints: BoxConstraints(maxHeight: height - inset),
      backgroundColor: AppColors.folha,
      barrierColor: AppColors.veu,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.folhaInferiorBorda,
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppMotion.lento),
        curve: AppMotion.entrar,
        reverseDuration: AppMotion.resolve(context, AppMotion.base),
        reverseCurve: AppMotion.sair,
      ),
      builder: builder,
    );
  } else {
    result = showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.veu,
      transitionDuration: AppMotion.resolve(context, AppMotion.base),
      pageBuilder: (context, _, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: readOnly ? AppSize.larguraLeitura : AppSize.dialogo,
                maxHeight: height - 2 * inset,
              ),
              child: Material(
                color: AppColors.folha,
                borderRadius: AppRadius.superficieBorda,
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: AppRadius.superficieBorda,
                    boxShadow: AppShadow.superficie,
                  ),
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondary, child) {
        final enter = CurvedAnimation(
          parent: animation,
          curve: AppMotion.entrar,
          reverseCurve: AppMotion.sair,
        );
        return FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: AppMotion.escalaDialogo,
              end: 1,
            ).animate(enter),
            child: child,
          ),
        );
      },
    );
  }

  final value = await result;
  // Devolve o foco ao botão de origem (se ainda existir).
  if (origin != null && origin.context != null && origin.canRequestFocus) {
    origin.requestFocus();
  }
  return value;
}
