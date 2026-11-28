import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_models.dart';
import '../domain/notifications_repository.dart';

/// Implementação sobre as RPC de notificações da migração 002.
class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<NotificationsBatch> list({int limit = 25, int offset = 0}) =>
      _guard(() async {
        final rows = _rows(
          await _client.rpc<dynamic>(
            'list_my_notifications',
            params: {'p_limit': limit, 'p_offset': offset},
          ),
        );
        if (rows.isEmpty) {
          return NotificationsBatch(
            items: const [],
            totalCount: offset == 0 ? 0 : null,
            unreadCount: offset == 0 ? 0 : null,
          );
        }
        return NotificationsBatch(
          items: [for (final r in rows) AppNotification.fromRow(r)],
          totalCount: _int(rows.first['total_count']),
          unreadCount: _int(rows.first['unread_count']),
        );
      });

  @override
  Future<int> unreadCount() => _guard(() async {
    final v = await _client.rpc<dynamic>('my_unread_notification_count');
    return _int(v) ?? 0;
  });

  @override
  Future<NotificationReadState> setRead(String id, {bool read = true}) =>
      _guard(() async {
        final rows = _rows(
          await _client.rpc<dynamic>(
            'set_notification_read',
            params: {'p_notification_id': id, 'p_read': read},
          ),
        );
        if (rows.isEmpty) {
          throw const NotificationFailure(NotificationFailureKind.notFound);
        }
        final r = rows.first;
        return NotificationReadState(
          id: '${r['notification_id'] ?? id}',
          isRead: r['is_read'] == true,
          readAt: r['read_at'] == null
              ? null
              : DateTime.tryParse('${r['read_at']}'),
        );
      });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on NotificationFailure {
      rethrow;
    } on Object catch (e) {
      throw mapError(e);
    }
  }

  /// Classificação das falhas (pública para teste).
  static NotificationFailure mapError(Object e) {
    if (e is NotificationFailure) return e;
    if (e is PostgrestException) {
      return NotificationFailure(
        e.message == 'not_found' || e.code == 'P0002'
            ? NotificationFailureKind.notFound
            : NotificationFailureKind.unknown,
      );
    }
    if (e is AuthRetryableFetchException) {
      return const NotificationFailure(NotificationFailureKind.network);
    }
    if (e is AuthException || e is FormatException || e is TypeError) {
      return const NotificationFailure(NotificationFailureKind.unknown);
    }
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const NotificationFailure(NotificationFailureKind.network);
  }
}

List<Map<String, dynamic>> _rows(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
