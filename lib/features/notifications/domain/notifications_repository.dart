import 'notification_models.dart';

/// Notificações do utilizador autenticado (só as suas; a identidade vem da
/// sessão no servidor). Todas as falhas chegam como [NotificationFailure].
abstract interface class NotificationsRepository {
  /// Por data decrescente (`list_my_notifications`).
  Future<NotificationsPage> list({int limit = 25, int offset = 0});

  /// Contador do sino (`my_unread_notification_count()`).
  Future<int> unreadCount();

  /// Lida/não lida (`set_notification_read`). Devolve o estado confirmado
  /// pelo servidor; nada é dado como lido sem esta resposta (US 7.6).
  Future<NotificationReadState> setRead(String id, {bool read = true});
}
