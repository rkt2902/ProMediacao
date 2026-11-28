import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/request_models.dart';
import '../domain/requests_repository.dart';

enum RequestDetailLoad {
  loading,
  ready,

  /// "Pedido não encontrado" (cliente) / "Sem acesso" (mediador): não existe,
  /// não é seu, ou o escritório perdeu o acesso (nunca se distingue).
  notFound,
  error,
}

/// Pedido aberto, só leitura: ecrã 3b do mediador e ecrã 5 do cliente.
class RequestDetailController extends ChangeNotifier {
  RequestDetailController(
    this._repo,
    this._connectivity, {
    required this.requestId,
  });

  final RequestsRepository _repo;
  final AppConnectivity _connectivity;
  final String requestId;

  RequestDetailLoad _load = RequestDetailLoad.loading;
  RequestDetail? _detail;
  bool _disposed = false;

  RequestDetailLoad get load => _load;
  RequestDetail? get detail => _detail;

  /// Também é o "Tentar de novo".
  Future<void> start() async {
    _load = RequestDetailLoad.loading;
    _emit();
    try {
      _detail = await _repo.request(requestId);
      _connectivity.reportReachable();
      _load = _detail == null
          ? RequestDetailLoad.notFound
          : RequestDetailLoad.ready;
    } on RequestFailure catch (f) {
      if (f.kind == RequestFailureKind.network) {
        _connectivity.reportNetworkFailure();
      }
      _load = f.kind == RequestFailureKind.notFound
          ? RequestDetailLoad.notFound
          : RequestDetailLoad.error;
    }
    _emit();
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
