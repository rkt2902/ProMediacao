import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

enum ClientLinkStatus { idle, sending, sent, failed }

/// Pedido de link de acesso do cliente (entrada e link expirado partilham-no:
/// mesmo comportamento e confirmação). Bloqueia 60 s após cada envio.
class ClientLinkController extends ChangeNotifier {
  ClientLinkController(
    this._repo,
    this._connectivity, {
    this.cooldownSeconds = 60,
  });

  final AuthRepository _repo;
  final AppConnectivity _connectivity;
  final int cooldownSeconds;

  ClientLinkStatus _status = ClientLinkStatus.idle;
  AuthFailureKind? _failure;
  String _email = '';
  int _remaining = 0;
  Timer? _timer;

  ClientLinkStatus get status => _status;
  AuthFailureKind? get failure => _failure;

  /// Último email a que se enviou.
  String get email => _email;

  /// Segundos até poder voltar a enviar para [email].
  int get remaining => _remaining;

  bool canSend(String email) =>
      _status != ClientLinkStatus.sending &&
      !(_remaining > 0 && email.trim() == _email);

  Future<void> send(String rawEmail) async {
    final email = rawEmail.trim();
    if (!canSend(email)) return;
    _status = ClientLinkStatus.sending;
    _failure = null;
    notifyListeners();
    try {
      await _repo.requestClientLink(email);
      _connectivity.reportReachable();
      _sent(email, cooldownSeconds);
    } on AuthFailure catch (f) {
      if (f.kind == AuthFailureKind.tooSoon) {
        // Resposta igual à de um envio normal: não revela nada.
        _sent(email, f.retryAfterSeconds ?? cooldownSeconds);
        return;
      }
      if (f.kind == AuthFailureKind.network) {
        _connectivity.reportNetworkFailure();
      }
      _status = ClientLinkStatus.failed;
      _failure = f.kind;
      notifyListeners();
    }
  }

  void _sent(String email, int seconds) {
    _email = email;
    _status = ClientLinkStatus.sent;
    _remaining = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        t.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// "Usar outro email": volta ao formulário.
  void useAnotherEmail() {
    _status = ClientLinkStatus.idle;
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
