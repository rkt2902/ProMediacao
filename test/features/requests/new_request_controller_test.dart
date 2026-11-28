// Tarefa 3 da 002: estado do Novo pedido (US 1.1 a 1.8, 2.1, 4.4) com o
// repositório e o email falsos.
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/requests/application/batch_email_controller.dart';
import 'package:promediacao/features/requests/application/created_batch.dart';
import 'package:promediacao/features/requests/application/new_request_controller.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import 'fake_requests_repository.dart';

final _now = DateTime.utc(2026, 11, 27, 10, 14);

class _Setup {
  _Setup({String? clientId, FakeRequestsRepository? repo})
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
      preselectedClientId: clientId,
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

void main() {
  test('sem cliente pré-escolhido: carrega o catálogo e os clientes '
      'ativos; pesquisa por nome ou email', () async {
    final s = _Setup();
    await s.controller.start();
    final c = s.controller;
    expect(c.catalogLoad, RequestsLoad.ready);
    expect(c.clientsLoad, RequestsLoad.ready);
    expect(c.client, isNull);
    expect(c.block, SubmitBlock.chooseClientAndType);
    c.setQuery('LIMA');
    expect(c.matches.single.clientId, 'c-joao');
    c.setQuery('figueiredo@');
    expect(c.matches.single.clientId, 'c-maria');
  });

  test('cliente pré-escolhido ativo fica escolhido e lê os tipos em '
      'curso', () async {
    final s = _Setup(clientId: 'c-maria');
    s.repo.openTypes['c-maria'] = [
      OpenType(
        typeCode: 'vida',
        typeName: 'Vida',
        openCount: 1,
        firstCreatedAt: DateTime.utc(2026, 11, 20),
        lastCreatedAt: DateTime.utc(2026, 11, 20),
        maxStage: RequestStage.created,
      ),
    ];
    await s.controller.start();
    await pumpEventQueue();
    final c = s.controller;
    expect(c.client?.clientId, 'c-maria');
    expect(c.clientsLoad, isNull);
    expect(c.isOpen('vida'), isTrue);
    expect(c.openTypeFor('vida')!.firstCreatedAt, DateTime.utc(2026, 11, 20));
    expect(c.isOpen('automovel'), isFalse);
  });

  test('US 2.1: cliente pré-escolhido pendente mostra o motivo e bloqueia '
      'criar', () async {
    final repo = FakeRequestsRepository(
      headers: {
        'c-p': const ClientHeader(
          clientId: 'c-p',
          access: ClientAccess.pending,
          grantId: 'g-p',
        ),
      },
    );
    final s = _Setup(clientId: 'c-p', repo: repo);
    await s.controller.start();
    expect(s.controller.client, isNull);
    expect(s.controller.unavailableClient?.access, ClientAccess.pending);
    s.controller.toggleType('automovel');
    expect(s.controller.block, SubmitBlock.clientUnavailable);

    final other = _Setup(clientId: 'c-de-outro-escritorio');
    await other.controller.start();
    expect(
      other.controller.unavailableClient?.access,
      ClientAccess.unavailable,
    );
  });

  test('US 1.3 e 1.4: lista do catálogo, tirar, repor e acrescentar itens '
      'livres; lista vazia bloqueia', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    final c = s.controller..toggleType('vida');
    expect(c.lines('vida').single.label, 'Cartão de Cidadão');

    c.removeLine('vida', c.lines('vida').single.key);
    expect(c.isEmptyList('vida'), isTrue);
    expect(c.removedCount('vida'), 1);
    expect(c.block, SubmitBlock.emptyList);
    expect(c.blockedType?.code, 'vida');

    c.restoreList('vida');
    expect(c.lines('vida'), hasLength(1));
    expect(c.block, isNull);

    expect(c.addFreeItem('vida', ItemKind.data, '   '), FreeItemError.empty);
    expect(
      c.addFreeItem('vida', ItemKind.data, 'Peso <b>'),
      FreeItemError.invalidCharacters,
    );
    expect(
      c.addFreeItem('vida', ItemKind.data, 'x' * 201),
      FreeItemError.tooLong,
    );
    expect(c.addFreeItem('vida', ItemKind.data, ' Profissão '), isNull);
    final free = c.lines('vida').last;
    expect(free.isFree, isTrue);
    expect(free.label, 'Profissão');
    c.removeLine('vida', free.key);
    expect(c.lines('vida'), hasLength(1));
    expect(c.removedCount('vida'), 0);
  });

  test('US 1.6: mensagem até 500 caracteres (aparada)', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    final c = s.controller..toggleType('vida');
    c.message = '${'a' * 500}   ';
    expect(c.messageLength, 500);
    expect(c.block, isNull);
    c.message = 'a' * 501;
    expect(c.block, SubmitBlock.messageTooLong);
  });

  test('US 1.2, 1.5 e 1.7: cria N pedidos com a lista editada, envia o '
      'email e deixa o resultado no handoff', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    final c = s.controller
      ..toggleType('vida')
      ..toggleType('automovel')
      ..allowPolicyConditions = true
      ..message = '  Bom dia  ';
    c.removeLine('automovel', 'c:i-auto-2');
    c.addFreeItem('automovel', ItemKind.document, 'Fotografias do veículo');

    expect(c.typesToCreate.map((t) => t.code), ['automovel', 'vida']);
    final batch = await c.submit();

    expect(batch, isNotNull);
    final call = s.repo.createCalls.single;
    expect(call.clientId, 'c-maria');
    expect(call.allowPolicyConditions, isTrue);
    expect(call.message, '  Bom dia  ');
    expect(call.requests.map((r) => r.typeCode), ['automovel', 'vida']);
    expect(call.requests.first.items.map((i) => i.toJson()), [
      {'catalog_item_id': 'i-auto-1'},
      {'catalog_item_id': 'i-auto-3'},
      {'kind': 'D', 'label': 'Fotografias do veículo'},
    ]);
    expect(s.email.calls, ['b-1']);
    expect(batch!.emailStatus, BatchEmailStatus.sent);
    expect(batch.emailLockUntil, _now.add(const Duration(seconds: 60)));
    expect(batch.typeNames, ['Automóvel', 'Vida']);
    expect(s.handoff.take('c-maria'), same(batch));
    // Depois do sucesso não volta a criar.
    expect(c.canSubmit, isFalse);
    expect(await c.submit(), isNull);
    expect(s.repo.createCalls, hasLength(1));
  });

  test('US 4.4: email não enviado (503 / função por publicar) não desfaz '
      'os pedidos', () async {
    final s = _Setup(clientId: 'c-maria');
    s.email.failure = const RequestFailure(RequestFailureKind.emailNotSent);
    await s.controller.start();
    s.controller.toggleType('vida');
    final batch = await s.controller.submit();
    expect(batch?.emailStatus, BatchEmailStatus.notSent);
    expect(batch?.emailLockUntil, isNull);
    expect(s.controller.error, isNull);
    expect(s.handoff.take('c-maria'), isNotNull);
  });

  test('US 1.8: repetido sem confirmação não conta; o servidor também o '
      'recusa e nada é criado', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    final c = s.controller..toggleType('vida');
    // O servidor sabe de um pedido em curso que a app não leu.
    s.repo.createFailure = const RequestFailure(
      RequestFailureKind.repeatedRequest,
      typeCodes: ['vida'],
    );
    expect(await c.submit(), isNull);
    expect(c.error?.kind, RequestFailureKind.repeatedRequest);
    expect(c.needsConfirmation('vida'), isTrue);
    expect(c.block, SubmitBlock.awaitingConfirmation);
    expect(s.handoff.take('c-maria'), isNull);

    c.confirmRepeat('vida');
    expect(c.repeatConfirmed('vida'), isTrue);
    expect(c.error, isNull);
    s.repo.createFailure = null;
    final batch = await c.submit();
    expect(batch, isNotNull);
    expect(s.repo.createCalls.last.requests.single.confirmRepeat, isTrue);
  });

  test(
    'tipo em curso por confirmar sai da contagem; os outros criam-se',
    () async {
      final s = _Setup(clientId: 'c-maria');
      s.repo.openTypes['c-maria'] = [
        OpenType(
          typeCode: 'vida',
          typeName: 'Vida',
          openCount: 1,
          firstCreatedAt: _now,
          lastCreatedAt: _now,
          maxStage: RequestStage.created,
        ),
      ];
      await s.controller.start();
      await pumpEventQueue();
      final c = s.controller
        ..toggleType('vida')
        ..toggleType('automovel');
      expect(c.typesToCreate.map((t) => t.code), ['automovel']);
      expect(c.typesAwaitingConfirmation.map((t) => t.code), ['vida']);
      await c.submit();
      expect(s.repo.createCalls.single.requests.map((r) => r.typeCode), [
        'automovel',
      ]);
    },
  );

  test('concessão perdida entre abrir e criar: bloqueia e nada é '
      'criado', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    s.controller.toggleType('vida');
    s.repo.createFailure = const RequestFailure(
      RequestFailureKind.clientNotAvailable,
    );
    expect(await s.controller.submit(), isNull);
    expect(s.controller.clientLost, isTrue);
    expect(s.controller.block, SubmitBlock.clientUnavailable);
    expect(s.email.calls, isEmpty);
  });

  test('offline: falha ao criar mantém a escolha e bloqueia até a ligação '
      'voltar', () async {
    final s = _Setup(clientId: 'c-maria');
    await s.controller.start();
    s.controller
      ..toggleType('vida')
      ..message = 'Olá';
    s.repo.createFailure = const RequestFailure(RequestFailureKind.network);
    expect(await s.controller.submit(), isNull);
    expect(s.connectivity.online, isFalse);
    expect(s.controller.block, SubmitBlock.offline);
    expect(s.controller.isSelected('vida'), isTrue);
    expect(s.controller.message, 'Olá');

    s.repo.createFailure = null;
    s.connectivity.reportReachable();
    await pumpEventQueue();
    expect(s.controller.block, isNull);
    expect(await s.controller.submit(), isNotNull);
  });

  test('falha do catálogo: erro e "Tentar de novo"', () async {
    final s = _Setup(clientId: 'c-maria');
    s.repo.failNext = const RequestFailure(RequestFailureKind.unknown);
    await s.controller.loadCatalog();
    expect(s.controller.catalogLoad, RequestsLoad.error);
    await s.controller.retry();
    expect(s.controller.catalogLoad, RequestsLoad.ready);
  });
}
