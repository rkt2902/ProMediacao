import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_copy.dart';

/// Confirmação em fundo `realce` com o email em `corpoForte`
/// (03-design.md, ecrã 1). O `InlineNotice` só aceita texto simples.
class SentNotice extends StatelessWidget {
  const SentNotice({
    super.key,
    required this.before,
    this.emphasis,
    this.after = '',
    this.children = const [],
  });

  final String before;
  final String? emphasis;
  final String after;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.s24),
        decoration: const BoxDecoration(
          color: AppColors.realce,
          borderRadius: AppRadius.controloBorda,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.mail_outline,
              size: AppSize.icone,
              color: AppColors.tinta,
            ),
            const SizedBox(width: AppSpace.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppType.corpo,
                      children: [
                        TextSpan(text: before),
                        if (emphasis != null)
                          TextSpan(text: emphasis, style: AppType.corpoForte),
                        TextSpan(text: after),
                      ],
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmação do link de acesso (Entrar e link expirado): "Enviar outra
/// vez" bloqueado 60 s com a razão escrita e "Usar outro email".
class LinkSentNotice extends StatelessWidget {
  const LinkSentNotice({super.key, this.onUseAnotherEmail});

  final VoidCallback? onUseAnotherEmail;

  @override
  Widget build(BuildContext context) {
    final link = AppScope.of(context).clientLink;
    return ListenableBuilder(
      listenable: link,
      builder: (context, _) {
        final locked = link.remaining > 0;
        return SentNotice(
          before: AuthCopy.sentBefore,
          emphasis: link.email,
          after: AuthCopy.sentAfter,
          children: [
            const SizedBox(height: AppSpace.s16),
            TextAction(
              label: AuthCopy.sendAgain,
              onPressed: locked ? null : () => link.send(link.email),
              disabledReason: locked
                  ? AuthCopy.waitToResend(link.remaining)
                  : null,
            ),
            TextAction(
              label: AuthCopy.otherEmail,
              onPressed: () {
                link.useAnotherEmail();
                onUseAnotherEmail?.call();
              },
            ),
          ],
        );
      },
    );
  }
}
