/// Modelos dos pedidos (feature 002). Espelham o contrato das RPC no topo de
/// `supabase/migrations/20261127120000_002_requests.sql`. Os `fromRow` lançam
/// [FormatException] quando falta algo essencial: nunca se mostra um pedido
/// que não se percebeu.
library;

/// Natureza de um item da lista: 'D' = Documento, 'I' = Dado a preencher.
enum ItemKind {
  document('D'),
  data('I');

  const ItemKind(this.code);

  /// Código do servidor (`kind`).
  final String code;

  static ItemKind? parse(Object? value) => switch (value) {
    'D' => document,
    'I' => data,
    _ => null,
  };
}

/// Etapas do pedido (1 a 4). "Em curso" = 1 a 3.
enum RequestStage {
  created(1),
  documentsSent(2),
  inReview(3),
  sentToInsurers(4);

  const RequestStage(this.number);

  final int number;

  bool get isOpen => number <= 3;

  static RequestStage? parse(Object? value) {
    final n = value is num ? value.toInt() : int.tryParse('$value');
    for (final s in values) {
      if (s.number == n) return s;
    }
    return null;
  }
}

/// Origem do pedido: `mediador` (002) ou `cliente` (preparado, 005).
enum RequestOrigin {
  mediador,
  cliente;

  static RequestOrigin? parse(Object? value) {
    for (final o in values) {
      if (o.name == value) return o;
    }
    return null;
  }
}

/// De onde veio um item guardado no pedido.
enum ItemSource {
  catalog,
  free;

  static ItemSource parse(Object? value) => value == 'livre' ? free : catalog;
}

// ---------------------------------------------------------------------------
// Catálogo
// ---------------------------------------------------------------------------

/// Item do catálogo de um tipo de seguro.
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.position,
    required this.kind,
    required this.label,
  });

  final String id;
  final int position;
  final ItemKind kind;
  final String label;

  factory CatalogItem.fromJson(Map<String, dynamic> j) {
    final kind = ItemKind.parse(j['kind']);
    final id = j['id'];
    final label = j['label'];
    if (kind == null || id is! String || label is! String) {
      throw const FormatException('Item do catálogo inválido');
    }
    return CatalogItem(
      id: id,
      position: _int(j['position']) ?? 0,
      kind: kind,
      label: label,
    );
  }
}

/// Tipo de seguro do catálogo (`get_insurance_catalog()`), já por ordem.
class InsuranceType {
  const InsuranceType({
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.items,
    this.note,
  });

  final String code;
  final String name;

  /// Nota na voz do cliente; nula se o tipo não tem nota.
  final String? note;
  final int sortOrder;
  final List<CatalogItem> items;

  factory InsuranceType.fromRow(Map<String, dynamic> row) {
    final code = row['code'];
    final name = row['name'];
    if (code is! String || name is! String) {
      throw const FormatException('Tipo de seguro inválido');
    }
    final items = [for (final i in _list(row['items'])) CatalogItem.fromJson(i)]
      ..sort((a, b) => a.position.compareTo(b.position));
    return InsuranceType(
      code: code,
      name: name,
      note: _text(row['note']),
      sortOrder: _int(row['sort_order']) ?? 0,
      items: List.unmodifiable(items),
    );
  }
}

// ---------------------------------------------------------------------------
// Mediador: escolher cliente, ficha e lista de Clientes
// ---------------------------------------------------------------------------

/// Cliente com concessão ativa com o escritório (escolha do Novo pedido).
class ActiveClient {
  const ActiveClient({
    required this.clientId,
    required this.fullName,
    required this.email,
  });

  final String clientId;
  final String fullName;
  final String email;
}

/// Estado da partilha de um cliente visto pelo mediador. `unavailable` cobre
/// retirada, outro escritório e inexistente (nunca se distingue).
enum ClientAccess { active, pending, declined, unavailable }

/// Cabeçalho da ficha do cliente (e validação do cliente pré-escolhido no
/// Novo pedido).
class ClientHeader {
  const ClientHeader({
    required this.clientId,
    required this.access,
    this.grantId,
    this.fullName,
    this.email,
    this.since,
  });

  const ClientHeader.unavailable(this.clientId)
    : access = ClientAccess.unavailable,
      grantId = null,
      fullName = null,
      email = null,
      since = null;

  final String clientId;
  final ClientAccess access;

  /// Concessão (para "Reenviar pedido de partilha" quando pendente).
  final String? grantId;
  final String? fullName;
  final String? email;

  /// Data que acompanha o estado (aceite, pedido ou recusa).
  final DateTime? since;

  bool get isActive => access == ClientAccess.active;
}

/// Tipo com pedido em curso para um cliente (`client_open_types`): aviso de
/// repetido e "Em curso desde {data}".
class OpenType {
  const OpenType({
    required this.typeCode,
    required this.typeName,
    required this.openCount,
    required this.firstCreatedAt,
    required this.lastCreatedAt,
    required this.maxStage,
  });

  final String typeCode;
  final String typeName;
  final int openCount;
  final DateTime firstCreatedAt;
  final DateTime lastCreatedAt;
  final RequestStage maxStage;

  factory OpenType.fromRow(Map<String, dynamic> row) {
    final code = row['type_code'];
    final first = _date(row['first_created_at']);
    final last = _date(row['last_created_at']);
    final stage = RequestStage.parse(row['max_stage']);
    if (code is! String || first == null || last == null || stage == null) {
      throw const FormatException('Tipo em curso inválido');
    }
    return OpenType(
      typeCode: code,
      typeName: _text(row['type_name']) ?? code,
      openCount: _int(row['open_count']) ?? 0,
      firstCreatedAt: first,
      lastCreatedAt: last,
      maxStage: stage,
    );
  }
}

/// Coluna "Pedidos" da lista Clientes (`office_requests_summary`). Cliente
/// ativo sem resumo = "Sem pedidos".
class ClientRequestsSummary {
  const ClientRequestsSummary({
    required this.clientId,
    required this.openCount,
    required this.totalCount,
    this.maxOpenStage,
    this.lastCreatedAt,
  });

  final String clientId;
  final int openCount;
  final int totalCount;

  /// Etapa mais avançada entre os pedidos em curso (nula se não há).
  final RequestStage? maxOpenStage;
  final DateTime? lastCreatedAt;

  factory ClientRequestsSummary.fromRow(Map<String, dynamic> row) {
    final id = row['client_id'];
    if (id is! String) throw const FormatException('Resumo inválido');
    return ClientRequestsSummary(
      clientId: id,
      openCount: _int(row['open_count']) ?? 0,
      totalCount: _int(row['total_count']) ?? 0,
      maxOpenStage: RequestStage.parse(row['max_open_stage']),
      lastCreatedAt: _date(row['last_created_at']),
    );
  }
}

/// Linha da ficha do cliente (`list_client_requests`).
class OfficeRequest {
  const OfficeRequest({
    required this.id,
    required this.typeCode,
    required this.typeName,
    required this.stage,
    required this.origin,
    required this.allowPolicyConditions,
    required this.createdAt,
    required this.documentCount,
    required this.dataCount,
    this.authorName,
  });

  final String id;
  final String typeCode;
  final String typeName;
  final RequestStage stage;
  final RequestOrigin origin;
  final bool allowPolicyConditions;
  final DateTime createdAt;
  final String? authorName;
  final int documentCount;
  final int dataCount;

  factory OfficeRequest.fromRow(Map<String, dynamic> row) {
    final b = _RequestBase.parse(row);
    return OfficeRequest(
      id: b.id,
      typeCode: b.typeCode,
      typeName: b.typeName,
      stage: b.stage,
      origin: b.origin,
      allowPolicyConditions: b.allowPolicyConditions,
      createdAt: b.createdAt,
      documentCount: _int(row['document_count']) ?? 0,
      dataCount: _int(row['data_count']) ?? 0,
      authorName: _text(row['author_name']),
    );
  }
}

// ---------------------------------------------------------------------------
// Cliente: "Os meus pedidos"
// ---------------------------------------------------------------------------

/// Linha de "Os meus pedidos" (`list_my_requests`).
class MyRequest {
  const MyRequest({
    required this.id,
    required this.typeCode,
    required this.typeName,
    required this.officeId,
    required this.officeName,
    required this.stage,
    required this.origin,
    required this.allowPolicyConditions,
    required this.createdAt,
    required this.documentCount,
    required this.dataCount,
    required this.accessWithdrawn,
    this.accessWithdrawnAt,
  });

  final String id;
  final String typeCode;
  final String typeName;
  final String officeId;
  final String officeName;
  final RequestStage stage;
  final RequestOrigin origin;
  final bool allowPolicyConditions;
  final DateTime createdAt;
  final int documentCount;
  final int dataCount;

  /// O escritório já não tem concessão ativa: carimbo "Acesso retirado",
  /// sem ações (US 4.3).
  final bool accessWithdrawn;
  final DateTime? accessWithdrawnAt;

  factory MyRequest.fromRow(Map<String, dynamic> row) {
    final b = _RequestBase.parse(row);
    final officeId = row['office_id'];
    if (officeId is! String) throw const FormatException('Pedido inválido');
    return MyRequest(
      id: b.id,
      typeCode: b.typeCode,
      typeName: b.typeName,
      officeId: officeId,
      officeName: _text(row['office_name']) ?? '',
      stage: b.stage,
      origin: b.origin,
      allowPolicyConditions: b.allowPolicyConditions,
      createdAt: b.createdAt,
      documentCount: _int(row['document_count']) ?? 0,
      dataCount: _int(row['data_count']) ?? 0,
      accessWithdrawn: row['access_withdrawn'] == true,
      accessWithdrawnAt: _date(row['access_withdrawn_at']),
    );
  }
}

// ---------------------------------------------------------------------------
// Detalhe (mediador e cliente)
// ---------------------------------------------------------------------------

/// Item guardado no pedido (cópia feita no servidor).
class RequestItem {
  const RequestItem({
    required this.id,
    required this.position,
    required this.kind,
    required this.label,
    required this.source,
  });

  final String id;
  final int position;
  final ItemKind kind;
  final String label;
  final ItemSource source;

  factory RequestItem.fromJson(Map<String, dynamic> j) {
    final kind = ItemKind.parse(j['kind']);
    final label = j['label'];
    if (kind == null || label is! String) {
      throw const FormatException('Item do pedido inválido');
    }
    return RequestItem(
      id: '${j['id'] ?? ''}',
      position: _int(j['position']) ?? 0,
      kind: kind,
      label: label,
      source: ItemSource.parse(j['source']),
    );
  }
}

/// Pedido aberto (`get_request`): ecrã 3b do mediador e ecrã 5 do cliente.
class RequestDetail {
  const RequestDetail({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.officeId,
    required this.officeName,
    required this.typeCode,
    required this.typeName,
    required this.origin,
    required this.stage,
    required this.allowPolicyConditions,
    required this.createdAt,
    required this.accessWithdrawn,
    required this.items,
    this.typeNote,
    this.message,
    this.authorName,
    this.documentsSentAt,
    this.reviewStartedAt,
    this.sentToInsurersAt,
    this.accessWithdrawnAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String officeId;
  final String officeName;
  final String typeCode;
  final String typeName;

  /// Cópia da nota do tipo no momento da criação.
  final String? typeNote;
  final RequestOrigin origin;
  final RequestStage stage;
  final bool allowPolicyConditions;
  final String? message;
  final String? authorName;
  final DateTime createdAt;
  final DateTime? documentsSentAt;
  final DateTime? reviewStartedAt;
  final DateTime? sentToInsurersAt;
  final bool accessWithdrawn;
  final DateTime? accessWithdrawnAt;
  final List<RequestItem> items;

  int get documentCount =>
      items.where((i) => i.kind == ItemKind.document).length;
  int get dataCount => items.where((i) => i.kind == ItemKind.data).length;

  /// Data em que cada etapa foi atingida (nula se por fazer), pela ordem.
  List<DateTime?> get stageDates => [
    createdAt,
    documentsSentAt,
    reviewStartedAt,
    sentToInsurersAt,
  ];

  factory RequestDetail.fromRow(Map<String, dynamic> row) {
    final b = _RequestBase.parse(row);
    final clientId = row['client_id'];
    final officeId = row['office_id'];
    if (clientId is! String || officeId is! String) {
      throw const FormatException('Pedido inválido');
    }
    final items = [for (final i in _list(row['items'])) RequestItem.fromJson(i)]
      ..sort((a, b) => a.position.compareTo(b.position));
    return RequestDetail(
      id: b.id,
      clientId: clientId,
      clientName: _text(row['client_name']) ?? '',
      officeId: officeId,
      officeName: _text(row['office_name']) ?? '',
      typeCode: b.typeCode,
      typeName: b.typeName,
      typeNote: _text(row['type_note']),
      origin: b.origin,
      stage: b.stage,
      allowPolicyConditions: b.allowPolicyConditions,
      message: _text(row['message']),
      authorName: _text(row['author_name']),
      createdAt: b.createdAt,
      documentsSentAt: _date(row['documents_sent_at']),
      reviewStartedAt: _date(row['review_started_at']),
      sentToInsurersAt: _date(row['sent_to_insurers_at']),
      accessWithdrawn: row['access_withdrawn'] == true,
      accessWithdrawnAt: _date(row['access_withdrawn_at']),
      items: List.unmodifiable(items),
    );
  }
}

// ---------------------------------------------------------------------------
// Criar
// ---------------------------------------------------------------------------

/// Item a enviar em `create_requests`: do catálogo (só o id; o servidor
/// copia natureza e texto) ou livre (natureza e texto validados no servidor).
sealed class DraftItem {
  const DraftItem();

  Map<String, Object?> toJson();
}

class CatalogDraftItem extends DraftItem {
  const CatalogDraftItem(this.catalogItemId);

  final String catalogItemId;

  @override
  Map<String, Object?> toJson() => {'catalog_item_id': catalogItemId};
}

class FreeDraftItem extends DraftItem {
  const FreeDraftItem({required this.kind, required this.label});

  final ItemKind kind;
  final String label;

  @override
  Map<String, Object?> toJson() => {'kind': kind.code, 'label': label};
}

/// Um pedido a criar (um por tipo). A ordem de [items] é a guardada.
class RequestDraft {
  const RequestDraft({
    required this.typeCode,
    required this.items,
    this.confirmRepeat = false,
  });

  final String typeCode;
  final List<DraftItem> items;

  /// "Criar outro na mesma" (US 1.8).
  final bool confirmRepeat;

  Map<String, Object?> toJson() => {
    'type_code': typeCode,
    'confirm_repeat': confirmRepeat,
    'items': [for (final i in items) i.toJson()],
  };
}

/// Pedido criado (`create_requests`).
class CreatedRequest {
  const CreatedRequest({
    required this.requestId,
    required this.batchId,
    required this.typeCode,
    required this.typeName,
    required this.createdAt,
  });

  final String requestId;

  /// Igual nos N pedidos da mesma criação (é o que o email recebe).
  final String batchId;
  final String typeCode;
  final String typeName;
  final DateTime createdAt;

  factory CreatedRequest.fromRow(Map<String, dynamic> row) {
    final id = row['request_id'];
    final batch = row['batch_id'];
    final code = row['type_code'];
    final created = _date(row['created_at']);
    if (id is! String || batch is! String || code is! String) {
      throw const FormatException('Pedido criado inválido');
    }
    return CreatedRequest(
      requestId: id,
      batchId: batch,
      typeCode: code,
      typeName: _text(row['type_name']) ?? code,
      createdAt: created ?? DateTime.now(),
    );
  }
}

/// Uma página de uma lista paginada, com os totais (todas as páginas) que o
/// servidor devolve em cada linha. Os totais são nulos quando a página vem
/// vazia depois da primeira (não se sabe).
class RequestsPage<T> {
  const RequestsPage({required this.items, this.totalCount, this.openCount});

  final List<T> items;
  final int? totalCount;
  final int? openCount;
}

// ---------------------------------------------------------------------------
// Falhas
// ---------------------------------------------------------------------------

enum RequestFailureKind {
  /// Sem ligação ou servidor inalcançável.
  network,

  /// Quem chama não é mediador com escritório (ou sem sessão).
  notAuthorized,

  /// Sem concessão ativa (pendente, recusada, retirada, outro escritório,
  /// inexistente). Copy: "Este cliente já não partilha dados consigo."
  clientNotAvailable,

  /// Pedido mal formado (tipos, confirmações). [RequestFailure.typeCodes]
  /// pode trazer o tipo.
  invalidInput,

  /// A lista de um tipo está vazia. [RequestFailure.typeCodes] = o tipo.
  emptyList,

  /// Item recusado (texto, natureza, repetido...). [RequestFailure.typeCodes]
  /// = o tipo.
  invalidItem,

  /// Mensagem com mais de 500 caracteres.
  messageTooLong,

  /// Já há pedido em curso destes tipos e não veio a confirmação.
  /// [RequestFailure.typeCodes] = os tipos. Nada foi criado.
  repeatedRequest,

  /// Não existe ou não é acessível (nunca se distingue).
  notFound,

  /// O email do pedido não foi enviado (os pedidos existem).
  emailNotSent,

  /// Limite de 60 s por destinatário. Ver [RequestFailure.retryAfterSeconds].
  tooSoon,

  /// Qualquer outra falha. Nunca mostrar texto técnico.
  unknown,
}

/// Falha já classificada: a UI só vê o tipo (nunca a `message` do servidor).
class RequestFailure implements Exception {
  const RequestFailure(
    this.kind, {
    this.typeCodes = const [],
    this.retryAfterSeconds,
  });

  final RequestFailureKind kind;

  /// Tipos envolvidos (de `details`), quando o servidor os indica.
  final List<String> typeCodes;
  final int? retryAfterSeconds;

  @override
  String toString() => 'RequestFailure($kind, $typeCodes)';
}

// ---------------------------------------------------------------------------
// Auxiliares de leitura
// ---------------------------------------------------------------------------

class _RequestBase {
  const _RequestBase({
    required this.id,
    required this.typeCode,
    required this.typeName,
    required this.stage,
    required this.origin,
    required this.allowPolicyConditions,
    required this.createdAt,
  });

  final String id;
  final String typeCode;
  final String typeName;
  final RequestStage stage;
  final RequestOrigin origin;
  final bool allowPolicyConditions;
  final DateTime createdAt;

  static _RequestBase parse(Map<String, dynamic> row) {
    final id = row['request_id'] ?? row['id'];
    final code = row['type_code'];
    final stage = RequestStage.parse(row['stage']);
    final origin = RequestOrigin.parse(row['origin']);
    final created = _date(row['created_at']);
    if (id is! String ||
        code is! String ||
        stage == null ||
        origin == null ||
        created == null) {
      throw const FormatException('Pedido inválido');
    }
    return _RequestBase(
      id: id,
      typeCode: code,
      typeName: _text(row['type_name']) ?? code,
      stage: stage,
      origin: origin,
      allowPolicyConditions: row['allow_policy_conditions'] == true,
      createdAt: created,
    );
  }
}

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];
