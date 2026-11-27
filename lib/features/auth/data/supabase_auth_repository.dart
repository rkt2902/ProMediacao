import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Implementação sobre o Supabase. Traduz todas as exceções para
/// [AuthFailure]; nada técnico sobe para a UI.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, {this.passwordRedirectUrl});

  final SupabaseClient _client;
  final String? passwordRedirectUrl;

  GoTrueClient get _auth => _client.auth;

  StreamController<AuthSignal>? _controller;
  StreamSubscription<AuthState>? _sub;

  @override
  Stream<AuthSignal> get signals {
    _controller ??= StreamController<AuthSignal>.broadcast(
      onListen: () {
        _sub = _auth.onAuthStateChange.listen(
          (state) {
            if (state.event == AuthChangeEvent.passwordRecovery) {
              _controller?.add(AuthSignal.passwordRecovery);
            } else if (state.event != AuthChangeEvent.initialSession) {
              _controller?.add(AuthSignal.sessionChanged);
            }
          },
          // Links de entrada inválidos ou expirados chegam como erro.
          onError: (Object _) => _controller?.add(AuthSignal.linkFailed),
        );
      },
      onCancel: () => _sub?.cancel(),
    );
    return _controller!.stream;
  }

  @override
  Future<AppSession?> restoreSession() async {
    try {
      final session = _auth.currentSession;
      if (session == null) return null;
      return await _loadSession(session);
    } on Object catch (e) {
      throw _map(e);
    }
  }

  Future<AppSession?> _loadSession(Session session) async {
    final user = session.user;
    final row = await _client
        .from('profiles')
        .select('role, full_name, created_at')
        .eq('id', user.id)
        .maybeSingle();
    final role = AppRole.parse(row?['role']);
    if (role == null) {
      // Sem perfil não há papel: não deixar uma sessão sem rota.
      await _auth.signOut();
      return null;
    }
    final (method, signedInAt) = _amr(session.accessToken);

    String? officeName;
    DateTime? joinedAt;
    if (role == AppRole.mediador) {
      // Só para o colofão: uma falha aqui não impede a entrada.
      try {
        final m = await _client
            .from('office_members')
            .select('created_at, offices(name)')
            .eq('user_id', user.id)
            .maybeSingle();
        joinedAt = _date(m?['created_at']);
        final office = m?['offices'];
        if (office is Map) officeName = office['name'] as String?;
      } on Object {
        // sem colofão completo, mas com sessão
      }
    }

    return AppSession(
      userId: user.id,
      role: role,
      email: user.email ?? '',
      fullName: row?['full_name'] as String?,
      createdAt: _date(row?['created_at']),
      method: method,
      signedInAt: signedInAt,
      passwordSetAt: _date(user.userMetadata?[passwordSetAtKey]),
      officeName: officeName,
      officeJoinedAt: joinedAt,
    );
  }

  /// Chave dos metadados do Auth onde a app regista a criação da
  /// palavra-passe (o Auth não diz se um utilizador tem uma).
  static const passwordSetAtKey = 'password_set_at';

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  /// Método e hora da entrada mais recente, a partir do claim `amr` do JWT.
  static (SignInMethod, DateTime?) _amr(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return (SignInMethod.unknown, null);
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final amr = payload['amr'];
      if (amr is! List || amr.isEmpty) return (SignInMethod.unknown, null);
      Map? latest;
      for (final e in amr) {
        if (e is! Map) continue;
        final t = e['timestamp'];
        if (latest == null || (t is num && t > (latest['timestamp'] as num))) {
          latest = e;
        }
      }
      if (latest == null) return (SignInMethod.unknown, null);
      final t = latest['timestamp'];
      return (
        SignInMethod.parse(latest['method']),
        t is num
            ? DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000, isUtc: true)
            : null,
      );
    } on Object {
      return (SignInMethod.unknown, null);
    }
  }

  @override
  Future<AppSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final current = res.session;
      if (current == null) {
        throw const AuthFailure(AuthFailureKind.invalidCredentials);
      }
      final session = await _loadSession(current);
      if (session == null) {
        throw const AuthFailure(AuthFailureKind.invalidCredentials);
      }
      return session;
    } on AuthFailure {
      rethrow;
    } on Object catch (e) {
      throw _map(e, signIn: true);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: passwordRedirectUrl);
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> requestClientLink(String email) async {
    try {
      await _client.functions.invoke('resend-request', body: {'email': email});
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<AppSession?> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(
        UserAttributes(
          password: newPassword,
          data: {passwordSetAtKey: DateTime.now().toUtc().toIso8601String()},
        ),
      );
      final session = _auth.currentSession;
      return session == null ? null : await _loadSession(session);
    } on Object catch (e) {
      throw _map(e, password: true);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<bool> isReachable() async {
    try {
      await _client.from('consent_texts').select('version').limit(1);
      return true;
    } on PostgrestException {
      return true; // o servidor respondeu
    } on Object {
      return false;
    }
  }

  AuthFailure _map(Object e, {bool signIn = false, bool password = false}) {
    if (e is AuthRetryableFetchException) {
      return const AuthFailure(AuthFailureKind.network);
    }
    if (password && e is AuthWeakPasswordException) {
      return const AuthFailure(AuthFailureKind.weakPassword);
    }
    if (e is AuthApiException) {
      if (password && e.code == 'weak_password') {
        return const AuthFailure(AuthFailureKind.weakPassword);
      }
      final status = int.tryParse(e.statusCode ?? '');
      if (status == 429) return const AuthFailure(AuthFailureKind.tooSoon);
      if (signIn && status != null && status >= 400 && status < 500) {
        return const AuthFailure(AuthFailureKind.invalidCredentials);
      }
      return const AuthFailure(AuthFailureKind.unknown);
    }
    if (e is FunctionException) {
      final details = e.details;
      final code = details is Map && details['error'] is Map
          ? (details['error'] as Map)['code']
          : null;
      if (e.status == 429 || code == 'too_soon') {
        final retry = details is Map && details['error'] is Map
            ? (details['error'] as Map)['retry_after_seconds']
            : null;
        return AuthFailure(
          AuthFailureKind.tooSoon,
          retryAfterSeconds: retry is num ? retry.toInt() : null,
        );
      }
      if (e.status == 400 || code == 'invalid_input') {
        return const AuthFailure(AuthFailureKind.invalidInput);
      }
      return const AuthFailure(AuthFailureKind.unknown);
    }
    if (e is AuthException || e is PostgrestException) {
      return const AuthFailure(AuthFailureKind.unknown);
    }
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const AuthFailure(AuthFailureKind.network);
  }
}
