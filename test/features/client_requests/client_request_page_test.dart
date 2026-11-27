import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/client_requests/presentation/client_requests_copy.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../requests/fake_requests_repository.dart';
import 'client_requests_test_helpers.dart';

const _route = '/cliente/pedidos/r-1';

FakeRequestsRepository _with(RequestDetail d) =>
    FakeRequestsRepository()..details[d.id] = d;

void main() {
  group('Pedido do cliente: tamanhos', () {
    for (final e in sizes.entries) {
      testWidgets('populado em ${e.key}', (tester) async {
        await pumpClient(
          tester,
          requests: _with(detail()),
          location: _route,
          size: e.value,
        );
        expect(find.text('Automóvel'), findsOneWidget);
        expect(
          find.text('Pedido do escritório Ribeira Seguros'),
          findsOneWidget,
        );
        expect(find.text('Enviado por Ana Martins, mediadora'), findsOneWidget);
        expect(find.text('Etapa 1 de 4: Pedido criado'), findsOneWidget);
        expect(find.text(ClientRequestsCopy.interimNotice), findsOneWidget);
        expect(find.text('Mensagem de Ana Martins'), findsOneWidget);
        expect(find.textContaining('Bom dia, D. Maria'), findsOneWidget);
        expect(find.text('O que lhe pedem'), findsOneWidget);
        expect(find.text('1 documento · 1 dado'), findsOneWidget);
        expect(find.text(ClientRequestsCopy.policyNote), findsOneWidget);
        expect(find.textContaining('condutor habitual'), findsOneWidget);
        expect(find.text('Carta de condução'), findsOneWidget);
        expect(find.text('Morada'), findsOneWidget);
        expect(find.byType(StageStrip), findsOneWidget);
        expect(find.text('Em análise pelo mediador'), findsOneWidget);
        expect(find.text('Por fazer'), findsNWidgets(3));
        expect(find.text(ClientRequestsCopy.footer), findsOneWidget);
        // Só leitura: nenhuma ação sobre os itens.
        expect(find.text('Tirar'), findsNothing);
        expect(find.text(ClientRequestsCopy.backToRequests), findsOneWidget);
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('etapa 2: duas etapas feitas', (tester) async {
      await pumpClient(
        tester,
        requests: _with(detail(stage: RequestStage.documentsSent)),
        location: _route,
      );
      expect(find.text('Etapa 2 de 4: Documentos enviados'), findsOneWidget);
      expect(find.text('Por fazer'), findsNWidgets(2));
    });
  });

  group('Pedido do cliente: estados', () {
    testWidgets('acesso retirado: carimbo, explicação, sem aviso interino', (
      tester,
    ) async {
      await pumpClient(
        tester,
        requests: _with(detail(withdrawn: true)),
        location: _route,
        size: const Size(390, 844),
      );
      expect(find.text('ACESSO RETIRADO'), findsOneWidget);
      expect(find.text('Retirado a 26 nov 2026, 15:02'), findsOneWidget);
      expect(
        find.text(
          'O escritório Ribeira Seguros já não vê este pedido nem os seus '
          'dados. Se voltar a dar acesso, o pedido continua onde estava.',
        ),
        findsOneWidget,
      );
      expect(find.text(ClientRequestsCopy.interimNotice), findsNothing);
      expect(find.textContaining('Etapa 1 de 4: Pedido criado'), findsNothing);
      // A lista e a mensagem continuam legíveis.
      expect(find.text('Carta de condução'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem mensagem nem autor nem notas', (tester) async {
      final d = RequestDetail(
        id: 'r-1',
        clientId: 'c',
        clientName: 'Maria',
        officeId: 'o',
        officeName: 'Ribeira Seguros',
        typeCode: 'vida',
        typeName: 'Vida',
        origin: RequestOrigin.mediador,
        stage: RequestStage.created,
        allowPolicyConditions: false,
        createdAt: DateTime.utc(2026, 11, 27, 10, 14),
        accessWithdrawn: false,
        items: const [],
      );
      await pumpClient(tester, requests: _with(d), location: _route);
      expect(find.textContaining('Mensagem de'), findsNothing);
      expect(find.text('Mensagem do escritório'), findsNothing);
      expect(find.textContaining('Enviado por'), findsNothing);
      expect(find.text('0 documentos · 0 dados'), findsOneWidget);
    });

    testWidgets('a carregar: esqueleto', (tester) async {
      final repo = _with(detail())..gate = Completer<void>();
      await pumpClient(tester, requests: repo, location: _route, settle: false);
      expect(find.byType(SkeletonRows), findsOneWidget);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonRows), findsNothing);
    });

    testWidgets('erro: mensagem e Tentar de novo', (tester) async {
      final repo = _with(detail())
        ..failNext = const RequestFailure(RequestFailureKind.unknown);
      await pumpClient(tester, requests: repo, location: _route);
      expect(find.text(ClientRequestsCopy.detailFailed), findsOneWidget);
      await tester.tap(find.text(ClientRequestsCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text(ClientRequestsCopy.detailFailed), findsNothing);
      expect(find.text('Carta de condução'), findsOneWidget);
    });

    testWidgets('não encontrado: explica e leva a Os meus pedidos', (
      tester,
    ) async {
      final repo = FakeRequestsRepository()..mine.add(myRequest('r-9'));
      await pumpClient(
        tester,
        requests: repo,
        location: '/cliente/pedidos/nao-existe',
      );
      expect(find.text(ClientRequestsCopy.notFoundTitle), findsOneWidget);
      expect(find.text(ClientRequestsCopy.notFoundHelp), findsOneWidget);
      await tester.tap(find.text(ClientRequestsCopy.seeMyRequests));
      await tester.pumpAndSettle();
      expect(find.text('Tem 1 pedido em curso.'), findsOneWidget);
    });

    testWidgets('regresso volta a Os meus pedidos', (tester) async {
      final repo = _with(detail())..mine.add(myRequest('r-1'));
      await pumpClient(tester, requests: repo, location: _route);
      await tester.tap(find.text(ClientRequestsCopy.backToRequests));
      await tester.pumpAndSettle();
      expect(find.text('Tem 1 pedido em curso.'), findsOneWidget);
    });
  });
}
