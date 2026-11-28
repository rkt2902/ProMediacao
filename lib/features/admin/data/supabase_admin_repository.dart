import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

/// Implementação sobre o Supabase. Só lê o que a RLS dá ao admin:
/// `admin_counts()`, `offices` (id, nome) e `office_members.office_id`
/// (só ids, para contar). Nunca toca em `profiles`.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AdminCounts> loadCounts() async {
    try {
      final rows = await _client.rpc('admin_counts');
      if (rows is! List || rows.isEmpty) {
        throw const AdminFailure(AdminFailureKind.forbidden);
      }
      final row = rows.first as Map;
      return AdminCounts(
        offices: _int(row['offices']),
        mediators: _int(row['mediators']),
        clients: _int(row['clients']),
        requests: _int(row['requests']),
      );
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<List<OfficeSummary>> loadOffices() async {
    try {
      final offices = await _client
          .from('offices')
          .select('id, name')
          .order('created_at', ascending: false);
      final members = await _client.from('office_members').select('office_id');
      final perOffice = <String, int>{};
      for (final m in members) {
        final id = m['office_id'] as String;
        perOffice[id] = (perOffice[id] ?? 0) + 1;
      }
      return [
        for (final o in offices)
          OfficeSummary(
            id: o['id'] as String,
            name: o['name'] as String,
            mediatorCount: perOffice[o['id']] ?? 0,
          ),
      ];
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<OfficeSummary> createOffice(String name) async {
    try {
      final row = await _client
          .from('offices')
          .insert({'name': name})
          .select('id, name')
          .single();
      return OfficeSummary(
        id: row['id'] as String,
        name: row['name'] as String,
      );
    } on Object catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> inviteMediator({
    required String officeId,
    required String email,
    required String fullName,
  }) async {
    try {
      // O cliente do Supabase envia a sessão do admin (JWT) no pedido.
      await _client.functions.invoke(
        'invite-mediator',
        body: {'email': email, 'office_id': officeId, 'full_name': fullName},
      );
    } on Object catch (e) {
      throw _map(e);
    }
  }

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  AdminFailure _map(Object e) {
    if (e is AdminFailure) return e;
    if (e is FunctionException) {
      final details = e.details;
      final code = details is Map && details['error'] is Map
          ? (details['error'] as Map)['code']
          : null;
      return AdminFailure(switch (code) {
        'cannot_invite' => AdminFailureKind.cannotInvite,
        'send_failed' => AdminFailureKind.sendFailed,
        'forbidden' => AdminFailureKind.forbidden,
        _ => AdminFailureKind.unknown,
      });
    }
    if (e is PostgrestException) {
      return AdminFailure(switch (e.code) {
        '23505' => AdminFailureKind.duplicateName,
        '42501' => AdminFailureKind.forbidden,
        _ => AdminFailureKind.unknown,
      });
    }
    if (e is AuthException) return const AdminFailure(AdminFailureKind.unknown);
    // ClientException, SocketException, TimeoutException...: sem rede.
    return const AdminFailure(AdminFailureKind.network);
  }
}
