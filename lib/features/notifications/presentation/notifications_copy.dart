import '../../../core/format/dates.dart';

/// Copy do sino e das notificações do cliente (03-design.md, ecrã 6).
abstract final class NotificationsCopy {
  static const title = 'Notificações';
  static const close = 'Fechar';
  static const backToRequests = 'Os meus pedidos';
  static const unreadMark = 'Por ler';
  static const allRead = 'Todas lidas';
  static String unreadCount(int n) => '$n por ler';

  static const emptyTitle = 'Sem notificações';
  static const emptyHelp =
      'Quando um escritório lhe enviar um pedido, o aviso aparece aqui.';
  static const loadFailed =
      'Não foi possível carregar as notificações. Tente de novo.';
  static const retry = 'Tentar de novo';

  /// Sem ligação: último estado conhecido (a hora vem do servidor).
  static String offline(DateTime? at) => at == null
      ? 'Sem ligação. Está a ver as últimas notificações carregadas. Abrir '
            'uma notificação só a marca como lida quando a ligação voltar.'
      : 'Sem ligação. Está a ver as notificações de ${AppDates.dateTime(at)}. '
            'Abrir uma notificação só a marca como lida quando a ligação '
            'voltar.';

  /// Com ligação, mas a atualização falhou.
  static String staleOnline(DateTime? at) => at == null
      ? 'Não foi possível atualizar as notificações. Está a ver as últimas '
            'carregadas.'
      : 'Não foi possível atualizar as notificações. Está a ver as de '
            '${AppDates.dateTime(at)}.';

  static String showMore(int n) => 'Mostrar mais $n';
  static const loadingMore = 'A carregar…';
  static const moreFailed =
      'Não foi possível mostrar mais notificações. Tente de novo.';

  static String rowSpoken({
    required String title,
    String? body,
    required bool unread,
    required DateTime date,
  }) =>
      '$title${body == null ? '' : ', $body'}, '
      '${unread ? 'por ler, ' : ''}${AppDates.dateTime(date)}';
}
