import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/features/consent/data/supabase_consent_repository.dart';
import 'package:promediacao/features/consent/domain/consent_models.dart';
import 'package:promediacao/features/consent/presentation/consent_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('linha de my_consents()', () {
    final g = ConsentGrant.fromRow({
      'grant_id': 'g1',
      'office_id': 'o1',
      'office_name': 'Ribeira Seguros',
      'mediator_name': null,
      'status': 'ativa',
      'consent_version': 'v0-rascunho',
      'created_at': '2026-11-10T09:00:00+00:00',
      'accepted_at': '2026-11-12T10:04:00+00:00',
      'declined_at': null,
      'withdrawn_at': null,
    });
    expect(g.status, GrantStatus.ativa);
    expect(g.mediatorName, isNull);
    expect(g.statusAt, DateTime.utc(2026, 11, 12, 10, 4));
  });

  test('estado desconhecido nunca é interpretado', () {
    expect(
      () => ConsentGrant.fromRow({
        'grant_id': 'g1',
        'office_id': 'o1',
        'office_name': 'X',
        'status': 'aceite',
        'consent_version': 'v0',
        'created_at': '2026-11-10T09:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('resposta do UPDATE de outra linha é recusada', () {
    final g = ConsentGrant(
      id: 'g1',
      officeId: 'o1',
      officeName: 'X',
      status: GrantStatus.pendente,
      consentVersion: 'v0',
      createdAt: DateTime.utc(2026),
    );
    expect(
      () => g.withServerRow({'id': 'g2', 'status': 'ativa'}),
      throwsFormatException,
    );
    final ok = g.withServerRow({
      'id': 'g1',
      'status': 'recusada',
      'consent_version': 'v0',
      'declined_at': '2026-11-26T14:32:00Z',
    });
    expect(ok.status, GrantStatus.recusada);
    expect(ok.statusAt, DateTime.utc(2026, 11, 26, 14, 32));
  });

  test('classificação das falhas do servidor', () {
    ConsentFailureKind k(Object e) =>
        SupabaseConsentRepository.mapError(e).kind;
    expect(
      k(const PostgrestException(message: 'x', code: '42501')),
      ConsentFailureKind.stateChanged,
    );
    expect(
      k(const PostgrestException(message: 'x', code: '23514')),
      ConsentFailureKind.stateChanged,
    );
    expect(
      k(const PostgrestException(message: 'x', code: 'PGRST301')),
      ConsentFailureKind.unknown,
    );
    expect(k(Exception('socket')), ConsentFailureKind.network);
  });

  test('parágrafos do texto e nome do escritório', () {
    expect(
      ConsentTextView.paragraphs('Um {escritório}.\n\n  Dois\r\n\r\nTrês', 'A'),
      ['Um A.', 'Dois', 'Três'],
    );
  });
}
