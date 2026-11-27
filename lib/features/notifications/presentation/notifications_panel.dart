import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/notification_models.dart';
import 'notifications_body.dart';
import 'notifications_copy.dart';

/// Abre o painel de notificações (médio/largo): folha lateral de
/// `folhaLateral` 440 à direita, com véu, Esc para fechar e o foco devolvido
/// a quem a abriu (o sino). Em compacto o sino abre o ecrã
/// [AppRoutes.clientNotifications] em vez disto.
Future<void> showNotificationsPanel(BuildContext context) async {
  final origin = FocusManager.instance.primaryFocus;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.veu,
    transitionDuration: AppMotion.resolve(context, AppMotion.lento),
    pageBuilder: (context, _, _) => Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: AppSize.folhaLateral,
        height: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.folha,
            boxShadow: AppShadow.superficie,
          ),
          child: Material(
            color: AppColors.folha,
            child: SafeArea(child: const NotificationsPanel()),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entrar,
        reverseCurve: AppMotion.sair,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
  if (origin != null && origin.context != null && origin.canRequestFocus) {
    origin.requestFocus();
  }
}

/// Conteúdo da folha lateral: cabeçalho ("Notificações" + "2 por ler" +
/// "Fechar") e a lista. O foco inicial fica no título.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.of(context).notifications.loadFirstPage();
  }

  /// `open` marca como lida sem esperar; o contador desce quando o servidor
  /// confirmar. A seguir fecha a folha e vai ao pedido.
  void _open(AppNotification n) {
    final controller = AppScope.of(context).notifications;
    final id = controller.open(n);
    if (id == null) return;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.clientRequest(id));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final controller = services.notifications;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: services.connectivity,
          builder: (context, _) =>
              OfflineBar(visible: !services.connectivity.online),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Focus(
                  autofocus: true,
                  child: Semantics(
                    header: true,
                    child: Text(
                      NotificationsCopy.title,
                      style: AppType.subtitulo,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final summary = notificationsSummary(controller);
                  return summary == null
                      ? const SizedBox.shrink()
                      : Text(
                          summary,
                          style: AppType.registo.copyWith(
                            color: AppColors.tintaMedia,
                          ),
                        );
                },
              ),
              const Spacer(),
              TextAction(
                label: NotificationsCopy.close,
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const AppRule(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s24,
              AppSpace.s8,
              AppSpace.s24,
              AppSpace.s24,
            ),
            child: NotificationsBody(controller: controller, onOpen: _open),
          ),
        ),
      ],
    );
  }
}
