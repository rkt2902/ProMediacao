import 'auth_models.dart';

/// Contrato de autenticação. A app só fala com esta interface, para os
/// testes usarem um fake. Todas as falhas chegam como [AuthFailure].
abstract interface class AuthRepository {
  Stream<AuthSignal> get signals;

  /// Sessão guardada neste dispositivo (com o papel), ou `null`.
  /// Lança [AuthFailure] se não conseguir confirmar (rede, servidor).
  Future<AppSession?> restoreSession();

  /// Lança [AuthFailure] com `invalidCredentials` se falhar.
  Future<AppSession> signInWithPassword({
    required String email,
    required String password,
  });

  /// Pede o email de recuperação. Termina sem erro exista ou não a conta.
  Future<void> sendPasswordReset(String email);

  /// Cliente pede link de entrada (`resend-request` com `{email}`).
  /// Termina sem erro exista ou não a conta.
  Future<void> requestClientLink(String email);

  /// Define a palavra-passe do utilizador com sessão (recuperação/convite).
  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  /// `true` se o servidor responde (qualquer resposta conta). Usado para
  /// perceber quando a ligação voltou.
  Future<bool> isReachable();
}
