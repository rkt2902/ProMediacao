import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../domain/notification_models.dart';
import 'client_frame.dart';
import 'notifications_body.dart';
import 'notifications_copy.dart';

/// Notificações em ecrã inteiro (compacto; rota `AppRoutes.clientNotifications`).
/// Em médio/largo o sino abre o painel lateral em vez desta rota, mas se
/// alguém chegar aqui (link, janela redimensionada) mostra-se a mesma lista.
/// Sem colofão: é uma passagem, não uma página. O sino aparece "aberto".
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final controller = AppScope.of(context).notifications;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadFirstPage();
    });
  }

  void _open(AppNotification n) {
    final id = AppScope.of(context).notifications.open(n);
    if (id != null) context.go(AppRoutes.clientRequest(id));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).notifications;
    final bp = AppBreakpoints.fromContext(context);
    return ClientFrame(
      notificationsScreen: true,
      backLabel: NotificationsCopy.backToRequests,
      backTo: AppRoutes.client,
      colophon: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpace.s12,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    NotificationsCopy.title,
                    style: AppType.tituloPara(bp),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final summary = notificationsSummary(controller);
                    return summary == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.s8),
                            child: Text(
                              summary,
                              style: AppType.registo.copyWith(
                                color: AppColors.tintaMedia,
                              ),
                            ),
                          );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s24),
            NotificationsBody(controller: controller, onOpen: _open),
            const SizedBox(height: AppSpace.s48),
          ],
        ),
      ),
    );
  }
}
