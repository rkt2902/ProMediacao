import '../domain/request_models.dart';
import 'batch_email_controller.dart';

/// Resultado de "Criar" no Novo pedido, já confirmado pelo servidor: os
/// pedidos criados e o que aconteceu ao email. É o que a ficha do cliente
/// mostra ao entrar ("2 pedidos criados: ..." ou o aviso de email).
class CreatedBatch {
  const CreatedBatch({
    required this.batchId,
    required this.clientId,
    required this.requests,
    required this.emailStatus,
    this.clientName,
    this.clientEmail,
    this.emailLockUntil,
  });

  final String batchId;
  final String clientId;
  final String? clientName;

  /// Para "Email enviado a {email}." (o do servidor, se o disse).
  final String? clientEmail;

  /// Pela ordem do catálogo (a ordem em que foram pedidos).
  final List<CreatedRequest> requests;
  final BatchEmailStatus emailStatus;
  final DateTime? emailLockUntil;

  int get count => requests.length;
  List<String> get typeNames => [for (final r in requests) r.typeName];
  Set<String> get requestIds => {for (final r in requests) r.requestId};
}

/// Passagem do Novo pedido para a ficha do cliente. Ordem depois de "Criar":
/// resposta do servidor -> envio do email -> [put] -> navegar para a ficha,
/// que chama [take] ao arrancar. Lido uma só vez (como
/// `session.takeNotice()`).
class CreatedRequestsHandoff {
  CreatedBatch? _batch;

  void put(CreatedBatch batch) => _batch = batch;

  /// O resultado de [clientId], se houver (e esquece-o).
  CreatedBatch? take(String clientId) {
    final b = _batch;
    if (b == null || b.clientId != clientId) return null;
    _batch = null;
    return b;
  }

  void clear() => _batch = null;
}
