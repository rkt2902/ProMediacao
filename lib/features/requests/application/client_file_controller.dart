import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/request_email_sender.dart';
import '../domain/request_models.dart';
import '../domain/requests_repository.dart';
import 'batch_email_controller.dart';
import 'created_batch.dart';
import 'requests_load.dart';

/// Estado da ficha do cliente (mediador, US 3.3 a 3.5 e 4.4): cabeçalho,
/// pedidos deste escritório (paginados em 25) e, se vier do Novo pedido, o
/// resultado da criação com o email.
class ClientFileController extends ChangeNotifier {
  ClientFileController(
    this._repo,
    RequestEmailSender emailSender,
    this._connectivity,
    CreatedRequestsHandoff handoff, {
    required this.clientId,
    this.pageSize = 25,
    Duration emailCooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) {
    // Lido uma só vez, antes da primeira carga.
    _created = handoff.take(clientId);
    final b = _created;
    if (b != null) {
      if (b.emailStatus == BatchEmailStatus.sent) {
        _highlight = b.requestIds;
      }
      email = BatchEmailController(
        emailSender,
        _connectivity,
        batchId: b.batchId,
        status: b.emailStatus,
        lockUntil: b.emailLockUntil,
        recipientEmail: b.clientEmail,
        cooldown: emailCooldown,
        now: now,
      )..addListener(_emit);
    }
  }

  final RequestsRepository _repo;
  final AppConnectivity _connectivity;
  final String clientId;
  final int pageSize;

  CreatedBatch? _created;

  /// Email da criação que acabou de acontecer (nulo se não se vem do Novo
  /// pedido).
  BatchEmailController? email;

  RequestsLoad _headerLoad = RequestsLoad.loading;
  ClientHeader? _header;
  RequestsLoad _listLoad = RequestsLoad.loading;
  List<OfficeRequest> _items = const [];
  int? _total;
  int? _open;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  Set<String> _highlight = const {};
  bool _disposed = false;

  /// Pedidos acabados de criar (aviso "N pedidos criados").
  CreatedBatch? get created => _created;

  RequestsLoad get headerLoad => _headerLoad;

  /// `access != active` = ecrã "Sem acesso" (não revela a existência).
  ClientHeader? get header => _header;

  RequestsLoad get listLoad => _listLoad;
  List<OfficeRequest> get requests => _items;

  /// Total de pedidos deste escritório para o cliente (todas as páginas).
  int get totalCount => _total ?? _items.length;

  /// "{n} em curso".
  int get openCount => _open ?? _items.where((r) => r.stage.isOpen).length;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;

  /// Linhas novas com `realce` a desvanecer (só quando o email seguiu; com
  /// o aviso de email não enviado não levam realce).
  Set<String> get highlightIds => _highlight;

  /// "Sem acesso": o cliente não existe, não partilha, ou retirou.
  bool get noAccess =>
      _headerLoad == RequestsLoad.ready && !(_header?.isActive ?? false);

  /// "Novo pedido" disponível (offline bloqueia criar, não ver).
  bool get canCreate => (_header?.isActive ?? false) && _connectivity.online;

  Future<void> start() async {
    await Future.wait([_loadHeader(), _loadFirstPage()]);
  }

  /// "Tentar de novo".
  Future<void> retry() async {
    await Future.wait([
      if (_headerLoad == RequestsLoad.error) _loadHeader(),
      if (_listLoad == RequestsLoad.error) _loadFirstPage(),
    ]);
  }

  /// Esquece o realce depois da animação.
  void clearHighlight() {
    if (_highlight.isEmpty) return;
    _highlight = const {};
    _emit();
  }

  /// Fecha o aviso da criação.
  void dismissCreated() {
    if (_created == null) return;
    _created = null;
    _emit();
  }

  Future<void> _loadHeader() async {
    _headerLoad = RequestsLoad.loading;
    _emit();
    try {
      _header = await _repo.clientHeader(clientId);
      _connectivity.reportReachable();
      _headerLoad = RequestsLoad.ready;
    } on RequestFailure catch (f) {
      _report(f);
      _headerLoad = RequestsLoad.error;
    }
    _emit();
  }

  Future<void> _loadFirstPage() async {
    _listLoad = RequestsLoad.loading;
    _emit();
    try {
      final page = await _repo.clientRequests(
        clientId,
        limit: pageSize + 1,
        offset: 0,
      );
      _connectivity.reportReachable();
      _hasMore = page.items.length > pageSize;
      _items = _hasMore ? page.items.sublist(0, pageSize) : page.items;
      _total = page.totalCount;
      _open = page.openCount;
      _loadMoreFailed = false;
      _listLoad = RequestsLoad.ready;
    } on RequestFailure catch (f) {
      _report(f);
      _listLoad = RequestsLoad.error;
    }
    _emit();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _loadMoreFailed = false;
    _emit();
    try {
      final page = await _repo.clientRequests(
        clientId,
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
    email?.removeListener(_emit);
    email?.dispose();
    super.dispose();
  }
}
