/// Modelos do admin. Só contagens e nomes de escritórios: nenhum destes
/// tipos tem campos para nome, email ou dados de pessoas (US 2 e matriz da
/// US 6), por isso o ecrã não os consegue mostrar.
class AdminCounts {
  const AdminCounts({
    required this.offices,
    required this.mediators,
    required this.clients,
  });

  final int offices;
  final int mediators;
  final int clients;
}

/// Escritório com o nº de mediadores (contado por `office_members`, só ids).
class OfficeSummary {
  const OfficeSummary({
    required this.id,
    required this.name,
    this.mediatorCount = 0,
  });

  final String id;
  final String name;
  final int mediatorCount;

  OfficeSummary copyWith({int? mediatorCount}) => OfficeSummary(
    id: id,
    name: name,
    mediatorCount: mediatorCount ?? this.mediatorCount,
  );
}

enum AdminFailureKind {
  /// Sem ligação ou servidor inalcançável.
  network,

  /// Já existe um escritório com este nome.
  duplicateName,

  /// Email já usado ou recusado pelo Auth (`cannot_invite`).
  cannotInvite,

  /// O convite não chegou a ser enviado (`send_failed`).
  sendFailed,

  /// Sem permissão de admin (ou dados em falta).
  forbidden,
  unknown,
}

/// Todas as falhas do repositório chegam assim; nada técnico sobe à UI.
class AdminFailure implements Exception {
  const AdminFailure(this.kind);

  final AdminFailureKind kind;

  @override
  String toString() => 'AdminFailure($kind)';
}
