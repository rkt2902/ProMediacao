// Tarefa 3 da 002: ficha do cliente (com o resultado da criação e o
// "Reenviar email"), pedido aberto e "Os meus pedidos".
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/requests/application/batch_email_controller.dart';
import 'package:promediacao/features/requests/application/client_file_controller.dart';
import 'package:promediacao/features/requests/application/created_batch.dart';
import 'package:promediacao/features/requests/application/my_requests_controller.dart';
import 'package:promediacao/features/requests/application/request_detail_controller.dart';
import 'package:promediacao/features/requests/application/requests_load.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import 'fake_requests_repository.dart';

void main() {
  late DateTime now;
  late AppConnectivity connectivity;

  setUp(() {
    now = DateTime.utc(2026, 11, 27, 10, 14);
    connectivity = AppConnectivity();
    addTearDown(connectivity.dispose);
  });

  CreatedBatch batch(BatchEmailStatus status, {DateTime? lock}) => CreatedBatch(
    batchId: 'b-1',
    clientId: 'c-maria',
    clientName: 'Maria',
    clientEmail: 'maria.figueiredo@exemplo.pt',
    requests: [
      CreatedRequest(
        requestId: 'r-new',
        batchId: 'b-1',
        typeCode: 'vida',
        typeName: 'Vida',
        createdAt: now,
      ),
    ],
    emailStatus: status,
    emailLockUntil: lock,
  );

  group('ficha do cliente', () {
    test('carrega cabeçalho e pedidos paginados (25 + "mais")', () async {
      final repo = FakeRequestsRepository();
      repo.officeRequests['c-maria'] = [
        for (var i = 0; i < 30; i++) officeRequest('r$i'),
      ];
      final c = ClientFileController(
        repo,
        FakeRequestEmailSender(),
        connectivity,
        CreatedRequestsHandoff(),
        clientId: 'c-maria',
      );
      addTearDown(c.dispose);
      await c.start();
      expect(c.header?.isActive, isTrue);
      expect(c.requests, hasLength(25));
      expect(c.hasMore, isTrue);
      expect(c.totalCount, 30);
      expect(c.openCount, 30);
      expect(c.created, isNull);
      expect(c.email, isNull);
      await c.loadMore();
      expect(c.requests, hasLength(30));
      expect(c.hasMore, isFalse);
    });

    test('sem acesso não revela nada', () async {
      final c = ClientFileController(
        FakeRequestsRepository(),
        FakeRequestEmailSender(),
        connectivity,
        CreatedRequestsHandoff(),
        clientId: 'c-outro',
      );
      addTearDown(c.dispose);
      await c.start();
      expect(c.noAccess, isTrue);
      expect(c.requests, isEmpty);
      expect(c.canCreate, isFalse);
    });

    test('vindo do Novo pedido com email enviado: aviso e realce, lido uma '
        'só vez', () async {
      final handoff = CreatedRequestsHandoff()
        ..put(
          batch(
            BatchEmailStatus.sent,
            lock: now.add(const Duration(seconds: 60)),
          ),
        );
      final c = ClientFileController(
        FakeRequestsRepository(),
        FakeRequestEmailSender(now: () => now),
        connectivity,
        handoff,
        clientId: 'c-maria',
        now: () => now,
      );
      addTearDown(c.dispose);
      expect(c.created?.count, 1);
      expect(c.highlightIds, {'r-new'});
      expect(c.email?.showResend, isFalse);
      expect(handoff.take('c-maria'), isNull);
    });

    test('US 4.4: email não enviado, reenviar, bloqueio de 60 s', () async {
      final sender = FakeRequestEmailSender(now: () => now);
      final c = ClientFileController(
        FakeRequestsRepository(),
        sender,
        connectivity,
        CreatedRequestsHandoff()..put(batch(BatchEmailStatus.notSent)),
        clientId: 'c-maria',
        now: () => now,
      );
      addTearDown(c.dispose);
      final email = c.email!;
      expect(c.highlightIds, isEmpty);
      expect(email.showResend, isTrue);
      expect(email.canResend, isTrue);

      sender.failure = const RequestFailure(RequestFailureKind.emailNotSent);
      await email.resend();
      expect(email.status, BatchEmailStatus.notSent);
      expect(email.lastError, RequestFailureKind.emailNotSent);
      expect(email.canResend, isTrue);

      sender.failure = null;
      await email.resend();
      expect(sender.calls, ['b-1', 'b-1']);
      expect(email.status, BatchEmailStatus.resent);
      expect(email.lockUntil, now.add(const Duration(seconds: 60)));
      expect(email.canResend, isFalse);
      await email.resend();
      expect(sender.calls, hasLength(2));

      now = now.add(const Duration(seconds: 61));
      expect(email.lockUntil, isNull);
      expect(email.canResend, isTrue);
    });

    test('reenviar: 429 bloqueia pelo tempo do servidor; 409 tira o '
        'reenviar; offline bloqueia', () async {
      final sender = FakeRequestEmailSender(now: () => now);
      final email = BatchEmailController(
        sender,
        connectivity,
        batchId: 'b-1',
        status: BatchEmailStatus.notSent,
        now: () => now,
      );
      addTearDown(email.dispose);
      sender.failure = const RequestFailure(
        RequestFailureKind.tooSoon,
        retryAfterSeconds: 30,
      );
      await email.resend();
      expect(email.lockUntil, now.add(const Duration(seconds: 30)));
      expect(email.status, BatchEmailStatus.notSent);

      now = now.add(const Duration(seconds: 31));
      sender.failure = const RequestFailure(RequestFailureKind.network);
      await email.resend();
      expect(connectivity.online, isFalse);
      expect(email.canResend, isFalse);
      connectivity.reportReachable();

      sender.failure = const RequestFailure(
        RequestFailureKind.clientNotAvailable,
      );
      await email.resend();
      expect(email.status, BatchEmailStatus.clientNotAvailable);
      expect(email.showResend, isFalse);
    });
  });

  group('pedido aberto', () {
    test('não encontrado, erro e pronto', () async {
      final repo = FakeRequestsRepository();
      final c = RequestDetailController(repo, connectivity, requestId: 'x');
      addTearDown(c.dispose);
      await c.start();
      expect(c.load, RequestDetailLoad.notFound);

      repo.failNext = const RequestFailure(RequestFailureKind.unknown);
      await c.start();
      expect(c.load, RequestDetailLoad.error);
    });
  });

  group('os meus pedidos', () {
    test(
      'grupos em curso e acesso retirado; contagem só dos em curso',
      () async {
        final repo = FakeRequestsRepository();
        repo.mine.addAll([
          myRequest('a'),
          myRequest('b'),
          myRequest('c', withdrawn: true),
        ]);
        final c = MyRequestsController(repo, connectivity);
        addTearDown(c.dispose);
        await c.start();
        expect(c.load, RequestsLoad.ready);
        expect(c.active.map((r) => r.id), ['a', 'b']);
        expect(c.withdrawn.single.accessWithdrawn, isTrue);
        expect(c.openCount, 2);
      },
    );

    test('vazio, e falha ao recarregar não apaga o que está no ecrã', () async {
      final repo = FakeRequestsRepository();
      final c = MyRequestsController(repo, connectivity);
      addTearDown(c.dispose);
      await c.start();
      expect(c.isEmpty, isTrue);

      repo.mine.add(myRequest('a'));
      await c.start();
      repo.failNext = const RequestFailure(RequestFailureKind.network);
      await c.start();
      expect(c.load, RequestsLoad.ready);
      expect(c.items, hasLength(1));
      expect(connectivity.online, isFalse);
    });
  });
}
