import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../application/notifications_controller.dart';
import '../domain/notification_models.dart';
import 'notifications_copy.dart';

/// Texto do cabeçalho: "2 por ler" / "Todas lidas" (nulo enquanto não se
/// sabe).
String? notificationsSummary(NotificationsController c) {
  if (c.load != NotificationsLoad.ready) return null;
  final n = c.unread;
  if (n == null) return null;
  return n == 0 ? NotificationsCopy.allRead : NotificationsCopy.unreadCount(n);
}

/// Estados e lista de notificações, partilhados pelo painel (médio/largo) e
/// pelo ecrã inteiro (compacto). [onOpen] abre a notificação: quem chama
/// marca-a como lida (sem esperar) e navega.
class NotificationsBody extends StatelessWidget {
  const NotificationsBody({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  final NotificationsController controller;
  final void Function(AppNotification n) onOpen;

  @override
  Widget build(BuildContext context) {
    final connectivity = AppScope.of(context).connectivity;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, connectivity]),
      builder: (context, _) {
        switch (controller.load) {
          case NotificationsLoad.idle || NotificationsLoad.loading:
            return const SkeletonRows(count: 4);
          case NotificationsLoad.error:
            return InlineNotice(
              kind: NoticeKind.erro,
              message: NotificationsCopy.loadFailed,
              actionLabel: NotificationsCopy.retry,
              onAction: controller.loadFirstPage,
            );
          case NotificationsLoad.ready:
            break;
        }
        if (controller.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(NotificationsCopy.emptyTitle, style: AppType.corpoForte),
              const SizedBox(height: AppSpace.s8),
              Text(
                NotificationsCopy.emptyHelp,
                style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
              ),
            ],
          );
        }
        final online = connectivity.online;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.stale) ...[
              InlineNotice(
                icon: online ? null : Icons.cloud_off,
                message: online
                    ? NotificationsCopy.staleOnline(controller.syncedAt)
                    : NotificationsCopy.offline(controller.syncedAt),
              ),
              const SizedBox(height: AppSpace.s16),
            ],
            RuledList(
              children: [
                for (final n in controller.items)
                  NotificationRow(
                    key: ValueKey(n.id),
                    notification: n,
                    onTap: () => onOpen(n),
                  ),
              ],
            ),
            if (controller.loadMoreFailed) ...[
              const SizedBox(height: AppSpace.s16),
              InlineNotice(
                kind: NoticeKind.erro,
                message: NotificationsCopy.moreFailed,
                actionLabel: NotificationsCopy.retry,
                onAction: controller.loadMore,
              ),
            ],
            if (controller.hasMore && !controller.loadMoreFailed) ...[
              const SizedBox(height: AppSpace.s16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SecondaryButton(
                  label: NotificationsCopy.showMore(controller.pageSize),
                  loading: controller.loadingMore,
                  loadingLabel: NotificationsCopy.loadingMore,
                  onPressed: controller.loadMore,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Linha de uma notificação: a linha inteira é uma ligação. A marca de não
/// lida e o peso nunca são o único sinal: "Por ler" está escrito.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    final dur = AppMotion.resolve(context, AppMotion.base);
    final when = AppDates.dateTime(n.createdAt);

    return RuledRow(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticsLabel: NotificationsCopy.rowSpoken(
        title: n.title,
        body: n.body,
        unread: unread,
        date: n.createdAt,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.linhaTabela),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: AppSize.marcaNaoLida,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: AnimatedOpacity(
                      opacity: unread ? 1 : 0,
                      duration: dur,
                      curve: AppMotion.sair,
                      child: const SizedBox(
                        key: ValueKey('marca-nao-lida'),
                        width: AppSize.marcaNaoLida,
                        height: AppSize.marcaNaoLida,
                        child: ColoredBox(color: AppColors.tinta),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: dur,
                        curve: AppMotion.mudar,
                        style: unread
                            ? AppType.corpoForte
                            : AppType.corpo.copyWith(
                                color: AppColors.tintaMedia,
                              ),
                        child: Text(n.title),
                      ),
                      if (n.body != null) ...[
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          n.body!,
                          style: AppType.corpoPequeno.copyWith(
                            color: AppColors.tintaMedia,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        unread
                            ? '${NotificationsCopy.unreadMark} · $when'
                            : when,
                        style: AppType.registo.copyWith(
                          color: AppColors.tintaMedia,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                const Icon(
                  Icons.chevron_right,
                  size: AppSize.iconePequeno,
                  color: AppColors.tintaMedia,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
