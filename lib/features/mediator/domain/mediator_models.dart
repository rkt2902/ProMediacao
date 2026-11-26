/// Estado de um cliente na lista do mediador. O retirado nunca chega (a
/// função da base de dados filtra-o) e nunca aparece.
enum ClientStatus {
  ativo,
  pendente,
  recusado;

  static ClientStatus? parse(Object? value) => switch (value) {
    'ativa' || 'ativo' => ativo,
    'pendente' => pendente,
    'recusada' || 'recusado' => recusado,
    _ => null,
  };
}

/// Uma linha da lista: só nome, email e estado (o que o mediador pode ver
/// de pendentes e recusados). [updatedAt] é a data de criação do pedido, do
/// último reenvio, da aceitação ou da recusa, conforme o estado.
class OfficeClient {
  const OfficeClient({
    required this.grantId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.updatedAt,
  });

  final String grantId;
  final String fullName;
  final String email;
  final ClientStatus status;
  final DateTime updatedAt;
}

enum MediatorFailureKind {
  /// Sem ligação ou servidor inalcançável.
  network,

  /// Limite de 60 s por destinatário (`too_soon`).
  tooSoon,

  /// O email já é cliente deste escritório (pendente ou ativo).
  alreadyClient,

  /// O cliente já recusou este escritório (final).
  declined,

  /// O pedido já não está pendente.
  notPending,

  /// Nome ou email recusados pelo servidor.
  invalidInput,

  /// O cliente/pedido foi criado mas o email não seguiu.
  sendFailed,

  /// Sem permissão ou pedido inexistente.
  forbidden,

  /// Qualquer outra falha. Nunca mostrar texto técnico.
  unknown,
}

/// Falha já classificada: a UI só vê o tipo.
class MediatorFailure implements Exception {
  const MediatorFailure(this.kind, {this.retryAfterSeconds});

  final MediatorFailureKind kind;
  final int? retryAfterSeconds;

  @override
  String toString() => 'MediatorFailure($kind)';
}
