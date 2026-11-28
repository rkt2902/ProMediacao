import 'dart:async';

import 'package:promediacao/features/requests/domain/request_models.dart';
import 'package:promediacao/features/requests/domain/requests_repository.dart';

/// Repositório de pedidos em memória para os testes (e para os ecrãs das
/// tarefas 4 e 5). Cada leitura pode falhar com [failNext] (uma vez) ou
/// ficar à espera de [gate].
class FakeRequestsRepository implements RequestsRepository {
  FakeRequestsRepository({
    List<InsuranceType>? catalog,
    List<ActiveClient>? clients,
    Map<String, ClientHeader>? headers,
  }) : catalogTypes = catalog ?? sampleCatalog(),
       clients = clients ?? [maria, joao],
       headers =
           headers ??
           {
             maria.clientId: activeHeader(maria),
             joao.clientId: activeHeader(joao),
           };

  static const maria = ActiveClient(
    clientId: 'c-maria',
    fullName: 'Maria do Carmo Figueiredo',
    email: 'maria.figueiredo@exemplo.pt',
  );
  static const joao = ActiveClient(
    clientId: 'c-joao',
    fullName: 'João Lima',
    email: 'joao.lima@exemplo.pt',
  );

  static ClientHeader activeHeader(ActiveClient c) => ClientHeader(
    clientId: c.clientId,
    access: ClientAccess.active,
    grantId: 'g-${c.clientId}',
    fullName: c.fullName,
    email: c.email,
    since: DateTime.utc(2026, 11, 12, 10, 4),
  );

  static List<InsuranceType> sampleCatalog() => const [
    InsuranceType(
      code: 'automovel',
      name: 'Automóvel',
      sortOrder: 1,
      note: 'Se o condutor habitual não for o tomador, envie também o CC.',
      items: [
        CatalogItem(
          id: 'i-auto-1',
          position: 1,
          kind: ItemKind.document,
          label: 'Cartão de Cidadão',
        ),
        CatalogItem(
          id: 'i-auto-2',
          position: 2,
          kind: ItemKind.document,
          label: 'Documento Único Automóvel',
        ),
        CatalogItem(
          id: 'i-auto-3',
          position: 3,
          kind: ItemKind.data,
          label: 'Data da carta de condução',
        ),
      ],
    ),
    InsuranceType(
      code: 'vida',
      name: 'Vida',
      sortOrder: 2,
      items: [
        CatalogItem(
          id: 'i-vida-1',
          position: 1,
          kind: ItemKind.document,
          label: 'Cartão de Cidadão',
        ),
      ],
    ),
  ];

  final List<InsuranceType> catalogTypes;
  final List<ActiveClient> clients;
  final Map<String, ClientHeader> headers;

  /// Tipos em curso por cliente.
  final Map<String, List<OpenType>> openTypes = {};

  /// Pedidos por cliente (ficha), mais recentes primeiro.
  final Map<String, List<OfficeRequest>> officeRequests = {};
  final List<MyRequest> mine = [];
  final Map<String, RequestDetail> details = {};
  Map<String, ClientRequestsSummary> summary = {};
  int openRequestCount = 0;

  /// Falha a lançar na próxima chamada (só uma vez).
  RequestFailure? failNext;

  /// Falha a lançar em `createRequests` (fica até ser limpa).
  RequestFailure? createFailure;

  /// Se não nulo, as leituras esperam por ele.
  Completer<void>? gate;

  final List<
    ({
      String clientId,
      List<RequestDraft> requests,
      bool allowPolicyConditions,
      String? message,
    })
  >
  createCalls = [];
  int catalogCalls = 0;
  int openTypesCalls = 0;

  Future<void> _step() async {
    if (gate != null) await gate!.future;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Future<List<InsuranceType>> catalog() async {
    catalogCalls++;
    await _step();
    return catalogTypes;
  }

  @override
  Future<List<ActiveClient>> activeClients() async {
    await _step();
    return clients;
  }

  @override
  Future<ClientHeader> clientHeader(String clientId) async {
    await _step();
    return headers[clientId] ?? ClientHeader.unavailable(clientId);
  }

  @override
  Future<List<OpenType>> clientOpenTypes(String clientId) async {
    openTypesCalls++;
    await _step();
    return openTypes[clientId] ?? const [];
  }

  @override
  Future<List<CreatedRequest>> createRequests({
    required String clientId,
    required List<RequestDraft> requests,
    bool allowPolicyConditions = false,
    String? message,
  }) async {
    createCalls.add((
      clientId: clientId,
      requests: requests,
      allowPolicyConditions: allowPolicyConditions,
      message: message,
    ));
    await _step();
    final f = createFailure;
    if (f != null) throw f;
    final now = DateTime.utc(2026, 11, 27, 10, 14);
    return [
      for (final (i, r) in requests.indexed)
        CreatedRequest(
          requestId: 'r-${createCalls.length}-$i',
          batchId: 'b-${createCalls.length}',
          typeCode: r.typeCode,
          typeName: catalogTypes.firstWhere((t) => t.code == r.typeCode).name,
          createdAt: now,
        ),
    ];
  }

  @override
  Future<Map<String, ClientRequestsSummary>> officeRequestsSummary([
    List<String>? clientIds,
  ]) async {
    await _step();
    return {
      for (final e in summary.entries)
        if (clientIds == null || clientIds.contains(e.key)) e.key: e.value,
    };
  }

  @override
  Future<int> officeOpenRequestCount() async {
    await _step();
    return openRequestCount;
  }

  @override
  Future<RequestsPage<OfficeRequest>> clientRequests(
    String clientId, {
    int limit = 25,
    int offset = 0,
  }) async {
    await _step();
    final all = officeRequests[clientId] ?? const <OfficeRequest>[];
    return RequestsPage(
      items: all.skip(offset).take(limit).toList(),
      totalCount: all.length,
      openCount: all.where((r) => r.stage.isOpen).length,
    );
  }

  @override
  Future<RequestDetail?> request(String requestId) async {
    await _step();
    return details[requestId];
  }

  @override
  Future<RequestsPage<MyRequest>> myRequests({
    int limit = 25,
    int offset = 0,
  }) async {
    await _step();
    return RequestsPage(
      items: mine.skip(offset).take(limit).toList(),
      totalCount: mine.length,
      openCount: mine.where((r) => r.stage.isOpen && !r.accessWithdrawn).length,
    );
  }
}

/// Pedido do mediador de exemplo para a ficha.
OfficeRequest officeRequest(String id, {String type = 'automovel'}) =>
    OfficeRequest(
      id: id,
      typeCode: type,
      typeName: type == 'vida' ? 'Vida' : 'Automóvel',
      stage: RequestStage.created,
      origin: RequestOrigin.mediador,
      allowPolicyConditions: false,
      createdAt: DateTime.utc(2026, 11, 27, 10, 14),
      documentCount: 2,
      dataCount: 1,
      authorName: 'Ana Martins',
    );

/// Pedido do cliente de exemplo.
MyRequest myRequest(String id, {bool withdrawn = false}) => MyRequest(
  id: id,
  typeCode: 'automovel',
  typeName: 'Automóvel',
  officeId: withdrawn ? 'o-lima' : 'o-ribeira',
  officeName: withdrawn ? 'Seguros Lima & Viana' : 'Ribeira Seguros',
  stage: RequestStage.created,
  origin: RequestOrigin.mediador,
  allowPolicyConditions: false,
  createdAt: DateTime.utc(2026, 11, 27, 10, 14),
  documentCount: 4,
  dataCount: 2,
  accessWithdrawn: withdrawn,
  accessWithdrawnAt: withdrawn ? DateTime.utc(2026, 11, 26, 15, 2) : null,
);
