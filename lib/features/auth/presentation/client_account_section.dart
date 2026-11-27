import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_copy.dart';

/// Secção "A sua conta" no fim de "Com quem partilho" (03-design.md, ecrã
/// 4): email e estado da palavra-passe, com "Criar palavra-passe" ou
/// "Alterar palavra-passe" (abre o ecrã 1c). A ação fica à direita em
/// médio/largo e por baixo a toda a largura em compacto, ou quando a zona de
/// texto fica abaixo de `textoMinimo`. Para a tarefa 5 incluir no ecrã real.
class ClientAccountSection extends StatelessWidget {
  const ClientAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session.session;
        final hasPassword = s?.hasPassword ?? false;
        final setAt = s?.passwordSetAt;
        final label = AppType.rotulo.copyWith(color: AppColors.tintaMedia);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(AuthCopy.accountTitle, style: AppType.subtitulo),
            ),
            const SizedBox(height: AppSpace.s16),
            RuledList(
              children: [
                RuledRow(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AuthCopy.email, style: label),
                      const SizedBox(height: AppSpace.s4),
                      SelectableText(s?.email ?? '', style: AppType.corpo),
                    ],
                  ),
                ),
                RuledRow(
                  child: _PasswordRow(
                    label: label,
                    status: !hasPassword
                        ? Text(AuthCopy.noPassword, style: AppType.corpo)
                        : (setAt == null
                              ? Text(
                                  AuthCopy.passwordCreated,
                                  style: AppType.corpo,
                                )
                              : Text.rich(
                                  TextSpan(
                                    style: AppType.corpo,
                                    children: [
                                      const TextSpan(
                                        text: AuthCopy.createdBefore,
                                      ),
                                      TextSpan(
                                        text: AppDates.date(setAt),
                                        style: AppType.registo,
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  semanticsLabel: AuthCopy.passwordCreatedAt(
                                    AppDates.date(setAt),
                                  ),
                                )),
                    action: (expand) => SecondaryButton(
                      label: hasPassword
                          ? AuthCopy.changeTitle
                          : AuthCopy.createTitle,
                      expand: expand,
                      onPressed: () => context.go(AppRoutes.clientPassword),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PasswordRow extends StatelessWidget {
  const _PasswordRow({
    required this.label,
    required this.status,
    required this.action,
  });

  final TextStyle label;
  final Widget status;
  final Widget Function(bool expand) action;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AuthCopy.password, style: label),
        const SizedBox(height: AppSpace.s4),
        status,
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        // Reserva para a ação ao lado: a coluna de ação das tabelas.
        final sideBySide =
            !compact &&
            c.maxWidth - AppSize.colunaAcao - AppSpace.s24 >=
                AppSize.textoMinimo;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: AppSpace.s16),
              action(true),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: AppSpace.s24),
            action(false),
          ],
        );
      },
    );
  }
}
