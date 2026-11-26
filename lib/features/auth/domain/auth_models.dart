/// Papéis da app (iguais ao enum `app_role` da base de dados).
enum AppRole {
  admin,
  mediador,
  cliente;

  static AppRole? parse(Object? value) {
    for (final r in AppRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }
}

/// Sessão ativa: quem é e com que papel. O papel vem sempre da base de
/// dados (`profiles`), nunca dos metadados do token.
class AppSession {
  const AppSession({required this.userId, required this.role});

  final String userId;
  final AppRole role;
}

enum AuthFailureKind {
  /// Email ou palavra-passe incorretos (sem dizer qual).
  invalidCredentials,

  /// Sem ligação ou servidor inalcançável.
  network,

  /// Limite de 60 s por destinatário (`too_soon`).
  tooSoon,

  /// Pedido recusado por dados inválidos.
  invalidInput,

  /// Qualquer outra falha. Nunca mostrar texto técnico.
  unknown,
}

/// Falha de autenticação já classificada: a UI só vê o tipo.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, {this.retryAfterSeconds});

  final AuthFailureKind kind;
  final int? retryAfterSeconds;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Eventos do repositório que não são uma sessão em si.
enum AuthSignal {
  /// A sessão mudou (entrou, saiu, renovou, expirou): voltar a ler.
  sessionChanged,

  /// O utilizador abriu um link de recuperação de palavra-passe.
  passwordRecovery,

  /// A app abriu um link de autenticação inválido ou expirado.
  linkFailed,
}
