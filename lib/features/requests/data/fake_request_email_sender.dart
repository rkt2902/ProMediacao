import '../domain/request_email_sender.dart';
import '../domain/request_models.dart';

/// Envio falso, sem rede: regista os pedidos e responde com [failure] (se
/// houver) ou com sucesso. Serve os testes e as demonstrações sem a função
/// `send-request-email` publicada.
class FakeRequestEmailSender implements RequestEmailSender {
  FakeRequestEmailSender({
    this.failure,
    this.recipientEmail,
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Falha a devolver em cada envio; `null` = enviado.
  RequestFailure? failure;
  String? recipientEmail;
  final Duration cooldown;
  final DateTime Function() _now;

  /// `batch_id` de cada pedido de envio, por ordem.
  final List<String> calls = [];

  @override
  Future<RequestEmailReceipt> send(String batchId) async {
    calls.add(batchId);
    final f = failure;
    if (f != null) throw f;
    final now = _now();
    return RequestEmailReceipt(
      recipientEmail: recipientEmail,
      sentAt: now,
      nextAllowedAt: now.add(cooldown),
    );
  }
}
