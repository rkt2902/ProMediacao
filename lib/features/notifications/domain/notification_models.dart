/// Notificações na app (US 7). Genéricas: [kind] e o objeto ligado
/// ([objectType] + [objectId]) dizem o que abrir. Na 002 só há
/// `pedido_criado` ligado a um `request`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.objectType,
    this.objectId,
    this.readAt,
  });

  static const kindRequestCreated = 'pedido_criado';
  static const objectRequest = 'request';

  final String id;
  final String kind;

  /// Texto curto ("Novo pedido: {tipo}").
  final String title;

  /// Linha de apoio (na 002, o nome do escritório).
  final String? body;
  final String? objectType;
  final String? objectId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Pedido a abrir (`get_request`), se a notificação for de um pedido.
  String? get requestId => objectType == objectRequest ? objectId : null;

  AppNotification withRead({required bool isRead, DateTime? readAt}) =>
      AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        objectType: objectType,
        objectId: objectId,
        isRead: isRead,
        readAt: readAt,
        createdAt: createdAt,
      );

  /// Linha de `list_my_notifications`. Lança [FormatException] se faltar
  /// algo essencial.
  factory AppNotification.fromRow(Map<String, dynamic> row) {
    final id = row['notification_id'] ?? row['id'];
    final kind = row['kind'];
    final title = row['title'];
    final created = _date(row['created_at']);
    if (id is! String ||
        kind is! String ||
        title is! String ||
        created == null) {
      throw const FormatException('Notificação inválida');
    }
    final body = row['body'];
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body is String && body.trim().isNotEmpty ? body : null,
      objectType: row['object_type'] as String?,
      objectId: row['object_id'] as String?,
      isRead: row['is_read'] == true,
      readAt: _date(row['read_at']),
      createdAt: created,
    );
  }
}

/// Uma página de notificações com os totais do servidor (todas as páginas).
/// Os totais são nulos quando a página vem vazia depois da primeira.
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    this.totalCount,
    this.unreadCount,
  });

  final List<AppNotification> items;
  final int? totalCount;
  final int? unreadCount;
}

/// Estado lida/não lida confirmado pelo servidor (`set_notification_read`).
class NotificationReadState {
  const NotificationReadState({
    required this.id,
    required this.isRead,
    this.readAt,
  });

  final String id;
  final bool isRead;
  final DateTime? readAt;
}

enum NotificationFailureKind {
  /// Sem ligação ou servidor inalcançável.
  network,

  /// Não existe ou não é sua (nunca se distingue).
  notFound,

  /// Qualquer outra falha. Nunca mostrar texto técnico.
  unknown,
}

class NotificationFailure implements Exception {
  const NotificationFailure(this.kind);

  final NotificationFailureKind kind;

  @override
  String toString() => 'NotificationFailure($kind)';
}

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');
