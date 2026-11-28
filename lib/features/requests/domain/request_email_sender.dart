import 'request_models.dart';

/// Resposta de sucesso da função `send-request-email`.
class RequestEmailReceipt {
  const RequestEmailReceipt({
    this.recipientEmail,
    this.sentAt,
    this.nextAllowedAt,
  });

  /// Para quem seguiu ("Email enviado a {email}").
  final String? recipientEmail;
  final DateTime? sentAt;

  /// A partir de quando se pode reenviar ("Pode reenviar às {hora}").
  final DateTime? nextAllowedAt;
}

/// Envio e reenvio do email curto de uma criação (um email por `batch_id`,
/// US 4.1 e 4.4). Contrato em `supabase/functions/README.md`
/// (`send-request-email`). O envio nunca desfaz nem altera os pedidos.
///
/// Falhas como [RequestFailure]:
/// - `emailNotSent`: não seguiu (fornecedor por configurar, função por
///   publicar, falha do fornecedor, batch não encontrado, erro do servidor).
///   [RequestFailure.retryAfterSeconds] vem quando o servidor pede espera.
/// - `tooSoon`: limite de 60 s; ver [RequestFailure.retryAfterSeconds].
/// - `clientNotAvailable`: a concessão já não está ativa (sem reenviar).
/// - `network`: sem ligação.
/// - `notAuthorized` / `unknown`: erro genérico (401, 403, 400).
abstract interface class RequestEmailSender {
  /// Envia (ou reenvia: é o mesmo pedido) o email da criação [batchId].
  Future<RequestEmailReceipt> send(String batchId);
}
