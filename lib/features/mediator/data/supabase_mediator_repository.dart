import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/mediator_models.dart';
import '../domain/mediator_repository.dart';

/// Implementação sobre o Supabase: a lista vem da função `list_office_clients`
/// (que já só devolve nome, email e estado) e as ações das funções de
/// servidor `create-client` e `resend-request`, chamadas com a sessão do
/// mediador. Traduz todas as exceções para [MediatorFailure].
class SupabaseMediatorRepository implements MediatorRepository {
  SupabaseMediatorRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OfficeClient>> listClients({
    required int limit,
    required int offset,
  }) async {
    try {
      final rows = await _client.rpc(
        'list_office_clients',
        params: {'p_limit': limit, 'p_offset': offset},
      );
      final out = <OfficeClient>[];
      if (rows is List) {
        for (final r in rows) {
          if (r is! Map) continue;
          final status = ClientStatus.parse(r['status']);
          final updated = DateTime.tryParse('${r['updated_at']}');
          if (status == null || updated == null) continue;
          out.add(
            OfficeClient(
              grantId: '${r['grant_id']}',
              fullName: '${r['full_name'] ?? ''}',
              email: '${r['email'] ?? ''}',
              status: status,
              updatedAt: updated,
            ),
          );
        }
      }
      return out;
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> createClient({
    required String fullName,
    required String email,
  }) => _invoke('create-client', {'full_name': fullName, 'email': email});

  @override
  Future<void> resendRequest(String grantId) =>
      _invoke('resend-request', {'grant_id': grantId});

  Future<void> _invoke(String function, Map<String, dynamic> body) async {
    try {
      await _client.functions.invoke(function, body: body);
    } on Object catch (e) {
      throw _map(e);
    }
  }

  MediatorFailure _map(Object e) {
    if (e is AuthRetryableFetchException) {
      return const MediatorFailure(MediatorFailureKind.network);
    }
    if (e is FunctionException) {
      final details = e.details;
      final error = details is Map ? details['error'] : null;
      final code = error is Map ? error['code'] : null;
      final retry = error is Map ? error['retry_after_seconds'] : null;
      if (e.status == 429 || code == 'too_soon') {
        return MediatorFailure(
          MediatorFailureKind.tooSoon,
          retryAfterSeconds: retry is num ? retry.toInt() : null,
        );
      }
      return MediatorFailure(switch (code) {
        'already_client' => MediatorFailureKind.alreadyClient,
        'declined' => MediatorFailureKind.declined,
        'not_pending' => MediatorFailureKind.notPending,
        'invalid_input' => MediatorFailureKind.invalidInput,
        'send_failed' => MediatorFailureKind.sendFailed,
        'forbidden' || 'not_found' => MediatorFailureKind.forbidden,
        _ => MediatorFailureKind.unknown,
      });
    }
    if (e is AuthException || e is PostgrestException) {
      return const MediatorFailure(MediatorFailureKind.unknown);
    }
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const MediatorFailure(MediatorFailureKind.network);
  }
}
