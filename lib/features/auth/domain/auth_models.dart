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

/// Como a sessão atual foi aberta (claim `amr` do token).
enum SignInMethod {
  password,

  /// Link mágico (`otp` / `magiclink`).
  link,

  /// Link de convite (mediador).
  invite,

  /// Link de recuperação de palavra-passe.
  recovery,
  unknown;

  static SignInMethod parse(Object? value) => switch (value) {
    'password' => password,
    'otp' || 'magiclink' => link,
    'invite' => invite,
    'recovery' => recovery,
    _ => unknown,
  };
}

/// Sessão ativa: quem é e com que papel. O papel vem sempre da base de
/// dados (`profiles`), nunca dos metadados do token.
class AppSession {
  const AppSession({
    required this.userId,
    required this.role,
    this.email = '',
    this.fullName,
    this.createdAt,
    this.method = SignInMethod.unknown,
    this.signedInAt,
    this.passwordSetAt,
    this.officeName,
    this.officeJoinedAt,
  });

  final String userId;
  final AppRole role;
  final String email;

  /// `profiles.full_name` (colofão do cliente e do mediador).
  final String? fullName;

  /// `profiles.created_at` ("Aberto a …" no colofão do cliente).
  final DateTime? createdAt;

  final SignInMethod method;

  /// Quando esta sessão foi aberta (identifica a entrada por link).
  final DateTime? signedInAt;

  /// Quando a palavra-passe foi criada pela app (metadados do Auth); nulo se
  /// ainda não há registo.
  final DateTime? passwordSetAt;

  /// Mediador: escritório e data de entrada (`office_members.created_at`).
  final String? officeName;
  final DateTime? officeJoinedAt;

  /// Tem palavra-passe: entrou com ela ou a app registou que a criou.
  bool get hasPassword =>
      passwordSetAt != null || method == SignInMethod.password;
}

enum AuthFailureKind {
  /// Email ou palavra-passe incorretos (sem dizer qual).
  invalidCredentials,

  /// Sem ligação ou servidor inalcançável.
  network,

  /// Limite de 60 s por destinatário (`too_soon`).
  tooSoon,

  /// O Auth recusou a palavra-passe por fraca.
  weakPassword,

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
