import 'dart:async';

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
      final user = _auth.currentSession?.user;
      if (user == null) return null;
      return await _loadSession(user.id);
    } on Object catch (e) {
      throw _map(e);
    }
  }

  Future<AppSession?> _loadSession(String userId) async {
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = AppRole.parse(row?['role']);
    if (role == null) {
      // Sem perfil não há papel: não deixar uma sessão sem rota.
      await _auth.signOut();
      return null;
    }
    return AppSession(userId: userId, role: role);
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
      final user = res.user;
      if (user == null) {
        throw const AuthFailure(AuthFailureKind.invalidCredentials);
      }
      final session = await _loadSession(user.id);
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
      await _client.functions.invoke(
        'resend-request',
        body: {'email': email},
      );
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on Object catch (e) {
      throw _map(e);
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

  AuthFailure _map(Object e, {bool signIn = false}) {
    if (e is AuthRetryableFetchError) {
      return const AuthFailure(AuthFailureKind.network);
    }
    if (e is AuthApiException) {
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
