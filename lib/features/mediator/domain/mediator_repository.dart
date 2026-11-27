import 'mediator_models.dart';

/// Contrato de dados do mediador. A UI só fala com esta interface (os
/// testes usam um fake). Todas as falhas chegam como [MediatorFailure].
abstract interface class MediatorRepository {
  /// Clientes do escritório, mais recentemente alterados primeiro.
  Future<List<OfficeClient>> listClients({
    required int limit,
    required int offset,
  });

  /// Total de clientes que [listClients] lista (`office_client_count()`), ou
  /// `null` se não for possível saber (nunca lança: a lista vive sem total).
  Future<int?> countClients();

  /// Cria o cliente e o pedido pendente e envia-o. A resposta de sucesso é
  /// igual exista ou não a conta (nunca revela nada).
  Future<void> createClient({required String fullName, required String email});

  /// "Reenviar pedido" de uma concessão pendente. Diz se seguiu um email ou
  /// se o pedido só está à espera na app do cliente.
  Future<ResendDelivery> resendRequest(String grantId);
}
