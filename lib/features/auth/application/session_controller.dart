import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/password_prompt_store.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

enum SessionStatus { restoring, signedOut, signedIn, failed }

/// Id do pedido de consentimento pendente mais recente do cliente com sessão,
/// ou `null`. Uma falha conta como "sem pedido" (nunca impede a entrada).
typedef PendingRequestLookup = Future<String?> Function();

/// Estado de sessão da app. O router escuta-o (refreshListenable).
class SessionController extends ChangeNotifier {
  SessionController(
    this._repo, {
    PasswordPromptStore? prompts,
    PendingRequestLookup? pendingRequest,
  }) : _prompts = prompts ?? MemoryPasswordPromptStore(),
       _pendingLookup = pendingRequest;

  final AuthRepository _repo;
  final PasswordPromptStore _prompts;
  final PendingRequestLookup? _pendingLookup;
  String? _pendingRequestId;
  String? _pendingCheckedFor;
  StreamSubscription<AuthSignal>? _sub;
  bool _explicitSignOut = false;

  SessionStatus _status = SessionStatus.restoring;
  AppSession? _session;
  bool _sessionEnded = false;
  bool _recovering = false;
  bool _linkFailed = false;
  bool _promptDismissed = false;
  String _lastEmail = '';
  String? _notice;

  SessionStatus get status => _status;
  AppSession? get session => _session;
  AppRole? get role => _session?.role;

  /// A sessão terminou sem o utilizador sair (mostra "A sua sessão terminou").
  bool get sessionEnded => _sessionEnded;

  /// Abriu um link de recuperação: tem de definir a palavra-passe.
  bool get recovering => _recovering;

  /// Mediador ou admin que entrou pelo link de convite e ainda não definiu a
  /// palavra-passe.
  bool get needsPasswordSetup {
    final s = _session;
    return s != null &&
        s.role != AppRole.cliente &&
        s.method == SignInMethod.invite &&
        !s.hasPassword;
  }

  /// Cliente que entrou por link, sem palavra-passe, e que ainda não disse
  /// "Agora não" nesta entrada: mostra o convite "Criar palavra-passe".
  bool get offerPassword {
    final s = _session;
    return s != null &&
        s.role == AppRole.cliente &&
        s.method == SignInMethod.link &&
        !s.hasPassword &&
        !_promptDismissed;
  }

  /// A app abriu um link inválido ou expirado (sem sessão: o router mostra
  /// "Este link já não é válido").
  bool get linkFailed => _linkFailed;

  /// Marca, antes de arrancar, que o URL de entrada trazia um erro de link
  /// (o Supabase limpa o fragmento antes de o router o ver).
  void markLinkFailed() {
    _linkFailed = true;
    notifyListeners();
  }

  /// Pedido pendente a abrir primeiro depois de uma entrada por link, antes
  /// do convite "Criar palavra-passe" (03-design, ecrã 1c). Só existe
  /// enquanto o convite estiver por mostrar nesta entrada.
  String? get pendingRequestId => offerPassword ? _pendingRequestId : null;

  /// O router abriu o pedido: a paragem seguinte já é o convite.
  void consumePendingRequest() => _pendingRequestId = null;

  /// Email para preencher Entrar (depois de sair, de a sessão terminar, ou
  /// de "Já tem palavra-passe? Entrar com ela"). Fica só em memória.
  String get lastEmail => _lastEmail;
  set lastEmail(String v) => _lastEmail = v.trim();

  /// Aviso para o ecrã seguinte mostrar uma vez (ex.: "Palavra-passe
  /// criada…"). O ecrã lê-o com [takeNotice].
  void setNotice(String message) => _notice = message;

  String? takeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

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

  /// Volta a ler a sessão (ex.: depois de mudar a palavra-passe).
  Future<void> refresh() => _restore();

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
      await _apply(await _repo.restoreSession());
    } on AuthFailure {
      if (_status != SessionStatus.signedIn) {
        _status = SessionStatus.failed;
        notifyListeners();
      }
    }
  }

  static String _promptKey(AppSession s) =>
      '${s.userId}:${s.signedInAt?.millisecondsSinceEpoch ?? 0}';

  /// Mediador e admin só entram com palavra-passe (US 1). Uma sessão aberta
  /// por link mágico com esses papéis termina já, sem dizer porquê (a
  /// mensagem é a de sessão terminada, igual para todos).
  static bool _forbiddenLink(AppSession s) =>
      s.role != AppRole.cliente && s.method == SignInMethod.link;

  Future<void> _apply(AppSession? s) async {
    final before = _status;
    final previous = _session;
    if (s != null && _forbiddenLink(s)) {
      try {
        await _repo.signOut();
      } on AuthFailure {
        // A sessão local termina na mesma.
      }
      _session = null;
      _sessionEnded = true;
      _recovering = false;
      _pendingRequestId = null;
      _status = SessionStatus.signedOut;
      _explicitSignOut = false;
      notifyListeners();
      return;
    }
    if (s != null &&
        s.role == AppRole.cliente &&
        s.method == SignInMethod.link) {
      _promptDismissed = await _prompts.isDismissed(_promptKey(s));
    } else {
      _promptDismissed = false;
    }
    await _lookUpPendingRequest(s);
    _session = s;
    if (s == null) {
      if (previous != null) _lastEmail = previous.email;
      if (before == SessionStatus.signedIn && !_explicitSignOut) {
        _sessionEnded = true;
      }
      _recovering = false;
      _status = SessionStatus.signedOut;
    } else {
      _sessionEnded = false;
      // Com sessão válida, um erro de link antigo já não interessa.
      _linkFailed = false;
      _status = SessionStatus.signedIn;
    }
    _explicitSignOut = false;
    notifyListeners();
  }

  /// Uma vez por entrada por link (cliente sem palavra-passe e com o convite
  /// por mostrar): procura o pedido pendente que deve abrir primeiro.
  Future<void> _lookUpPendingRequest(AppSession? s) async {
    final lookup = _pendingLookup;
    if (s == null) {
      _pendingRequestId = null;
      _pendingCheckedFor = null;
      return;
    }
    final offers =
        s.role == AppRole.cliente &&
        s.method == SignInMethod.link &&
        !s.hasPassword &&
        !_promptDismissed;
    final key = _promptKey(s);
    if (lookup == null || !offers || _pendingCheckedFor == key) return;
    _pendingCheckedFor = key;
    try {
      _pendingRequestId = await lookup();
    } on Object {
      _pendingRequestId = null;
    }
  }

  /// Lança [AuthFailure] se falhar.
  Future<void> signIn(String email, String password) async {
    _lastEmail = email.trim();
    final s = await _repo.signInWithPassword(email: email, password: password);
    await _apply(s);
  }

  Future<void> signOut() async {
    _explicitSignOut = true;
    try {
      await _repo.signOut();
    } on AuthFailure {
      // Mesmo sem rede, esta sessão local termina.
    }
    await _apply(null);
  }

  /// "Agora não": o convite só volta na entrada seguinte por link.
  Future<void> dismissPasswordPrompt() async {
    final s = _session;
    _promptDismissed = true;
    notifyListeners();
    if (s != null) await _prompts.dismiss(_promptKey(s));
  }

  /// Palavra-passe guardada (lança [AuthFailure] se falhar). A sessão passa a
  /// saber que já tem palavra-passe; acaba a recuperação, se houver.
  ///
  /// [notice] fica pronto para o ecrã seguinte antes de a sessão mudar (o
  /// router pode trocar de ecrã logo a seguir).
  Future<void> updatePassword(String password, {String? notice}) async {
    final s = await _repo.updatePassword(password);
    if (notice != null) _notice = notice;
    _recovering = false;
    if (s != null) {
      await _apply(s);
    } else {
      notifyListeners();
    }
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
