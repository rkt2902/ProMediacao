import 'request_models.dart';

/// Contrato de dados dos pedidos (feature 002). A UI e os controladores só
/// falam com esta interface (os testes usam um fake). Todas as falhas chegam
/// como [RequestFailure]. Identidade e escritório vêm sempre da sessão no
/// servidor: nenhum método recebe o utilizador nem o escritório.
///
/// "Sem acesso" nas leituras = lista vazia ou `null` (nunca erro), para não
/// revelar se o cliente ou o pedido existe.
abstract interface class RequestsRepository {
  // ---- Catálogo -------------------------------------------------------------

  /// Tipos e itens ativos, por ordem (`get_insurance_catalog()`).
  Future<List<InsuranceType>> catalog();

  // ---- Mediador -------------------------------------------------------------

  /// Clientes com concessão ativa com o escritório (escolha do Novo pedido).
  Future<List<ActiveClient>> activeClients();

  /// Cabeçalho da ficha e validação do cliente pré-escolhido: nome, email,
  /// estado e data da concessão. Nunca lança por falta de acesso: devolve
  /// `ClientAccess.unavailable`.
  Future<ClientHeader> clientHeader(String clientId);

  /// Tipos com pedido em curso deste escritório para o cliente
  /// (`client_open_types`). Vazio sem concessão ativa.
  Future<List<OpenType>> clientOpenTypes(String clientId);

  /// Cria N pedidos (um por [RequestDraft]) de forma atómica
  /// (`create_requests`): ou todos ou nenhum. A mensagem é aparada; vazia
  /// vai como nula.
  Future<List<CreatedRequest>> createRequests({
    required String clientId,
    required List<RequestDraft> requests,
    bool allowPolicyConditions = false,
    String? message,
  });

  /// Coluna "Pedidos" da lista Clientes (`office_requests_summary`), por
  /// `clientId`. [clientIds] = os da página (máx. 200); `null` = todos.
  /// Cliente ativo sem entrada = "Sem pedidos".
  Future<Map<String, ClientRequestsSummary>> officeRequestsSummary([
    List<String>? clientIds,
  ]);

  /// "{n} pedidos em curso" do cabeçalho de Clientes
  /// (`office_open_request_count()`).
  Future<int> officeOpenRequestCount();

  /// Pedidos deste escritório para o cliente, mais recentes primeiro
  /// (`list_client_requests`).
  Future<RequestsPage<OfficeRequest>> clientRequests(
    String clientId, {
    int limit = 25,
    int offset = 0,
  });

  // ---- Mediador e cliente ---------------------------------------------------

  /// Detalhe (`get_request`). `null` = "Pedido não encontrado" / "Sem acesso".
  Future<RequestDetail?> request(String requestId);

  // ---- Cliente --------------------------------------------------------------

  /// "Os meus pedidos" (`list_my_requests`), mais recentes primeiro.
  /// `openCount` = em curso e com acesso não retirado.
  Future<RequestsPage<MyRequest>> myRequests({int limit = 25, int offset = 0});
}
