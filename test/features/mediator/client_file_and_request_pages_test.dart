import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/mediator/presentation/client_file_page.dart';
import 'package:promediacao/features/mediator/presentation/mediator_request_page.dart';
import 'package:promediacao/features/requests/application/batch_email_controller.dart';
import 'package:promediacao/features/requests/application/created_batch.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../auth/auth_test_helpers.dart';
import '../requests/fake_requests_repository.dart';
import 'request_test_helpers.dart';

const _file = ClientFilePage(clientId: 'c-maria');

FakeRequestsRepository _repoWithRequests() {
  final repo = FakeRequestsRepository();
  repo.officeRequests['c-maria'] = [
    OfficeRequest(
      id: 'r-auto',
      typeCode: 'automovel',
      typeName: 'Automóvel',
      stage: RequestStage.created,
      origin: RequestOrigin.mediador,
      allowPolicyConditions: true,
      createdAt: DateTime(2026, 11, 27, 10, 14),
      documentCount: 2,
      dataCount: 1,
      authorName: 'Ana Martins',
    ),
    OfficeRequest(
      id: 'r-vida',
      typeCode: 'vida',
      typeName: 'Vida',
      stage: RequestStage.created,
      origin: RequestOrigin.mediador,
      allowPolicyConditions: false,
      createdAt: DateTime(2026, 11, 20, 16, 40),
      documentCount: 1,
      dataCount: 0,
      authorName: 'Ana Martins',
    ),
  ];
  return repo;
}

CreatedBatch _batch(BatchEmailStatus status, {DateTime? lock}) => CreatedBatch(
  batchId: 'b-1',
  clientId: 'c-maria',
  clientName: 'Maria do Carmo Figueiredo',
  clientEmail: 'maria.figueiredo@exemplo.pt',
  requests: [
    for (final (i, t) in ['Automóvel', 'Vida'].indexed)
      CreatedRequest(
        requestId: i == 0 ? 'r-auto' : 'r-vida',
        batchId: 'b-1',
        typeCode: t.toLowerCase(),
        typeName: t,
        createdAt: DateTime(2026, 11, 27, 10, 14),
      ),
  ],
  emailStatus: status,
  emailLockUntil: lock,
);

void main() {
  group('ficha do cliente', () {
    for (final e in testSizes.entries) {
      testWidgets('populado, ${e.key}', (tester) async {
        final h = await pumpPage(
          tester,
          _file,
          repo: _repoWithRequests(),
          size: e.value,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Maria do Carmo Figueiredo'), findsOneWidget);
        expect(find.text('maria.figueiredo@exemplo.pt'), findsOneWidget);
        expect(find.text('ATIVO'), findsOneWidget);
        expect(find.text('Desde 12 nov 2026, 10:04'), findsOneWidget);
        expect(find.text('Pedidos deste escritório'), findsOneWidget);
        expect(find.text('2 em curso'), findsOneWidget);
        expect(find.text('Condições particulares'), findsOneWidget);
        expect(find.text('Mediador · Ana Martins'), findsNWidgets(2));
        expect(find.text('Novo pedido'), findsOneWidget);
        if (e.key == 'desktop') {
          expect(find.text('Etapa'), findsOneWidget);
        }
        // O nome do tipo abre o pedido.
        await tester.ensureVisible(find.text('Automóvel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Automóvel'));
        await tester.pumpAndSettle();
        expect(h.location, '/mediador/clientes/c-maria/pedidos/r-auto');
      });
    }

    testWidgets('"Novo pedido" vai para o Novo pedido com o cliente', (
      tester,
    ) async {
      final h = await pumpPage(tester, _file, repo: _repoWithRequests());
      await tester.tap(find.text('Novo pedido'));
      await tester.pumpAndSettle();
      expect(h.location, '/mediador/clientes/c-maria/novo-pedido');
    });

    testWidgets('sem pedidos: uma só ação "Novo pedido"', (tester) async {
      await pumpPage(tester, _file);
      expect(find.text('Sem pedidos'), findsOneWidget);
      expect(find.textContaining('Crie o primeiro pedido'), findsOneWidget);
      expect(find.text('Novo pedido'), findsOneWidget);
    });

    testWidgets('a carregar e erro com "Tentar de novo"', (tester) async {
      final repo = _repoWithRequests();
      final gate = Completer<void>();
      repo.gate = gate;
      await pumpPage(tester, _file, repo: repo, settle: false);
      await tester.pump();
      expect(find.byType(SkeletonRows), findsWidgets);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Vida'), findsOneWidget);

      final bad = _repoWithRequests()
        ..failNext = const RequestFailure(RequestFailureKind.unknown);
      await pumpPage(tester, _file, repo: bad);
      expect(
        find.text('Não foi possível carregar os pedidos. Tente de novo.'),
        findsWidgets,
      );
      await tester.tap(find.text('Tentar de novo').first);
      await tester.pumpAndSettle();
      expect(find.text('Vida'), findsOneWidget);
    });

    testWidgets('offline: ver continua, "Novo pedido" desativado', (
      tester,
    ) async {
      final h = await pumpPage(tester, _file, repo: _repoWithRequests());
      h.connectivity.reportNetworkFailure();
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem ligação.'), findsOneWidget);
      expect(find.text('Precisa de ligação para criar.'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Novo pedido'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Vida'), findsOneWidget);
    });

    testWidgets('sem acesso: não revela se o cliente existe', (tester) async {
      final h = await pumpPage(tester, const ClientFilePage(clientId: 'c-x'));
      expect(find.text('Sem acesso'), findsOneWidget);
      expect(find.text('Novo pedido'), findsNothing);
      await tester.tap(find.text('Voltar a Clientes'));
      await tester.pumpAndSettle();
      expect(h.location, '/mediador');
    });

    testWidgets('depois de criar: aviso com os pedidos e o email enviado', (
      tester,
    ) async {
      await pumpPage(
        tester,
        _file,
        repo: _repoWithRequests(),
        beforePump: (s) => s.requestsHandoff.put(_batch(BatchEmailStatus.sent)),
      );
      expect(find.text('2 pedidos criados'), findsOneWidget);
      expect(
        find.text(
          'Automóvel e Vida. Email enviado a maria.figueiredo@exemplo.pt.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reenviar email'), findsNothing);
    });

    testWidgets('email não enviado: reenviar, e bloqueio de 60 s', (
      tester,
    ) async {
      final mail = FakeRequestEmailSender(
        recipientEmail: 'maria.figueiredo@exemplo.pt',
      );
      final h = await pumpPage(
        tester,
        _file,
        repo: _repoWithRequests(),
        email: mail,
        beforePump: (s) =>
            s.requestsHandoff.put(_batch(BatchEmailStatus.notSent)),
      );
      expect(
        find.text('2 pedidos criados, mas o email não foi enviado.'),
        findsOneWidget,
      );
      expect(find.text('Reenviar email'), findsOneWidget);
      await tester.ensureVisible(find.text('Reenviar email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reenviar email'));
      await tester.pump();
      await tester.pump();
      expect(mail.calls, ['b-1']);
      expect(
        find.text('Email reenviado a maria.figueiredo@exemplo.pt.'),
        findsOneWidget,
      );
      expect(find.textContaining('Pode reenviar às'), findsOneWidget);
      expect(
        tester
            .widget<SecondaryButton>(
              find.widgetWithText(SecondaryButton, 'Reenviar email'),
            )
            .onPressed,
        isNull,
      );
      expect(h.repo.createCalls, isEmpty);
      // Deixa o relógio do bloqueio acabar (sem temporizadores pendentes).
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('email não enviado e offline: reenviar bloqueado', (
      tester,
    ) async {
      final h = await pumpPage(
        tester,
        _file,
        repo: _repoWithRequests(),
        beforePump: (s) =>
            s.requestsHandoff.put(_batch(BatchEmailStatus.notSent)),
      );
      h.connectivity.reportNetworkFailure();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SecondaryButton>(
              find.widgetWithText(SecondaryButton, 'Reenviar email'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('falha do reenvio: aviso e continua por enviar', (
      tester,
    ) async {
      final mail = FakeRequestEmailSender(
        failure: const RequestFailure(RequestFailureKind.emailNotSent),
      );
      await pumpPage(
        tester,
        _file,
        repo: _repoWithRequests(),
        email: mail,
        beforePump: (s) =>
            s.requestsHandoff.put(_batch(BatchEmailStatus.notSent)),
      );
      await tester.ensureVisible(find.text('Reenviar email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reenviar email'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível reenviar o email'),
        findsOneWidget,
      );
      expect(
        find.text('Email reenviado a maria.figueiredo@exemplo.pt.'),
        findsNothing,
      );
    });

    testWidgets('visível também com email_unavailable (concessão perdida)', (
      tester,
    ) async {
      await pumpPage(
        tester,
        _file,
        repo: _repoWithRequests(),
        beforePump: (s) =>
            s.requestsHandoff.put(_batch(BatchEmailStatus.clientNotAvailable)),
      );
      expect(
        find.text('Este cliente já não partilha dados consigo.'),
        findsOneWidget,
      );
    });

    testWidgets('mostrar mais 25', (tester) async {
      final repo = FakeRequestsRepository();
      repo.officeRequests['c-maria'] = [
        for (var i = 0; i < 30; i++)
          OfficeRequest(
            id: 'r$i',
            typeCode: 'vida',
            typeName: 'Vida $i',
            stage: RequestStage.created,
            origin: RequestOrigin.mediador,
            allowPolicyConditions: false,
            createdAt: DateTime(2026, 11, 27 - (i % 20)),
            documentCount: 1,
            dataCount: 0,
          ),
      ];
      await pumpPage(tester, _file, repo: repo);
      expect(find.text('Vida 0'), findsOneWidget);
      await tester.ensureVisible(find.text('Mostrar mais 25'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mostrar mais 25'));
      await tester.pumpAndSettle();
      expect(find.text('Vida 29'), findsOneWidget);
      expect(find.text('Mostrar mais 25'), findsNothing);
    });
  });

  group('pedido aberto do mediador', () {
    const page = MediatorRequestPage(clientId: 'c-maria', requestId: 'r1');

    for (final e in testSizes.entries) {
      testWidgets('só leitura, ${e.key}', (tester) async {
        final repo = FakeRequestsRepository();
        repo.details['r1'] = sampleDetail();
        final h = await pumpPage(tester, page, repo: repo, size: e.value);
        expect(tester.takeException(), isNull);
        expect(find.text('Automóvel'), findsOneWidget);
        expect(find.text('Para Maria do Carmo Figueiredo'), findsOneWidget);
        expect(find.text('Criado por Ana Martins'), findsOneWidget);
        expect(find.text('Origem: mediador'), findsOneWidget);
        expect(find.text('Condições particulares'), findsOneWidget);
        expect(find.text('Etapa 1 de 4: Pedido criado'), findsOneWidget);
        expect(find.text('Mensagem de Ana Martins'), findsOneWidget);
        expect(find.textContaining('Bom dia, D. Maria'), findsOneWidget);
        expect(find.text('Lista pedida'), findsOneWidget);
        expect(find.text('2 documentos · 1 dado'), findsOneWidget);
        expect(find.text('Morada'), findsOneWidget);
        expect(find.text('Acrescentado neste pedido'), findsOneWidget);
        // Só leitura: nenhuma ação sobre a lista.
        expect(find.text('Tirar'), findsNothing);
        expect(find.text('Acrescentar item'), findsNothing);
        expect(find.byType(PrimaryButton), findsNothing);
        expect(find.byType(StageStrip), findsOneWidget);
        expect(find.textContaining('Só leitura'), findsOneWidget);
        // O regresso diz o nome do cliente e volta à ficha.
        await tester.tap(find.text('Maria do Carmo Figueiredo').first);
        await tester.pumpAndSettle();
        expect(h.location, '/mediador/clientes/c-maria');
      });
    }

    testWidgets('sem mensagem nem condições particulares', (tester) async {
      final repo = FakeRequestsRepository();
      repo.details['r1'] = sampleDetail(policy: false, message: null);
      await pumpPage(tester, page, repo: repo);
      expect(find.textContaining('Mensagem de'), findsNothing);
      expect(find.text('Condições particulares'), findsNothing);
    });

    testWidgets('a carregar, erro e sem acesso', (tester) async {
      final repo = FakeRequestsRepository();
      final gate = Completer<void>();
      repo.gate = gate;
      await pumpPage(tester, page, repo: repo, settle: false);
      await tester.pump();
      expect(find.byType(SkeletonRows), findsOneWidget);
      repo.details['r1'] = sampleDetail();
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Lista pedida'), findsOneWidget);

      final bad = FakeRequestsRepository()
        ..failNext = const RequestFailure(RequestFailureKind.unknown);
      bad.details['r1'] = sampleDetail();
      await pumpPage(tester, page, repo: bad);
      expect(
        find.text('Não foi possível abrir este pedido. Tente de novo.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Lista pedida'), findsOneWidget);

      await pumpPage(tester, page, repo: FakeRequestsRepository());
      expect(find.text('Sem acesso'), findsOneWidget);
    });
  });
}
