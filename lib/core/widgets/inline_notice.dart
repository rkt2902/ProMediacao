import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_buttons.dart';

enum NoticeKind { info, aviso, erro }

/// Mensagem dentro do fluxo, com ação opcional. Aparece com opacidade e
/// altura (`base` / `entrar`). `info` e `aviso` em fundo `realce`; `erro`
/// em `folha` com contorno `erro`. Sempre com ícone + texto.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.message,
    this.detail,
    this.kind = NoticeKind.info,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String message;

  /// Explicação por baixo da mensagem (`corpoPequeno` `tintaMedia`); com ela,
  /// a mensagem passa a `corpoForte` (ex.: credenciais erradas + dica do link).
  final String? detail;
  final NoticeKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.resolve(context, AppMotion.base);
    final (IconData defaultIcon, Color iconColor) = switch (kind) {
      NoticeKind.info => (Icons.info_outline, AppColors.tinta),
      NoticeKind.aviso => (Icons.warning_amber, AppColors.estadoPendente),
      NoticeKind.erro => (Icons.error_outline, AppColors.erro),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: dur,
      curve: AppMotion.entrar,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: child,
          ),
        ),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: kind == NoticeKind.erro ? AppColors.folha : AppColors.realce,
            borderRadius: AppRadius.controloBorda,
            border: kind == NoticeKind.erro
                ? Border.all(color: AppColors.erro, width: AppStroke.controlo)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon ?? defaultIcon,
                    size: AppSize.icone,
                    color: iconColor,
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: detail == null
                              ? AppType.corpo
                              : AppType.corpoForte,
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            detail!,
                            style: AppType.corpoPequeno.copyWith(
                              color: AppColors.tintaMedia,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSize.icone + AppSpace.s12,
                  ),
                  child: TextAction(label: actionLabel!, onPressed: onAction),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
