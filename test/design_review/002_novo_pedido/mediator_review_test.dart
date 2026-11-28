@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/features/mediator/domain/mediator_models.dart';
import 'package:promediacao/features/mediator/presentation/client_file_page.dart';
import 'package:promediacao/features/mediator/presentation/mediator_request_page.dart';
import 'package:promediacao/features/requests/application/batch_email_controller.dart';
import 'package:promediacao/features/requests/application/created_batch.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../../features/mediator/mediator_screens_test.dart'
    show FakeMediatorRepository, client, fixtures, pumpMediator;
import '../../features/mediator/request_test_helpers.dart';
import '../../features/requests/fake_requests_repository.dart';
import 'review_helpers.dart';

DateTime _now() => DateTime(2026, 11, 27, 10, 15);

// --- Clientes com a coluna Pedidos ----------------------------------------

List<OfficeClient> _clients() => [
  ...fixtures(),
  client(
    'g5',
    'Manuel Araújo Pereira',
    'manuel.pereira@exemplo.pt',
    ClientStatus.ativo,
    DateTime(2026, 11, 9, 17, 30),
    clientId: 'c-manuel',
  ),
  client(
    'g6',
    'Marta Sousa Lopes',
    'marta.lopes@exemplo.pt',
    ClientStatus.ativo,
    DateTime(2026, 11, 5, 11, 48),
    clientId: 'c-marta',
  ),
];

FakeRequestsRepository _summaryRepo() => FakeRequestsRepository()
  ..openRequestCount = 6
  ..summary = {
    'c-maria': ClientRequestsSummary(
      clientId: 'c-maria',
      openCount: 5,
      totalCount: 5,
      maxOpenStage: RequestStage.documentsSent,
      lastCreatedAt: DateTime(2026, 11, 27, 10, 14),
    ),
    'c-manuel': ClientRequestsSummary(
      clientId: 'c-manuel',
      openCount: 1,
      totalCount: 1,
      maxOpenStage: RequestStage.created,
      lastCreatedAt: DateTime(2026, 11, 22, 9),
    ),
  };

Future<void> _pumpClients(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
}) async {
  await loadReviewFonts();
  final repo = FakeMediatorRepository(_now, _clients())..countWorks = true;
  await pumpMediator(
    tester,
    repo,
    size: size,
    textScale: scale,
    clock: _now,
    requests: _summaryRepo(),
  );
}

// --- Ficha e pedido aberto -----------------------------------------------

const _file = ClientFilePage(clientId: 'c-maria');

FakeRequestsRepository _fileRepo() =>
    FakeRequestsRepository()..officeRequests['c-maria'] = mariaRequests();

CreatedBatch _batch(BatchEmailStatus status) => CreatedBatch(
  batchId: 'b-1',
  clientId: 'c-maria',
  clientName: 'Maria do Carmo Figueiredo',
  clientEmail: 'maria.figueiredo@exemplo.pt',
  requests: [
    for (final (code, name) in [('automovel', 'Automóvel'), ('vida', 'Vida')])
      CreatedRequest(
        requestId: code == 'automovel' ? 'r-auto' : 'r-vida',
        batchId: 'b-1',
        typeCode: code,
        typeName: name,
        createdAt: DateTime(2026, 11, 27, 10, 14),
      ),
  ],
  emailStatus: status,
);

Future<PageHarness> _pumpFile(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
  CreatedBatch? batch,
  FakeRequestEmailSender? email,
  bool settle = true,
}) async {
  await loadReviewFonts();
  return pumpPage(
    tester,
    _file,
    repo: _fileRepo(),
    size: size,
    textScale: scale,
    email: email,
    settle: settle,
    beforePump: batch == null ? null : (s) => s.requestsHandoff.put(batch),
  );
}

void main() {
  for (final v in mainVariants.entries) {
    testWidgets('clientes-${v.key}', (tester) async {
      await _pumpClients(tester, v.value.$1, scale: v.value.$2);
      await shoot(tester, 'clientes-${v.key}');
    }, skip: skipReview);

    testWidgets('ficha-${v.key}', (tester) async {
      await _pumpFile(tester, v.value.$1, scale: v.value.$2);
      await shoot(tester, 'ficha-${v.key}');
    }, skip: skipReview);
  }

  testWidgets('clientes-completo-telemovel', (tester) async {
    await _pumpClients(tester, reviewSizes['telemovel']!);
    await growToFullPage(tester);
    await shoot(tester, 'clientes-completo-telemovel');
  }, skip: skipReview);

  for (final e in reviewSizes.entries) {
    testWidgets('ficha-pedidos-criados-${e.key}', (tester) async {
      await _pumpFile(tester, e.value, batch: _batch(BatchEmailStatus.sent));
      await shoot(tester, 'ficha-pedidos-criados-${e.key}');
    }, skip: skipReview);

    testWidgets('ficha-email-falhou-${e.key}', (tester) async {
      await _pumpFile(tester, e.value, batch: _batch(BatchEmailStatus.notSent));
      await shoot(tester, 'ficha-email-falhou-${e.key}');
    }, skip: skipReview);

    testWidgets('pedido-mediador-${e.key}', (tester) async {
      await loadReviewFonts();
      final repo = FakeRequestsRepository()
        ..details['r-auto'] = automovelDetail();
      await pumpPage(
        tester,
        const MediatorRequestPage(clientId: 'c-maria', requestId: 'r-auto'),
        repo: repo,
        size: e.value,
      );
      await shoot(tester, 'pedido-mediador-${e.key}');
    }, skip: skipReview);
  }

  for (final k in ['telemovel', 'desktop']) {
    testWidgets('ficha-completo-$k', (tester) async {
      await _pumpFile(tester, reviewSizes[k]!);
      await growToFullPage(tester);
      await shoot(tester, 'ficha-completo-$k');
    }, skip: skipReview);

    testWidgets('pedido-mediador-completo-$k', (tester) async {
      await loadReviewFonts();
      final repo = FakeRequestsRepository()
        ..details['r-auto'] = automovelDetail();
      await pumpPage(
        tester,
        const MediatorRequestPage(clientId: 'c-maria', requestId: 'r-auto'),
        repo: repo,
        size: reviewSizes[k]!,
      );
      await growToFullPage(tester);
      await shoot(tester, 'pedido-mediador-completo-$k');
    }, skip: skipReview);
  }

  // Email reenviado: botão bloqueado com a hora.
  testWidgets('ficha-email-reenviado-desktop', (tester) async {
    final mail = FakeRequestEmailSender(
      recipientEmail: 'maria.figueiredo@exemplo.pt',
    );
    await _pumpFile(
      tester,
      reviewSizes['desktop']!,
      batch: _batch(BatchEmailStatus.notSent),
      email: mail,
    );
    await tester.tap(find.text('Reenviar email'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shoot(tester, 'ficha-email-reenviado-desktop');
    await tester.pump(const Duration(seconds: 61));
  }, skip: skipReview);

  // Linhas novas a meio da entrada (pendente: entrada `lento` e realce).
  testWidgets('ficha-pedidos-criados-meio-desktop', (tester) async {
    await _pumpFile(
      tester,
      reviewSizes['desktop']!,
      batch: _batch(BatchEmailStatus.sent),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 160));
    await shoot(tester, 'ficha-pedidos-criados-meio-desktop');
    await tester.pumpAndSettle();
  }, skip: skipReview);

  testWidgets('ficha-offline-telemovel', (tester) async {
    final h = await _pumpFile(tester, reviewSizes['telemovel']!);
    h.connectivity.reportNetworkFailure();
    await tester.pumpAndSettle();
    await shoot(tester, 'ficha-offline-telemovel');
  }, skip: skipReview);
}
