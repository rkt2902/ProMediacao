import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/request_models.dart';
import '../domain/requests_repository.dart';

/// Implementação sobre as RPC da migração 002 (contrato no topo de
/// `supabase/migrations/20261127120000_002_requests.sql`). Os erros do
/// servidor chegam com um código estável em `message`; são traduzidos para
/// [RequestFailure] e a `message` nunca chega à UI.
class SupabaseRequestsRepository implements RequestsRepository {
  SupabaseRequestsRepository(this._client);

  final SupabaseClient _client;

  /// Máximo de linhas por pedido em `list_office_clients`.
  static const _clientsPage = 200;

  /// Limite de segurança para juntar páginas de clientes (5 x 200).
  static const _clientsMaxPages = 5;

  @override
  Future<List<InsuranceType>> catalog() => _guard(() async {
    final rows = await _client.rpc<dynamic>('get_insurance_catalog');
    return [for (final r in _rows(rows)) InsuranceType.fromRow(r)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  });

  @override
  Future<List<ActiveClient>> activeClients() => _guard(() async {
    final out = <ActiveClient>[];
    for (var page = 0; page < _clientsMaxPages; page++) {
      final rows = _rows(
        await _client.rpc<dynamic>(
          'list_office_clients',
          params: {'p_limit': _clientsPage, 'p_offset': page * _clientsPage},
        ),
      );
      for (final r in rows) {
        final id = r['client_id'];
        if (r['status'] != 'ativa' || id is! String) continue;
        out.add(
          ActiveClient(
            clientId: id,
            fullName: '${r['full_name'] ?? ''}',
            email: '${r['email'] ?? ''}',
          ),
        );
      }
      if (rows.length < _clientsPage) break;
    }
    out.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return out;
  });

  @override
  Future<ClientHeader> clientHeader(String clientId) => _guard(() async {
    // RLS da 001: o mediador vê as concessões do seu escritório, nunca as
    // retiradas; o perfil só com concessão ativa.
    final grants = await _client
        .from('consent_grants')
        .select('id, status, created_at, updated_at, accepted_at, declined_at')
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .limit(1);
    if (grants.isEmpty) return ClientHeader.unavailable(clientId);
    final g = grants.first;
    final grantId = '${g['id']}';
    switch (g['status']) {
      case 'ativa':
        final p = await _client
            .from('profiles')
            .select('full_name, email')
            .eq('id', clientId)
            .maybeSingle();
        if (p == null) return ClientHeader.unavailable(clientId);
        return ClientHeader(
          clientId: clientId,
          access: ClientAccess.active,
          grantId: grantId,
          fullName: '${p['full_name'] ?? ''}',
          email: '${p['email'] ?? ''}',
          since: _date(g['accepted_at']) ?? _date(g['updated_at']),
        );
      case 'pendente' || 'recusada':
        // Nome e email de pendentes/recusados só pela lista do escritório.
        final row = await _findOfficeClient(grantId);
        final pending = g['status'] == 'pendente';
        return ClientHeader(
          clientId: clientId,
          access: pending ? ClientAccess.pending : ClientAccess.declined,
          grantId: grantId,
          fullName: row?['full_name'] as String?,
          email: row?['email'] as String?,
          since: pending
              ? _date(g['updated_at']) ?? _date(g['created_at'])
              : _date(g['declined_at']) ?? _date(g['updated_at']),
        );
    }
    return ClientHeader.unavailable(clientId);
  });

  Future<Map<String, dynamic>?> _findOfficeClient(String grantId) async {
    for (var page = 0; page < _clientsMaxPages; page++) {
      final rows = _rows(
        await _client.rpc<dynamic>(
          'list_office_clients',
          params: {'p_limit': _clientsPage, 'p_offset': page * _clientsPage},
        ),
      );
      for (final r in rows) {
        if ('${r['grant_id']}' == grantId) return r;
      }
      if (rows.length < _clientsPage) break;
    }
    return null;
  }

  @override
  Future<List<OpenType>> clientOpenTypes(String clientId) => _guard(() async {
    final rows = await _client.rpc<dynamic>(
      'client_open_types',
      params: {'p_client_id': clientId},
    );
    return [for (final r in _rows(rows)) OpenType.fromRow(r)];
  });

  @override
  Future<List<CreatedRequest>> createRequests({
    required String clientId,
    required List<RequestDraft> requests,
    bool allowPolicyConditions = false,
    String? message,
  }) => _guard(() async {
    final text = message?.trim();
    final rows = await _client.rpc<dynamic>(
      'create_requests',
      params: {
        'p_client_id': clientId,
        'p_requests': [for (final r in requests) r.toJson()],
        'p_allow_policy_conditions': allowPolicyConditions,
        'p_message': text == null || text.isEmpty ? null : text,
      },
    );
    final created = [for (final r in _rows(rows)) CreatedRequest.fromRow(r)];
    // Atómica: sem linhas, nada foi criado e não se sabe porquê.
    if (created.isEmpty) {
      throw const RequestFailure(RequestFailureKind.unknown);
    }
    return created;
  });

  @override
  Future<Map<String, ClientRequestsSummary>> officeRequestsSummary([
    List<String>? clientIds,
  ]) => _guard(() async {
    final rows = await _client.rpc<dynamic>(
      'office_requests_summary',
      params: {'p_client_ids': clientIds},
    );
    return {
      for (final r in _rows(rows))
        '${r['client_id']}': ClientRequestsSummary.fromRow(r),
    };
  });

  @override
  Future<int> officeOpenRequestCount() => _guard(() async {
    final v = await _client.rpc<dynamic>('office_open_request_count');
    return _int(v) ?? 0;
  });

  @override
  Future<RequestsPage<OfficeRequest>> clientRequests(
    String clientId, {
    int limit = 25,
    int offset = 0,
  }) => _guard(() async {
    final rows = _rows(
      await _client.rpc<dynamic>(
        'list_client_requests',
        params: {'p_client_id': clientId, 'p_limit': limit, 'p_offset': offset},
      ),
    );
    return _page(rows, offset, OfficeRequest.fromRow);
  });

  @override
  Future<RequestDetail?> request(String requestId) => _guard(() async {
    final rows = _rows(
      await _client.rpc<dynamic>(
        'get_request',
        params: {'p_request_id': requestId},
      ),
    );
    return rows.isEmpty ? null : RequestDetail.fromRow(rows.first);
  });

  @override
  Future<RequestsPage<MyRequest>> myRequests({
    int limit = 25,
    int offset = 0,
  }) => _guard(() async {
    final rows = _rows(
      await _client.rpc<dynamic>(
        'list_my_requests',
        params: {'p_limit': limit, 'p_offset': offset},
      ),
    );
    return _page(rows, offset, MyRequest.fromRow);
  });

  RequestsPage<T> _page<T>(
    List<Map<String, dynamic>> rows,
    int offset,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (rows.isEmpty) {
      return RequestsPage<T>(
        items: const [],
        totalCount: offset == 0 ? 0 : null,
        openCount: offset == 0 ? 0 : null,
      );
    }
    return RequestsPage<T>(
      items: [for (final r in rows) parse(r)],
      totalCount: _int(rows.first['total_count']),
      openCount: _int(rows.first['open_count']),
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on RequestFailure {
      rethrow;
    } on Object catch (e) {
      throw mapError(e);
    }
  }

  /// Classificação das falhas das RPC (pública para teste). Decide pelo
  /// código estável em `message`; `details` traz os tipos quando indicado.
  static RequestFailure mapError(Object e) {
    if (e is RequestFailure) return e;
    if (e is PostgrestException) {
      final codes = _typeCodes(e.details);
      return switch (e.message) {
        'not_authorized' => const RequestFailure(
          RequestFailureKind.notAuthorized,
        ),
        'client_not_available' => const RequestFailure(
          RequestFailureKind.clientNotAvailable,
        ),
        'invalid_input' => RequestFailure(
          RequestFailureKind.invalidInput,
          typeCodes: codes,
        ),
        'empty_list' => RequestFailure(
          RequestFailureKind.emptyList,
          typeCodes: codes,
        ),
        'invalid_item' => RequestFailure(
          RequestFailureKind.invalidItem,
          typeCodes: codes,
        ),
        'message_too_long' => const RequestFailure(
          RequestFailureKind.messageTooLong,
        ),
        'repeated_request' => RequestFailure(
          RequestFailureKind.repeatedRequest,
          typeCodes: codes,
        ),
        'not_found' => const RequestFailure(RequestFailureKind.notFound),
        _ =>
          // Permissão recusada sem código nosso (ex.: sessão de outro papel).
          e.code == '42501'
              ? const RequestFailure(RequestFailureKind.notAuthorized)
              : const RequestFailure(RequestFailureKind.unknown),
      };
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

  static List<String> _typeCodes(Object? details) {
    if (details is! String) return const [];
    return [
      for (final c in details.split(','))
        if (c.trim().isNotEmpty) c.trim(),
    ];
  }
}

List<Map<String, dynamic>> _rows(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
