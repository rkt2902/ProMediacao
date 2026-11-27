// QA 002 (tarefa 6): casos-limite do Novo pedido que faltavam nos testes das
// tarefas 3 e 4. Espelham supabase/tests/002b_edge_cases.sql do lado da app:
// 13 tipos, mensagem contada em code points (emojis e famílias ZWJ), item
// livre como o servidor o valida, repetido devolvido pelo servidor sem a app o
// saber, e duplo "Criar".
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/requests/application/created_batch.dart';
import 'package:promediacao/features/requests/application/new_request_controller.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import 'fake_requests_repository.dart';

final _now = DateTime.utc(2026, 11, 27, 10, 14);

/// Os 13 códigos do catálogo real (seed da migração 002), cada um com 1 item.
const _codes = [
  'vida',
  'vida_habitacao',
  'doencas_graves',
  'multirriscos_habitacao',
  'multirriscos_negocio',
  'saude',
  'acidentes_pessoais',
  'automovel',
  'acidentes_trabalho_fixo',
  'acidentes_trabalho_variavel',
  'pets',
  'responsabilidade_civil',
  'obras',
];

List<InsuranceType> _catalog13() => [
  for (final (i, code) in _codes.indexed)
    InsuranceType(
      code: code,
      name: 'Tipo ${i + 1}',
      sortOrder: i + 1,
      items: [
        CatalogItem(
          id: 'i-$code-1',
          position: 1,
          kind: ItemKind.document,
          label: 'Cartão de Cidadão',
        ),
      ],
    ),
];

class _Setup {
  _Setup({FakeRequestsRepository? repo})
    : repo = repo ?? FakeRequestsRepository(),
      email = FakeRequestEmailSender(
        recipientEmail: FakeRequestsRepository.maria.email,
        now: () => _now,
      ),
      connectivity = AppConnectivity(),
      handoff = CreatedRequestsHandoff() {
    controller = NewRequestController(
      this.repo,
      email,
      connectivity,
      handoff,
      preselectedClientId: 'c-maria',
      now: () => _now,
    );
    addTearDown(controller.dispose);
    addTearDown(connectivity.dispose);
  }

  final FakeRequestsRepository repo;
  final FakeRequestEmailSender email;
  final AppConnectivity connectivity;
  final CreatedRequestsHandoff handoff;
  late final NewRequestController controller;
}

const _family = '\u{1F468}‍\u{1F469}‍\u{1F467}'; // 5 code points

void main() {
  test('US 1.2: os 13 tipos de uma vez vão numa só chamada, pela ordem do '
      'catálogo, com a mesma mensagem e condições', () async {
    final s = _Setup(repo: FakeRequestsRepository(catalog: _catalog13()));
    await s.controller.start();
    await pumpEventQueue();
    final c = s.controller;
    for (final code in _codes.reversed) {
      c.toggleType(code);
    }
    c
      ..allowPolicyConditions = true
      ..message = 'Bom dia 👋';
    expect(c.typesToCreate.length, 13);
    expect(c.block, isNull);

    final batch = await c.submit();

    expect(batch, isNotNull);
    expect(batch!.requests.length, 13);
    final call = s.repo.createCalls.single;
    expect(call.requests.map((r) => r.typeCode), _codes);
    expect(call.allowPolicyConditions, isTrue);
    expect(call.message, 'Bom dia 👋');
    expect(call.requests.every((r) => r.confirmRepeat == false), isTrue);
  });

  group('US 1.6: mensagem contada como o servidor (code points)', () {
    test('500 emojis passa; 501 bloqueia', () async {
      final s = _Setup();
      await s.controller.start();
      await pumpEventQueue();
      final c = s.controller..toggleType('vida');
      c.message = '😀' * 500;
      expect(c.messageLength, 500);
      expect(c.block, isNull);
      c.message = '😀' * 501;
      expect(c.block, SubmitBlock.messageTooLong);
    });

    test('100 famílias ZWJ (500 code points) passa; 101 bloqueia, apesar de '
        'serem só 101 caracteres visíveis', () async {
      final s = _Setup();
      await s.controller.start();
      await pumpEventQueue();
      final c = s.controller..toggleType('vida');
      c.message = _family * 100;
      expect(c.messageLength, 500);
      expect(c.block, isNull);
      c.message = _family * 101;
      expect(c.messageLength, 505);
      expect(c.block, SubmitBlock.messageTooLong);
    });

    test('só espaços e quebras de linha conta 0', () async {
      final s = _Setup();
      await s.controller.start();
      await pumpEventQueue();
      final c = s.controller..message = '  \n\t ';
      expect(c.messageLength, 0);
    });
  });

  group('US 1.4: item livre validado como o servidor', () {
    test('200 emojis passa; 201 é longo; < > tab recusados', () {
      expect(NewRequestController.validateFreeItem('🚗' * 200), isNull);
      expect(
        NewRequestController.validateFreeItem('🚗' * 201),
        FreeItemError.tooLong,
      );
      expect(
        NewRequestController.validateFreeItem('Fotos < 3'),
        FreeItemError.invalidCharacters,
      );
      expect(
        NewRequestController.validateFreeItem('a > b'),
        FreeItemError.invalidCharacters,
      );
      expect(
        NewRequestController.validateFreeItem('Fotos\tdo carro'),
        FreeItemError.invalidCharacters,
      );
      expect(NewRequestController.validateFreeItem('   '), FreeItemError.empty);
    });

    test(
      'carateres de controlo C1 (U+0080 a U+009F) recusados, como o '
      '[[:cntrl:]] do servidor ao vivo',
      () {
        expect(
          NewRequestController.validateFreeItem('Fotos\u0085do carro'),
          FreeItemError.invalidCharacters,
        );
      },
      skip:
          'Bug 1 do 05-qa.md da 002: a app aceita U+0080..U+009F e o '
          'servidor recusa (invalid_item, "Não foi possível criar")',
    );

    test('espaços nas pontas aparados e & " \' guardados tal como estão; '
        'o 61.º item é recusado', () async {
      final s = _Setup();
      await s.controller.start();
      await pumpEventQueue();
      final c = s.controller..toggleType('vida');
      expect(
        c.addFreeItem('vida', ItemKind.data, '  Recibos & "outros" \'x\'  '),
        isNull,
      );
      expect(c.lines('vida').last.label, 'Recibos & "outros" \'x\'');
      // vida tem 1 item do catálogo + 1 livre; até 60
      for (var i = 0; i < 58; i++) {
        expect(c.addFreeItem('vida', ItemKind.document, 'Item $i'), isNull);
      }
      expect(c.lines('vida').length, 60);
      expect(
        c.addFreeItem('vida', ItemKind.document, 'Item 61'),
        FreeItemError.tooMany,
      );
    });
  });

  test('US 1.8: repetido que a app não conhecia (tipos em curso falharam a '
      'carregar): nada criado, só esse tipo pede confirmação e os outros '
      'podem ser criados sem ele', () async {
    final s = _Setup();
    await s.controller.start();
    await pumpEventQueue();
    final c = s.controller
      ..toggleType('vida')
      ..toggleType('automovel');
    s.repo.createFailure = const RequestFailure(
      RequestFailureKind.repeatedRequest,
      typeCodes: ['vida'],
    );

    expect(await c.submit(), isNull);
    expect(c.created, isNull);
    expect(c.needsConfirmation('vida'), isTrue);
    expect(c.typesToCreate.map((t) => t.code), ['automovel']);

    s.repo.createFailure = null;
    final batch = await c.submit();
    expect(batch, isNotNull);
    expect(s.repo.createCalls.length, 2);
    expect(s.repo.createCalls.last.requests.map((r) => r.typeCode), [
      'automovel',
    ]);
  });

  test('duplo "Criar" (dois toques antes da resposta) só chama o servidor '
      'uma vez; depois do sucesso já não volta a criar', () async {
    final s = _Setup();
    await s.controller.start();
    await pumpEventQueue();
    final c = s.controller..toggleType('vida');
    s.repo.gate = Completer<void>();
    final first = c.submit();
    final second = c.submit();
    expect(c.submitting, isTrue);
    expect(c.canSubmit, isFalse);
    s.repo.gate!.complete();
    s.repo.gate = null;
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(await c.submit(), isNull);
    expect(s.repo.createCalls.length, 1);
  });
}
