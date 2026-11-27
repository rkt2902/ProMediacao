/// Estado de uma concessão (igual ao enum `grant_status` da base de dados).
///
/// Transições permitidas pelo servidor (trigger `trg_consent_grants_before_update`):
/// pendente -> ativa | recusada; ativa -> retirada. Recusada e retirada são
/// finais; voltar a aceitar depois de retirar cria um registo novo
/// (`reaccept_grant`).
enum GrantStatus {
  pendente,
  ativa,
  recusada,
  retirada;

  static GrantStatus? parse(Object? value) {
    for (final s in GrantStatus.values) {
      if (s.name == value) return s;
    }
    return null;
  }
}

/// Uma concessão do cliente autenticado, como `my_consents()` a devolve.
class ConsentGrant {
  const ConsentGrant({
    required this.id,
    required this.officeId,
    required this.officeName,
    required this.status,
    required this.consentVersion,
    required this.createdAt,
    this.mediatorName,
    this.acceptedAt,
    this.declinedAt,
    this.withdrawnAt,
  });

  final String id;
  final String officeId;
  final String officeName;

  /// Mediador que enviou o pedido (nulo se o pedido não veio de um mediador).
  final String? mediatorName;
  final GrantStatus status;

  /// Versão do texto: a do pedido enquanto pendente; a aceite depois.
  final String consentVersion;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? withdrawnAt;

  /// Data que acompanha o estado (pedido, desde, recusado, retirado).
  DateTime get statusAt => switch (status) {
    GrantStatus.pendente => createdAt,
    GrantStatus.ativa => acceptedAt ?? createdAt,
    GrantStatus.recusada => declinedAt ?? createdAt,
    GrantStatus.retirada => withdrawnAt ?? createdAt,
  };

  /// Linha de `my_consents()`. Lança [FormatException] se faltar algo
  /// essencial (nunca se mostra um estado que não se percebeu).
  factory ConsentGrant.fromRow(Map<String, dynamic> row) {
    final status = GrantStatus.parse(row['status']);
    final id = row['grant_id'] ?? row['id'];
    final created = _date(row['created_at']);
    if (status == null ||
        id is! String ||
        row['office_id'] is! String ||
        row['office_name'] is! String ||
        row['consent_version'] is! String ||
        created == null) {
      throw const FormatException('Linha de concessão inválida');
    }
    return ConsentGrant(
      id: id,
      officeId: row['office_id'] as String,
      officeName: row['office_name'] as String,
      mediatorName: row['mediator_name'] as String?,
      status: status,
      consentVersion: row['consent_version'] as String,
      createdAt: created,
      acceptedAt: _date(row['accepted_at']),
      declinedAt: _date(row['declined_at']),
      withdrawnAt: _date(row['withdrawn_at']),
    );
  }

  /// Aplica a linha devolvida pelo servidor depois de um UPDATE (estado,
  /// versão e datas); o resto (nomes) mantém-se.
  ConsentGrant withServerRow(Map<String, dynamic> row) {
    final status = GrantStatus.parse(row['status']);
    if (status == null || row['id'] != id) {
      throw const FormatException('Resposta do servidor inválida');
    }
    return ConsentGrant(
      id: id,
      officeId: officeId,
      officeName: officeName,
      mediatorName: mediatorName,
      status: status,
      consentVersion: row['consent_version'] as String? ?? consentVersion,
      createdAt: createdAt,
      acceptedAt: _date(row['accepted_at']),
      declinedAt: _date(row['declined_at']),
      withdrawnAt: _date(row['withdrawn_at']),
    );
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : (v is DateTime ? v : null);
}

/// Texto de consentimento de uma versão (`consent_texts`).
class ConsentText {
  const ConsentText({required this.version, required this.content});

  final String version;
  final String content;
}

enum ConsentFailureKind {
  /// Sem ligação: não se sabe se o pedido chegou ao servidor.
  network,

  /// O servidor recusou (RLS, permissão) ou o pedido já não está no estado
  /// esperado (já respondido, já retirado): voltar a ler o estado.
  stateChanged,

  /// O registo não existe ou não é deste cliente (sem revelar qual).
  notFound,

  /// Qualquer outra falha. Nunca mostrar texto técnico.
  unknown,
}

/// Falha já classificada: a UI só vê o tipo.
class ConsentFailure implements Exception {
  const ConsentFailure(this.kind);

  final ConsentFailureKind kind;

  @override
  String toString() => 'ConsentFailure($kind)';
}
