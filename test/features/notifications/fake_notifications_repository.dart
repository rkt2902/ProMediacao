import 'dart:async';

import 'package:promediacao/features/notifications/domain/notification_models.dart';
import 'package:promediacao/features/notifications/domain/notifications_repository.dart';

/// Notificações em memória (mais recentes primeiro).
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository([List<AppNotification>? items])
    : items = items ?? [];

  final List<AppNotification> items;

  /// Falha em todas as chamadas enquanto não for nula.
  NotificationFailure? failure;

  /// Se não nulo, `setRead` espera por ele.
  Completer<void>? readGate;
  final List<String> readCalls = [];

  void _check() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<NotificationsBatch> list({int limit = 25, int offset = 0}) async {
    _check();
    return NotificationsBatch(
      items: items.skip(offset).take(limit).toList(),
      totalCount: items.length,
      unreadCount: items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<int> unreadCount() async {
    _check();
    return items.where((n) => !n.isRead).length;
  }

  @override
  Future<NotificationReadState> setRead(String id, {bool read = true}) async {
    readCalls.add(id);
    if (readGate != null) await readGate!.future;
    _check();
    final i = items.indexWhere((n) => n.id == id);
    if (i < 0) {
      throw const NotificationFailure(NotificationFailureKind.notFound);
    }
    final at = DateTime.utc(2026, 11, 27, 11);
    items[i] = items[i].withRead(isRead: read, readAt: read ? at : null);
    return NotificationReadState(id: id, isRead: read, readAt: items[i].readAt);
  }
}

AppNotification notification(String id, {bool read = false}) => AppNotification(
  id: id,
  kind: AppNotification.kindRequestCreated,
  title: 'Novo pedido: Automóvel',
  body: 'Ribeira Seguros',
  objectType: AppNotification.objectRequest,
  objectId: 'r-$id',
  isRead: read,
  createdAt: DateTime.utc(2026, 11, 27, 10, 14),
);
