import 'admin_models.dart';

/// Contrato de dados do admin. A UI só fala com esta interface (os testes
/// usam um fake). Lança [AdminFailure].
abstract interface class AdminRepository {
  /// As 3 contagens (função `admin_counts`).
  Future<AdminCounts> loadCounts();

  /// Escritórios, o mais recente primeiro, com o nº de mediadores.
  Future<List<OfficeSummary>> loadOffices();

  /// Cria um escritório e devolve-o.
  Future<OfficeSummary> createOffice(String name);

  /// Convida um mediador para o escritório (função `invite-mediator`, com a
  /// sessão do admin). O email não é guardado nem devolvido.
  Future<void> inviteMediator({
    required String officeId,
    required String email,
    required String fullName,
  });
}
