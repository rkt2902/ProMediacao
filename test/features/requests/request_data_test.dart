// Tarefa 3 da 002: leitura das linhas das RPC e classificação dos erros
// (pelo código estável em `message`, nunca mostrado ao utilizador).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/features/requests/data/supabase_request_email_sender.dart';
import 'package:promediacao/features/requests/data/supabase_requests_repository.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

RequestFailure _pg(String message, {String? code, Object? details}) =>
    SupabaseRequestsRepository.mapError(
      PostgrestException(message: message, code: code, details: details),
    );

RequestFailure _fn(int status, [Map<String, dynamic>? error]) =>
    SupabaseRequestEmailSender.mapError(
      FunctionException(
        status: status,
        details: error == null ? 'Not Found' : {'error': error},
      ),
    );

void main() {
  group('modelos', () {
    test('catálogo: itens por posição, nota vazia passa a nula', () {
      final t = InsuranceType.fromRow({
        'code': 'automovel',
        'name': 'Automóvel',
        'note': '  ',
        'sort_order': 8,
        'items': [
          {'id': 'b', 'position': 2, 'kind': 'I', 'label': 'Data da carta'},
          {'id': 'a', 'position': 1, 'kind': 'D', 'label': 'CC'},
        ],
      });
      expect(t.note, isNull);
      expect(t.sortOrder, 8);
      expect([for (final i in t.items) i.id], ['a', 'b']);
      expect(t.items.first.kind, ItemKind.document);
      expect(t.items.last.kind, ItemKind.data);
    });

    test('item com natureza desconhecida é recusado', () {
      expect(
        () => CatalogItem.fromJson({'id': 'x', 'kind': 'X', 'label': 'y'}),
        throwsFormatException,
      );
    });

    test('detalhe do cliente com acesso retirado e etapas', () {
      final d = RequestDetail.fromRow({
        'request_id': 'r1',
        'client_id': 'c1',
        'client_name': 'Maria',
        'office_id': 'o1',
        'office_name': 'Ribeira Seguros',
        'type_code': 'vida',
        'type_name': 'Vida',
        'type_note': null,
        'origin': 'mediador',
        'stage': 1,
        'allow_policy_conditions': true,
        'message': 'Bom dia',
        'author_name': 'Ana Martins',
        'created_at': '2026-11-27T10:14:00Z',
        'documents_sent_at': null,
        'review_started_at': null,
        'sent_to_insurers_at': null,
        'access_withdrawn': true,
        'access_withdrawn_at': '2026-11-26T15:02:00Z',
        'items': [
          {
            'id': 'i2',
            'position': 2,
            'kind': 'I',
            'label': 'Profissão',
            'source': 'livre',
          },
          {
            'id': 'i1',
            'position': 1,
            'kind': 'D',
            'label': 'CC',
            'source': 'catalogo',
          },
        ],
      });
      expect(d.stage, RequestStage.created);
      expect(d.accessWithdrawn, isTrue);
      expect(d.allowPolicyConditions, isTrue);
      expect([for (final i in d.items) i.id], ['i1', 'i2']);
      expect(d.items.last.source, ItemSource.free);
      expect(d.documentCount, 1);
      expect(d.dataCount, 1);
      expect(d.stageDates.whereType<DateTime>().length, 1);
    });

    test('linha da ficha e de "Os meus pedidos"', () {
      final r = OfficeRequest.fromRow({
        'request_id': 'r1',
        'type_code': 'automovel',
        'type_name': 'Automóvel',
        'stage': 1,
        'origin': 'mediador',
        'allow_policy_conditions': false,
        'created_at': '2026-11-27T10:14:00Z',
        'author_name': 'Ana Martins',
        'document_count': 4,
        'data_count': 2,
        'total_count': 3,
        'open_count': 3,
      });
      expect(r.documentCount, 4);
      expect(r.stage.isOpen, isTrue);
      final m = MyRequest.fromRow({
        'request_id': 'r2',
        'type_code': 'vida',
        'type_name': 'Vida',
        'office_id': 'o1',
        'office_name': 'Ribeira',
        'stage': 4,
        'origin': 'mediador',
        'allow_policy_conditions': false,
        'created_at': '2026-11-27T10:14:00Z',
        'document_count': 1,
        'data_count': 0,
        'access_withdrawn': false,
      });
      expect(m.stage, RequestStage.sentToInsurers);
      expect(m.stage.isOpen, isFalse);
    });

    test('pedido para criar: catálogo só com o id, livre com natureza', () {
      const draft = RequestDraft(
        typeCode: 'automovel',
        confirmRepeat: true,
        items: [
          CatalogDraftItem('i-1'),
          FreeDraftItem(kind: ItemKind.data, label: 'Fotografias'),
        ],
      );
      expect(draft.toJson(), {
        'type_code': 'automovel',
        'confirm_repeat': true,
        'items': [
          {'catalog_item_id': 'i-1'},
          {'kind': 'I', 'label': 'Fotografias'},
        ],
      });
    });
  });

  group('erros das RPC', () {
    test('códigos estáveis do contrato', () {
      expect(_pg('not_authorized').kind, RequestFailureKind.notAuthorized);
      expect(
        _pg('client_not_available', code: '42501').kind,
        RequestFailureKind.clientNotAvailable,
      );
      expect(_pg('message_too_long').kind, RequestFailureKind.messageTooLong);
      expect(_pg('not_found').kind, RequestFailureKind.notFound);
    });

    test('repetido traz os type_codes de details', () {
      final f = _pg(
        'repeated_request',
        code: 'P0001',
        details: 'automovel, vida',
      );
      expect(f.kind, RequestFailureKind.repeatedRequest);
      expect(f.typeCodes, ['automovel', 'vida']);
    });

    test('lista vazia e item inválido dizem o tipo', () {
      expect(_pg('empty_list', details: 'vida').typeCodes, ['vida']);
      final f = _pg('invalid_item', details: 'automovel');
      expect(f.kind, RequestFailureKind.invalidItem);
      expect(f.typeCodes, ['automovel']);
      expect(_pg('invalid_input').typeCodes, isEmpty);
    });

    test('mensagem desconhecida nunca passa: genérico', () {
      expect(
        _pg('permission denied for table requests', code: '42501').kind,
        RequestFailureKind.notAuthorized,
      );
      expect(
        _pg('qualquer coisa', code: 'XX000').kind,
        RequestFailureKind.unknown,
      );
    });

    test('sem rede', () {
      expect(
        SupabaseRequestsRepository.mapError(
          const SocketException('offline'),
        ).kind,
        RequestFailureKind.network,
      );
    });
  });

  group('erros do email (send-request-email)', () {
    test('503 email_unavailable e 404 (por publicar) = email não enviado', () {
      expect(
        _fn(503, {'code': 'email_unavailable'}).kind,
        RequestFailureKind.emailNotSent,
      );
      expect(_fn(404).kind, RequestFailureKind.emailNotSent);
      expect(
        _fn(404, {'code': 'not_found'}).kind,
        RequestFailureKind.emailNotSent,
      );
      expect(
        _fn(500, {'code': 'server_error'}).kind,
        RequestFailureKind.emailNotSent,
      );
    });

    test('502 send_failed pede espera', () {
      final f = _fn(502, {'code': 'send_failed', 'retry_after_seconds': 60});
      expect(f.kind, RequestFailureKind.emailNotSent);
      expect(f.retryAfterSeconds, 60);
    });

    test('429 too_soon com a espera', () {
      final f = _fn(429, {'code': 'too_soon', 'retry_after_seconds': 42});
      expect(f.kind, RequestFailureKind.tooSoon);
      expect(f.retryAfterSeconds, 42);
    });

    test('409 concessão perdida; 401/403/400 genéricos', () {
      expect(
        _fn(409, {'code': 'client_not_available'}).kind,
        RequestFailureKind.clientNotAvailable,
      );
      expect(
        _fn(403, {'code': 'forbidden'}).kind,
        RequestFailureKind.notAuthorized,
      );
      expect(
        _fn(401, {'code': 'unauthenticated'}).kind,
        RequestFailureKind.notAuthorized,
      );
      expect(
        _fn(400, {'code': 'invalid_input'}).kind,
        RequestFailureKind.unknown,
      );
    });
  });
}
