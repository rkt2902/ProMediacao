import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/request_email_sender.dart';
import '../domain/request_models.dart';

/// Envio pela função `send-request-email` (contrato em
/// `supabase/functions/README.md`), com a sessão do mediador. O mesmo
/// pedido serve para "Reenviar email".
class SupabaseRequestEmailSender implements RequestEmailSender {
  SupabaseRequestEmailSender(this._client);

  static const function = 'send-request-email';

  final SupabaseClient _client;

  @override
  Future<RequestEmailReceipt> send(String batchId) async {
    try {
      final res = await _client.functions.invoke(
        function,
        body: {'batch_id': batchId},
      );
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        return RequestEmailReceipt(
          recipientEmail: data['recipient_email'] as String?,
          sentAt: DateTime.tryParse('${data['sent_at']}'),
          nextAllowedAt: DateTime.tryParse('${data['next_allowed_at']}'),
        );
      }
      throw const RequestFailure(RequestFailureKind.emailNotSent);
    } on RequestFailure {
      rethrow;
    } on Object catch (e) {
      throw mapError(e);
    }
  }

  /// Classificação das respostas de erro (pública para teste). Fora de 401,
  /// 403 e 400, tudo é "o email não foi enviado" (US 4.4), incluindo 404
  /// (função ainda por publicar, ou batch não encontrado) e 503
  /// `email_unavailable` (fornecedor de email por configurar).
  static RequestFailure mapError(Object e) {
    if (e is RequestFailure) return e;
    if (e is FunctionException) {
      final details = e.details;
      final error = details is Map ? details['error'] : null;
      final code = error is Map ? error['code'] : null;
      final retryRaw = error is Map ? error['retry_after_seconds'] : null;
      final retry = retryRaw is num ? retryRaw.toInt() : null;
      if (code == 'too_soon' || e.status == 429) {
        return RequestFailure(
          RequestFailureKind.tooSoon,
          retryAfterSeconds: retry,
        );
      }
      if (code == 'client_not_available' || e.status == 409) {
        return const RequestFailure(RequestFailureKind.clientNotAvailable);
      }
      if (e.status == 401 || e.status == 403 || code == 'forbidden') {
        return const RequestFailure(RequestFailureKind.notAuthorized);
      }
      if (e.status == 400 || code == 'invalid_input') {
        return const RequestFailure(RequestFailureKind.unknown);
      }
      return RequestFailure(
        RequestFailureKind.emailNotSent,
        retryAfterSeconds: retry,
      );
    }
    if (e is AuthRetryableFetchException) {
      return const RequestFailure(RequestFailureKind.network);
    }
    if (e is AuthException || e is FormatException || e is TypeError) {
      return const RequestFailure(RequestFailureKind.unknown);
    }
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const RequestFailure(RequestFailureKind.network);
  }
}
