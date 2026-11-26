import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

enum SessionStatus { restoring, signedOut, signedIn, failed }

/// Estado de sessão da app. O router escuta-o (refreshListenable).
class SessionController extends ChangeNotifier {
  SessionController(this._repo);

  final AuthRepository _repo;
  StreamSubscription<AuthSignal>? _sub;
  bool _explicitSignOut = false;

  SessionStatus _status = SessionStatus.restoring;
  AppSession? _session;
  bool _sessionEnded = false;
  AppRole? _endedRole;
  bool _recovering = false;
  bool _linkFailed = false;

  SessionStatus get status => _status;
  AppSession? get session => _session;
  AppRole? get role => _session?.role;

  /// A sessão terminou sem o utilizador sair (mostra "A sua sessão terminou").
  bool get sessionEnded => _sessionEnded;
  AppRole? get endedRole => _endedRole;

  /// Abriu um link de recuperação: tem de definir a palavra-passe.
  bool get recovering => _recovering;

  /// A app abriu um link inválido ou expirado.
  bool get linkFailed => _linkFailed;

  Future<void> start() async {
    _sub ??= _repo.signals.listen(_onSignal);
    await retry();
  }

  Future<void> retry() async {
    if (_status == SessionStatus.failed) {
      _status = SessionStatus.restoring;
      notifyListeners();
    }
    await _restore();
  }

  void _onSignal(AuthSignal s) {
    switch (s) {
      case AuthSignal.passwordRecovery:
        _recovering = true;
        _restore();
      case AuthSignal.sessionChanged:
        _restore();
      case AuthSignal.linkFailed:
        _linkFailed = true;
        notifyListeners();
    }
  }

  Future<void> _restore() async {
    try {
      _apply(await _repo.restoreSession());
    } on AuthFailure {
      if (_status != SessionStatus.signedIn) {
        _status = SessionStatus.failed;
        notifyListeners();
      }
    }
  }

  void _apply(AppSession? s) {
    final before = _status;
    final beforeRole = _session?.role;
    _session = s;
    if (s == null) {
      if (before == SessionStatus.signedIn && !_explicitSignOut) {
        _sessionEnded = true;
        _endedRole = beforeRole;
      }
      _recovering = false;
      _status = SessionStatus.signedOut;
    } else {
      _sessionEnded = false;
      _endedRole = null;
      _status = SessionStatus.signedIn;
    }
    _explicitSignOut = false;
    notifyListeners();
  }

  /// Lança [AuthFailure] se falhar.
  Future<void> signIn(String email, String password) async {
    final s = await _repo.signInWithPassword(email: email, password: password);
    _apply(s);
  }

  Future<void> signOut() async {
    _explicitSignOut = true;
    try {
      await _repo.signOut();
    } on AuthFailure {
      // Mesmo sem rede, esta sessão local termina.
    }
    _apply(null);
  }

  /// Palavra-passe definida: acaba a recuperação.
  void finishRecovery() {
    _recovering = false;
    notifyListeners();
  }

  void consumeLinkFailure() {
    _linkFailed = false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
