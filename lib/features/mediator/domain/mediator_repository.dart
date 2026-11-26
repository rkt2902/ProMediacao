import 'mediator_models.dart';

/// Contrato de dados do mediador. A UI só fala com esta interface (os
/// testes usam um fake). Todas as falhas chegam como [MediatorFailure].
abstract interface class MediatorRepository {
  /// Clientes do escritório, mais recentemente alterados primeiro.
  Future<List<OfficeClient>> listClients({
    required int limit,
    required int offset,
  });

  /// Cria o cliente e o pedido pendente e envia-o. A resposta de sucesso é
  /// igual exista ou não a conta (nunca revela nada).
  Future<void> createClient({required String fullName, required String email});

  /// "Reenviar pedido" de uma concessão pendente.
  Future<void> resendRequest(String grantId);
}
