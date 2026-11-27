import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/client_requests/presentation/client_request_page.dart';
import 'package:promediacao/features/client_requests/presentation/client_requests_copy.dart';
import 'package:promediacao/features/consent/domain/consent_models.dart';
import 'package:promediacao/features/consent/presentation/client_home_page.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';
import 'package:promediacao/features/notifications/domain/notification_models.dart';

import '../consent/consent_test_helpers.dart';
import '../notifications/fake_notifications_repository.dart';
import '../requests/fake_requests_repository.dart';
import 'client_requests_test_helpers.dart';

FakeRequestsRepository _populated() {
  final repo = FakeRequestsRepository();
  repo.mine.addAll([
    myRequest('r-1'),
    myRequest('r-2'),
    myRequest('r-3', withdrawn: true),
  ]);
  repo.details['r-1'] = detail();
  return repo;
}

void main() {
  group('Os meus pedidos: tamanhos', () {
    for (final e in sizes.entries) {
      testWidgets('populado em ${e.key}', (tester) async {
        await pumpClient(
          tester,
          requests: _populated(),
          notifications: FakeNotificationsRepository([
            notification('n1'),
            notification('n2'),
          ]),
          size: e.value,
        );
        expect(find.text('Os meus dados'), findsOneWidget);
        expect(find.text(ClientRequestsCopy.title), findsOneWidget);
        expect(find.text('Tem 2 pedidos em curso.'), findsOneWidget);
        expect(find.text(ClientRequestsCopy.interimNotice), findsOneWidget);
        expect(find.text(ClientRequestsCopy.groupOpen), findsOneWidget);
        expect(find.text(ClientRequestsCopy.groupWithdrawn), findsOneWidget);
        expect(find.text(ClientRequestsCopy.withdrawnHelp), findsOneWidget);
        expect(find.text('Etapa 1 de 4: Pedido criado'), findsNWidgets(2));
        expect(find.text('ACESSO RETIRADO'), findsOneWidget);
        expect(find.text('4 documentos e 2 dados pedidos'), findsNWidgets(3));
        expect(find.text('Ver o pedido'), findsNWidgets(3));
        expect(find.text('Do escritório Ribeira Seguros'), findsNWidgets(2));
        expect(find.text('2'), findsOneWidget); // contador do sino
        await tester.ensureVisible(find.text(ClientRequestsCopy.viewSharing));
        await tester.pumpAndSettle();
        expect(
          find.text('Partilha os seus dados com 1 escritório.'),
          findsOneWidget,
        );
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('compacto: "Ver o pedido" a toda a largura; largo: à direita', (
      tester,
    ) async {
      await pumpClient(
        tester,
        requests: _populated(),
        size: const Size(390, 844),
      );
      final compact = tester.getRect(
        find.widgetWithText(SecondaryButton, 'Ver o pedido').first,
      );
      expect(compact.width, greaterThan(300));
      await tester.pumpWidget(const SizedBox.shrink());

      await pumpClient(tester, requests: _populated());
      final wide = tester.getRect(
        find.widgetWithText(SecondaryButton, 'Ver o pedido').first,
      );
      expect(wide.width, lessThan(260));
      expect(wide.right, lessThan(700));
    });

    testWidgets('texto ampliado a 1.3 em 390 não rebenta', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpClient(
        tester,
        requests: _populated(),
        size: const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Os meus pedidos: estados', () {
    testWidgets('vazio', (tester) async {
      await pumpClient(tester, requests: FakeRequestsRepository());
      expect(find.text(ClientRequestsCopy.emptyTitle), findsOneWidget);
      expect(find.text(ClientRequestsCopy.emptyHelp), findsOneWidget);
      expect(find.text(ClientRequestsCopy.interimNotice), findsNothing);
      // Sem contador quando nada está por ler.
      expect(find.text(ClientRequestsCopy.viewSharing), findsOneWidget);
    });

    testWidgets('a carregar: esqueleto e passagem já visível', (tester) async {
      final repo = _populated()..gate = Completer<void>();
      await pumpClient(tester, requests: repo, settle: false);
      expect(find.byType(SkeletonRows), findsOneWidget);
      expect(find.text(ClientRequestsCopy.title), findsOneWidget);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonRows), findsNothing);
      expect(find.text('Ver o pedido'), findsNWidgets(3));
    });

    testWidgets('erro: mensagem e Tentar de novo', (tester) async {
      final repo = _populated()
        ..failNext = const RequestFailure(RequestFailureKind.unknown);
      await pumpClient(tester, requests: repo);
      expect(find.text(ClientRequestsCopy.loadFailed), findsOneWidget);
      await tester.tap(find.text(ClientRequestsCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text(ClientRequestsCopy.loadFailed), findsNothing);
      expect(find.text('Ver o pedido'), findsNWidgets(3));
    });

    testWidgets('offline: faixa e a lista fica', (tester) async {
      final connectivity = AppConnectivity();
      await pumpClient(
        tester,
        requests: _populated(),
        connectivity: connectivity,
      );
      connectivity.reportNetworkFailure();
      await tester.pump();
      expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
      expect(find.text('Ver o pedido'), findsNWidgets(3));
    });

    testWidgets('pedido de acesso pendente fica acima de tudo', (tester) async {
      await pumpClient(
        tester,
        requests: _populated(),
        consent: FakeConsentRepository(grants: [pendingGrant(), activeGrant()]),
      );
      expect(find.text('À espera da sua resposta'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('À espera da sua resposta')).dy,
        lessThan(tester.getTopLeft(find.text(ClientRequestsCopy.title)).dy),
      );
    });

    testWidgets('sem a lista de consentimentos: sem bloco nem frase', (
      tester,
    ) async {
      final consent = FakeConsentRepository(grants: [pendingGrant()])
        ..listFailure = const ConsentFailure(ConsentFailureKind.unknown);
      await pumpClient(tester, requests: _populated(), consent: consent);
      expect(find.text('À espera da sua resposta'), findsNothing);
      expect(find.textContaining('Partilha os seus dados'), findsNothing);
      expect(find.text(ClientRequestsCopy.viewSharing), findsOneWidget);
    });

    testWidgets('Mostrar mais quando há mais de 25', (tester) async {
      final repo = FakeRequestsRepository();
      for (var i = 0; i < 30; i++) {
        repo.mine.add(myRequest('r-$i'));
      }
      await pumpClient(tester, requests: repo);
      await tester.ensureVisible(find.text(ClientRequestsCopy.showMore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ClientRequestsCopy.showMore));
      await tester.pumpAndSettle();
      expect(find.text(ClientRequestsCopy.showMore), findsNothing);
    });
  });

  group('Os meus pedidos: navegação', () {
    testWidgets('Ver o pedido abre o detalhe', (tester) async {
      await pumpClient(tester, requests: _populated());
      await tester.tap(find.text('Ver o pedido').first);
      await tester.pumpAndSettle();
      expect(find.byType(ClientRequestPage), findsOneWidget);
      expect(find.text('Pedido do escritório Ribeira Seguros'), findsOneWidget);
    });

    testWidgets('Ver com quem partilho abre o ecrã da 001, com regresso', (
      tester,
    ) async {
      await pumpClient(tester, requests: _populated());
      await tester.ensureVisible(find.text(ClientRequestsCopy.viewSharing));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ClientRequestsCopy.viewSharing));
      await tester.pumpAndSettle();
      expect(find.byType(ClientHomePage), findsOneWidget);
      expect(find.text('Os meus pedidos'), findsOneWidget); // regresso
      await tester.tap(find.text('Os meus pedidos'));
      await tester.pumpAndSettle();
      expect(find.text('Tem 2 pedidos em curso.'), findsOneWidget);
    });

    testWidgets('em Com quem partilho há sino', (tester) async {
      await pumpClient(
        tester,
        requests: _populated(),
        notifications: FakeNotificationsRepository([notification('n1')]),
        location: '/cliente/partilhas',
      );
      expect(find.byType(ClientHomePage), findsOneWidget);
      expect(find.byType(NotificationBell), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  testWidgets('contador 9+ no sino', (tester) async {
    await pumpClient(
      tester,
      requests: _populated(),
      notifications: FakeNotificationsRepository([
        for (var i = 0; i < 12; i++) notification('n$i'),
      ]),
    );
    expect(find.text('9+'), findsOneWidget);
    expect(AppNotification.kindRequestCreated, isNotEmpty);
  });
}
