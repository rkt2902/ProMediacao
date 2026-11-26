import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/consent_models.dart';
import '../domain/consent_repository.dart';

/// Implementação sobre o Supabase. Identidade sempre pela sessão
/// (`auth.uid()` no servidor); a RLS e o trigger de transições decidem.
/// Traduz todas as exceções para [ConsentFailure].
class SupabaseConsentRepository implements ConsentRepository {
  SupabaseConsentRepository(this._client);

  final SupabaseClient _client;

  /// Colunas devolvidas depois de um UPDATE (o cliente tem SELECT nas suas).
  static const _returned =
      'id, status, consent_version, accepted_at, declined_at, withdrawn_at';

  @override
  Future<List<ConsentGrant>> myConsents() => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>('my_consents');
    return [
      for (final r in rows) ConsentGrant.fromRow(Map<String, dynamic>.from(r)),
    ];
  });

  @override
  Future<String> currentVersion() => _guard(() async {
    final v = await _client.rpc<dynamic>('current_consent_version');
    if (v is! String || v.isEmpty) {
      throw const ConsentFailure(ConsentFailureKind.notFound);
    }
    return v;
  });

  @override
  Future<ConsentText> text(String version) => _guard(() async {
    final row = await _client
        .from('consent_texts')
        .select('version, content')
        .eq('version', version)
        .maybeSingle();
    final content = row?['content'];
    if (row == null || content is! String) {
      throw const ConsentFailure(ConsentFailureKind.notFound);
    }
    return ConsentText(version: version, content: content);
  });

  @override
  Future<ConsentGrant> accept(ConsentGrant grant, {required String version}) =>
      _transition(
        grant,
        from: GrantStatus.pendente,
        to: GrantStatus.ativa,
        version: version,
      );

  @override
  Future<ConsentGrant> decline(ConsentGrant grant) =>
      _transition(grant, from: GrantStatus.pendente, to: GrantStatus.recusada);

  @override
  Future<ConsentGrant> withdraw(ConsentGrant grant) =>
      _transition(grant, from: GrantStatus.ativa, to: GrantStatus.retirada);

  /// UPDATE condicionado ao estado de partida: se outra sessão já respondeu,
  /// nenhuma linha muda e devolve `stateChanged` (nunca se sobrepõe).
  Future<ConsentGrant> _transition(
    ConsentGrant grant, {
    required GrantStatus from,
    required GrantStatus to,
    String? version,
  }) => _guard(() async {
    final rows = await _client
        .from('consent_grants')
        .update({'status': to.name, 'consent_version': ?version})
        .eq('id', grant.id)
        .eq('status', from.name)
        .select(_returned);
    if (rows.length != 1) {
      throw const ConsentFailure(ConsentFailureKind.stateChanged);
    }
    final updated = grant.withServerRow(rows.single);
    if (updated.status != to) {
      throw const ConsentFailure(ConsentFailureKind.stateChanged);
    }
    return updated;
  });

  @override
  Future<String> reaccept({
    required String officeId,
    required String version,
  }) => _guard(() async {
    final id = await _client.rpc<dynamic>(
      'reaccept_grant',
      params: {'p_office_id': officeId, 'p_version': version},
    );
    if (id is! String) throw const ConsentFailure(ConsentFailureKind.unknown);
    return id;
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ConsentFailure {
      rethrow;
    } on Object catch (e) {
      throw mapError(e);
    }
  }

  /// Classificação das falhas (pública para teste).
  static ConsentFailure mapError(Object e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // Permissão (RLS, trigger "só o titular") ou transição recusada.
        case '42501' || '23514' || '23505':
          return const ConsentFailure(ConsentFailureKind.stateChanged);
        // .single()/.maybeSingle() sem linha.
        case 'PGRST116':
          return const ConsentFailure(ConsentFailureKind.notFound);
      }
      return const ConsentFailure(ConsentFailureKind.unknown);
    }
    if (e is AuthException || e is FormatException || e is TypeError) {
      return const ConsentFailure(ConsentFailureKind.unknown);
    }
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const ConsentFailure(ConsentFailureKind.network);
  }
}
