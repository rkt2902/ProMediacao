import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_pressable.dart';

/// Sino de notificações (002, só cliente), para a linha da conta.
///
/// Ícone + palavra "Notificações" (médio/largo; em compacto só o ícone) +
/// contador retangular a `tinta` AO LADO (nunca um `Badge` sobreposto).
/// - [unread] `null` ou 0: sem contador (nunca se mostra "0"; `null` é
///   "ainda não sei" e também fica sem contador). 1 a 9 o número; acima de 9
///   "9+".
/// - [open] marca o painel aberto: fundo `cartolina`.
/// - Leitura de ecrã e tooltip: "Notificações, 2 por ler", uma só vez.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.onPressed,
    this.unread,
    this.open = false,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final int? unread;
  final bool open;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Texto do contador, ou `null` quando não há nada por ler.
  static String? counterText(int? unread) {
    if (unread == null || unread <= 0) return null;
    return unread > 9 ? '9+' : '$unread';
  }

  static String spokenLabel(int? unread) {
    if (unread == null || unread <= 0) return 'Notificações';
    return 'Notificações, $unread por ler';
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final dur = AppMotion.resolve(context, AppMotion.base);
    final counter = counterText(unread);
    final spoken = spokenLabel(unread);

    return Tooltip(
      message: spoken,
      excludeFromSemantics: true,
      child: AppPressable(
        onPressed: onPressed,
        semanticsLabel: spoken,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, s) => ExcludeSemantics(
          child: AnimatedContainer(
            duration: dur,
            curve: AppMotion.mudar,
            constraints: const BoxConstraints(
              minHeight: AppSize.alvoMinimo,
              minWidth: AppSize.alvoMinimo,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            decoration: BoxDecoration(
              color: open
                  ? AppColors.cartolina
                  : (s.hovered ? AppColors.realce : AppColors.nenhuma),
              borderRadius: AppRadius.controloBorda,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: AppSize.icone,
                  color: AppColors.tinta,
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpace.s4),
                  Text(
                    'Notificações',
                    style: AppType.corpoPequeno.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.tinta,
                      decorationThickness: s.hovered || s.pressed
                          ? AppStroke.foco
                          : AppStroke.fino,
                    ),
                  ),
                ],
                AnimatedSize(
                  duration: dur,
                  curve: AppMotion.mudar,
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedSwitcher(
                    duration: dur,
                    switchInCurve: AppMotion.mudar,
                    switchOutCurve: AppMotion.mudar,
                    child: counter == null
                        ? const SizedBox.shrink(key: ValueKey('sem-contador'))
                        : Padding(
                            key: const ValueKey('contador'),
                            padding: const EdgeInsetsDirectional.only(
                              start: AppSpace.s4,
                            ),
                            child: _Counter(text: counter),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppSize.iconePequeno,
        minHeight: AppSize.iconePequeno,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.tinta,
        borderRadius: AppRadius.carimboBorda,
      ),
      child: Text(
        text,
        style: AppType.carimbo.copyWith(
          color: AppColors.sobreTinta,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
