import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/request_models.dart';
import '../domain/requests_repository.dart';
import 'requests_load.dart';

/// "Os meus pedidos" do cliente (US 4.2 e 4.3): paginada em 25, por grupos
/// "Em curso" e "Com o acesso retirado". Só leitura.
class MyRequestsController extends ChangeNotifier {
  MyRequestsController(this._repo, this._connectivity, {this.pageSize = 25});

  final RequestsRepository _repo;
  final AppConnectivity _connectivity;
  final int pageSize;

  RequestsLoad _load = RequestsLoad.loading;
  List<MyRequest> _items = const [];
  int? _total;
  int? _open;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _disposed = false;

  RequestsLoad get load => _load;

  /// Todos os carregados, mais recentes primeiro.
  List<MyRequest> get items => _items;

  /// Grupo "Em curso" (acesso não retirado).
  List<MyRequest> get active => [
    for (final r in _items)
      if (!r.accessWithdrawn) r,
  ];

  /// Grupo "Com o acesso retirado".
  List<MyRequest> get withdrawn => [
    for (final r in _items)
      if (r.accessWithdrawn) r,
  ];

  /// "Tem {n} pedidos em curso." (em curso e com acesso).
  int get openCount =>
      _open ?? _items.where((r) => r.stage.isOpen && !r.accessWithdrawn).length;

  int get totalCount => _total ?? _items.length;

  /// "Ainda não tem pedidos."
  bool get isEmpty => _load == RequestsLoad.ready && _items.isEmpty;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;

  /// Primeira carga (ou "Tentar de novo"). Ao voltar a carregar com
  /// pedidos no ecrã, falhar não os apaga.
  Future<void> start() async {
    final hadItems = _items.isNotEmpty;
    if (!hadItems) {
      _load = RequestsLoad.loading;
      _emit();
    }
    try {
      final page = await _repo.myRequests(limit: pageSize + 1, offset: 0);
      _connectivity.reportReachable();
      _hasMore = page.items.length > pageSize;
      _items = _hasMore ? page.items.sublist(0, pageSize) : page.items;
      _total = page.totalCount;
      _open = page.openCount;
      _loadMoreFailed = false;
      _load = RequestsLoad.ready;
    } on RequestFailure catch (f) {
      _report(f);
      if (!hadItems) _load = RequestsLoad.error;
    }
    _emit();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _loadMoreFailed = false;
    _emit();
    try {
      final page = await _repo.myRequests(
        limit: pageSize + 1,
        offset: _items.length,
      );
      _connectivity.reportReachable();
      final more = page.items.length > pageSize;
      final known = {for (final r in _items) r.id};
      _items = [
        ..._items,
        for (final r in (more ? page.items.sublist(0, pageSize) : page.items))
          if (!known.contains(r.id)) r,
      ];
      _hasMore = more;
      _total = page.totalCount ?? _total;
      _open = page.openCount ?? _open;
    } on RequestFailure catch (f) {
      _report(f);
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    _emit();
  }

  void _report(RequestFailure f) {
    if (f.kind == RequestFailureKind.network) {
      _connectivity.reportNetworkFailure();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
