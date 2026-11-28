import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

enum AdminLoad { loading, ready, failed }

/// Estado do painel do admin: contagens e escritórios. Só mostra o que o
/// servidor confirmou (cria e convida primeiro no servidor).
class AdminController extends ChangeNotifier {
  AdminController(this._repo, {this.onNetworkFailure, this.onReachable});

  final AdminRepository _repo;

  /// Ligação com o estado de rede da app (offline / online).
  final VoidCallback? onNetworkFailure;
  final VoidCallback? onReachable;

  AdminLoad _state = AdminLoad.loading;
  AdminCounts? _counts;
  List<OfficeSummary> _offices = const [];
  bool _disposed = false;

  AdminLoad get state => _state;
  AdminCounts? get counts => _counts;
  List<OfficeSummary> get offices => _offices;

  /// Carrega contagens e escritórios. `quiet` não volta ao skeleton e, se
  /// falhar, mantém o que já está no ecrã.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      _state = AdminLoad.loading;
      notifyListeners();
    }
    try {
      final results = await Future.wait<Object>([
        _repo.loadCounts(),
        _repo.loadOffices(),
      ]);
      if (_disposed) return;
      _counts = results[0] as AdminCounts;
      _offices = results[1] as List<OfficeSummary>;
      _state = AdminLoad.ready;
      onReachable?.call();
    } on AdminFailure catch (f) {
      if (_disposed) return;
      if (f.kind == AdminFailureKind.network) onNetworkFailure?.call();
      if (!quiet || _state != AdminLoad.ready) _state = AdminLoad.failed;
    }
    notifyListeners();
  }

  /// Cria o escritório; lança [AdminFailure] se não conseguir.
  Future<OfficeSummary> createOffice(String name) async {
    final clean = name.trim();
    final lower = clean.toLowerCase();
    // Sem restrição única na base de dados: confere-se na lista conhecida.
    if (_offices.any((o) => o.name.trim().toLowerCase() == lower)) {
      throw const AdminFailure(AdminFailureKind.duplicateName);
    }
    try {
      final office = await _repo.createOffice(clean);
      onReachable?.call();
      if (!_disposed) {
        _offices = [office, ..._offices];
        final c = _counts;
        if (c != null) {
          _counts = AdminCounts(
            offices: c.offices + 1,
            mediators: c.mediators,
            clients: c.clients,
            requests: c.requests,
          );
        }
        notifyListeners();
        unawaited(load(quiet: true));
      }
      return office;
    } on AdminFailure catch (f) {
      if (f.kind == AdminFailureKind.network) onNetworkFailure?.call();
      rethrow;
    }
  }

  /// Convida o mediador; lança [AdminFailure] se não conseguir.
  Future<void> inviteMediator({
    required String officeId,
    required String email,
    required String fullName,
  }) async {
    try {
      await _repo.inviteMediator(
        officeId: officeId,
        email: email.trim(),
        fullName: fullName.trim(),
      );
      onReachable?.call();
      if (!_disposed) unawaited(load(quiet: true));
    } on AdminFailure catch (f) {
      if (f.kind == AdminFailureKind.network) onNetworkFailure?.call();
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
