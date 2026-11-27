import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/notification_models.dart';
import '../domain/notifications_repository.dart';

enum NotificationsLoad { idle, loading, ready, error }

/// Sino e lista de notificações do cliente (US 7.3 a 7.7). Um só por sessão
/// (vive em `AppServices.notifications`), para o contador ser o mesmo em
/// todos os ecrãs e sobreviver à navegação.
///
/// - Offline ou erro: mantém o último estado conhecido ([unread], [items])
///   e liga [stale], com a hora em [syncedAt] ("Está a ver as notificações
///   de {data, hora}").
/// - "Lida" só depois da confirmação do servidor (sem update otimista). Uma
///   notificação aberta sem ligação fica por marcar e é marcada quando a
///   ligação voltar.
class NotificationsController extends ChangeNotifier {
  NotificationsController(
    this._repo,
    this._connectivity, {
    this.pageSize = 25,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _wasOnline = _connectivity.online;
    _connectivity.addListener(_onConnectivity);
  }

  final NotificationsRepository _repo;
  final AppConnectivity _connectivity;
  final int pageSize;
  final DateTime Function() _now;

  /// Muda em [reset]: respostas de antes (outra sessão) são ignoradas.
  int _epoch = 0;
  late bool _wasOnline;
  bool _disposed = false;

  int _unread = 0;
  bool _countKnown = false;
  DateTime? _syncedAt;
  bool _stale = false;

  NotificationsLoad _load = NotificationsLoad.idle;
  List<AppNotification> _items = const [];
  int? _total;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  final Set<String> _marking = {};
  final Set<String> _pendingReads = {};

  /// Contador do sino (último conhecido). `null` antes da primeira resposta.
  int? get unread => _countKnown ? _unread : null;

  /// Última resposta do servidor (lista ou contador).
  DateTime? get syncedAt => _syncedAt;

  /// A última atualização falhou: o ecrã mostra o último estado com aviso.
  bool get stale => _stale;

  NotificationsLoad get load => _load;
  List<AppNotification> get items => _items;
  int get totalCount => _total ?? _items.length;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;

  /// "Sem notificações".
  bool get isEmpty => _load == NotificationsLoad.ready && _items.isEmpty;

  /// A pedir ao servidor para marcar como lida.
  bool isMarking(String id) => _marking.contains(id);

  /// Aberta sem ligação: fica marcada quando a ligação voltar.
  bool isPendingRead(String id) => _pendingReads.contains(id);

  /// Atualiza o contador do sino. Falhar mantém o último valor.
  Future<void> refreshCount() async {
    final epoch = _epoch;
    try {
      final n = await _repo.unreadCount();
      if (epoch != _epoch) return;
      _connectivity.reportReachable();
      _setCount(n);
      _stale = false;
    } on NotificationFailure catch (f) {
      if (epoch != _epoch) return;
      _report(f);
      _stale = true;
    }
    _emit();
  }

  /// Primeira página (ao abrir o painel ou o ecrã, e "Tentar de novo").
  /// Com notificações já no ecrã, falhar não as apaga.
  Future<void> loadFirstPage() async {
    final epoch = _epoch;
    final hadItems = _load == NotificationsLoad.ready;
    if (!hadItems) {
      _load = NotificationsLoad.loading;
      _emit();
    }
    try {
      final page = await _repo.list(limit: pageSize + 1, offset: 0);
      if (epoch != _epoch) return;
      _connectivity.reportReachable();
      _hasMore = page.items.length > pageSize;
      _items = _hasMore ? page.items.sublist(0, pageSize) : page.items;
      _total = page.totalCount;
      if (page.unreadCount != null) _setCount(page.unreadCount!);
      _loadMoreFailed = false;
      _stale = false;
      _load = NotificationsLoad.ready;
    } on NotificationFailure catch (f) {
      if (epoch != _epoch) return;
      _report(f);
      _stale = true;
      if (!hadItems) _load = NotificationsLoad.error;
    }
    _emit();
  }

  /// "Mostrar mais 25".
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final epoch = _epoch;
    _loadingMore = true;
    _loadMoreFailed = false;
    _emit();
    try {
      final page = await _repo.list(limit: pageSize + 1, offset: _items.length);
      if (epoch != _epoch) return;
      _connectivity.reportReachable();
      final more = page.items.length > pageSize;
      final known = {for (final n in _items) n.id};
      _items = [
        ..._items,
        for (final n in (more ? page.items.sublist(0, pageSize) : page.items))
          if (!known.contains(n.id)) n,
      ];
      _hasMore = more;
      _total = page.totalCount ?? _total;
    } on NotificationFailure catch (f) {
      if (epoch != _epoch) return;
      _report(f);
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    _emit();
  }

  /// Abrir uma notificação: pede ao servidor para a marcar como lida (sem
  /// esperar) e devolve o pedido a abrir. Ordem na página: `open(n)` e logo
  /// `context.go(AppRoutes.clientRequest(id))`; este controlador sobrevive à
  /// navegação e o contador desce quando o servidor confirmar.
  String? open(AppNotification n) {
    if (!n.isRead) markRead(n.id);
    return n.requestId;
  }

  /// Marca como lida. `true` só depois de o servidor confirmar.
  Future<bool> markRead(String id) async {
    if (_marking.contains(id)) return false;
    final epoch = _epoch;
    _marking.add(id);
    _emit();
    try {
      final state = await _repo.setRead(id);
      if (epoch != _epoch) return false;
      _connectivity.reportReachable();
      _pendingReads.remove(id);
      _marking.remove(id);
      _applyRead(state);
      _emit();
      return state.isRead;
    } on NotificationFailure catch (f) {
      if (epoch != _epoch) return false;
      _marking.remove(id);
      _report(f);
      if (f.kind == NotificationFailureKind.network) {
        _pendingReads.add(id);
      } else {
        _pendingReads.remove(id);
      }
      _emit();
      return false;
    }
  }

  /// Fim de sessão: esquece tudo (a próxima sessão pode ser de outra
  /// pessoa).
  void reset() {
    _epoch++;
    _unread = 0;
    _countKnown = false;
    _syncedAt = null;
    _stale = false;
    _load = NotificationsLoad.idle;
    _items = const [];
    _total = null;
    _hasMore = false;
    _loadingMore = false;
    _loadMoreFailed = false;
    _marking.clear();
    _pendingReads.clear();
    _emit();
  }

  void _applyRead(NotificationReadState s) {
    var found = false;
    var wasUnread = false;
    final next = <AppNotification>[];
    for (final n in _items) {
      if (n.id == s.id) {
        found = true;
        wasUnread = !n.isRead;
        next.add(n.withRead(isRead: s.isRead, readAt: s.readAt));
      } else {
        next.add(n);
      }
    }
    _items = next;
    _syncedAt = _now();
    if (!found) {
      // Fora da lista carregada: o servidor diz o contador certo.
      refreshCount();
    } else if (_countKnown && wasUnread && s.isRead) {
      _unread = _unread > 0 ? _unread - 1 : 0;
    } else if (_countKnown && !wasUnread && !s.isRead) {
      _unread++;
    }
  }

  void _setCount(int n) {
    _unread = n < 0 ? 0 : n;
    _countKnown = true;
    _syncedAt = _now();
  }

  void _report(NotificationFailure f) {
    if (f.kind == NotificationFailureKind.network) {
      _connectivity.reportNetworkFailure();
    }
  }

  void _onConnectivity() {
    final online = _connectivity.online;
    final back = online && !_wasOnline;
    _wasOnline = online;
    if (!back) return;
    _flushPendingReads();
  }

  /// Marca as abertas sem ligação e, depois, lê o contador do servidor (a
  /// ordem evita contar a mesma descida duas vezes).
  Future<void> _flushPendingReads() async {
    await Future.wait([
      for (final id in [..._pendingReads]) markRead(id),
    ]);
    if (_countKnown || _load != NotificationsLoad.idle) await refreshCount();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivity.removeListener(_onConnectivity);
    super.dispose();
  }
}
