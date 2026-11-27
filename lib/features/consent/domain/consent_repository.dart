import 'consent_models.dart';

/// Contrato do consentimento do cliente. A app só fala com esta interface,
/// para os testes usarem um fake. Todas as falhas chegam como
/// [ConsentFailure].
///
/// Só o cliente titular muda o estado: a garantia é da base de dados (RLS e
/// trigger de transições). As operações de escrita devolvem a concessão tal
/// como o servidor a confirmou; nada é dado como aceite, recusado ou
/// retirado sem essa resposta.
abstract interface class ConsentRepository {
  /// Concessões do cliente autenticado (`my_consents()`), mais recentes
  /// primeiro.
  Future<List<ConsentGrant>> myConsents();

  /// Versão corrente do texto (`current_consent_version()`).
  Future<String> currentVersion();

  /// Texto de uma versão. Lança `notFound` se não existir.
  Future<ConsentText> text(String version);

  /// Pendente -> ativa, com a [version] do texto que o cliente leu.
  /// `stateChanged` se o pedido já não estiver pendente.
  Future<ConsentGrant> accept(ConsentGrant grant, {required String version});

  /// Pendente -> recusada. `stateChanged` se já não estiver pendente.
  Future<ConsentGrant> decline(ConsentGrant grant);

  /// Ativa -> retirada. `stateChanged` se já não estiver ativa.
  Future<ConsentGrant> withdraw(ConsentGrant grant);

  /// Voltar a aceitar depois de retirar (`reaccept_grant`): nasce uma
  /// concessão nova, ativa, com [version]. Devolve o id novo.
  Future<String> reaccept({required String officeId, required String version});
}
