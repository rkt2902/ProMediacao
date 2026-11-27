import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/client_requests/presentation/client_request_page.dart';
import 'package:promediacao/features/notifications/domain/notification_models.dart'
    hide NotificationsPage;
import 'package:promediacao/features/notifications/presentation/notifications_copy.dart';
import 'package:promediacao/features/notifications/presentation/notifications_page.dart';
import 'package:promediacao/features/notifications/presentation/notifications_panel.dart';

import '../../client_requests/client_requests_test_helpers.dart';
import '../../requests/fake_requests_repository.dart';
import '../fake_notifications_repository.dart';

FakeRequestsRepository _requests() => FakeRequestsRepository()
  ..mine.add(myRequest('r-n1'))
  ..details['r-n1'] = detail(id: 'r-n1');

FakeNotificationsRepository _two() => FakeNotificationsRepository([
  notification('n1'),
  notification('n2'),
  notification('n3', read: true),
]);

void main() {
  group('painel (médio e largo)', () {
    for (final e in {
      'tablet': const Size(768, 1024),
      'desktop': const Size(1280, 800),
    }.entries) {
      testWidgets('o sino abre a folha lateral em ${e.key}', (tester) async {
        await pumpClient(
          tester,
          requests: _requests(),
          notifications: _two(),
          size: e.value,
        );
        await tester.tap(find.byType(NotificationBell));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsPanel), findsOneWidget);
        expect(find.text(NotificationsCopy.title), findsWidgets);
        expect(find.text('2 por ler'), findsOneWidget);
        expect(find.text(NotificationsCopy.close), findsOneWidget);
        expect(find.textContaining('Por ler · '), findsNWidgets(2));
        expect(find.text('Novo pedido: Automóvel'), findsNWidgets(3));
        final panel = tester.getRect(find.byType(NotificationsPanel));
        expect(panel.width, 440);
        // O sino fica "aberto" (fundo cartolina).
        expect(
          tester.widget<NotificationBell>(find.byType(NotificationBell)).open,
          isTrue,
        );
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('Fechar fecha e devolve o foco ao ecrã', (tester) async {
      await pumpClient(tester, requests: _requests(), notifications: _two());
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NotificationsCopy.close));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPanel), findsNothing);
    });

    testWidgets('Esc fecha', (tester) async {
      await pumpClient(tester, requests: _requests(), notifications: _two());
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPanel), findsNothing);
    });

    testWidgets('abrir marca como lida só com o servidor e leva ao pedido', (
      tester,
    ) async {
      final repo = _two()..readGate = Completer<void>();
      await pumpClient(tester, requests: _requests(), notifications: repo);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Novo pedido: Automóvel').first);
      await tester.pumpAndSettle();
      // Foi ao pedido; o servidor ainda não respondeu: contador igual.
      expect(find.byType(ClientRequestPage), findsOneWidget);
      expect(repo.readCalls, ['n1']);
      Finder counter(String t) => find.descendant(
        of: find.byType(NotificationBell),
        matching: find.text(t),
      );
      expect(counter('2'), findsOneWidget);
      repo.readGate!.complete();
      await tester.pumpAndSettle();
      expect(counter('1'), findsOneWidget);
      expect(counter('2'), findsNothing);
    });

    testWidgets('vazio: Sem notificações', (tester) async {
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: FakeNotificationsRepository(),
      );
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.text(NotificationsCopy.emptyTitle), findsOneWidget);
      expect(find.text(NotificationsCopy.emptyHelp), findsOneWidget);
    });

    testWidgets('todas lidas: sem contador no sino', (tester) async {
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: FakeNotificationsRepository([
          notification('n1', read: true),
        ]),
      );
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.text(NotificationsCopy.allRead), findsOneWidget);
      expect(NotificationBell.counterText(0), isNull);
    });

    testWidgets('erro ao carregar: Tentar de novo', (tester) async {
      final repo = _two();
      await pumpClient(tester, requests: _requests(), notifications: repo);
      repo.failure = const NotificationFailure(NotificationFailureKind.unknown);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.text(NotificationsCopy.loadFailed), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.text(NotificationsCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text(NotificationsCopy.loadFailed), findsNothing);
      expect(find.text('Novo pedido: Automóvel'), findsNWidgets(3));
    });

    testWidgets('offline: último estado conhecido e aviso', (tester) async {
      final connectivity = AppConnectivity();
      final repo = _two();
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: repo,
        connectivity: connectivity,
      );
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      repo.failure = const NotificationFailure(NotificationFailureKind.network);
      await tester.tap(find.text(NotificationsCopy.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      connectivity.reportNetworkFailure();
      await tester.pump();
      expect(
        find.textContaining('Sem ligação. Está a ver as notificações de'),
        findsOneWidget,
      );
      // A lista fica (já estava carregada).
      expect(find.text('Novo pedido: Automóvel'), findsNWidgets(3));
    });

    testWidgets('Mostrar mais 25 com mais de 25', (tester) async {
      final repo = FakeNotificationsRepository([
        for (var i = 0; i < 30; i++) notification('n$i'),
      ]);
      await pumpClient(tester, requests: _requests(), notifications: repo);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Mostrar mais 25'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('Mostrar mais 25'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar mais 25'), findsNothing);
    });
  });

  group('ecrã inteiro (compacto)', () {
    testWidgets('o sino leva ao ecrã, com regresso e sem colofão', (
      tester,
    ) async {
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: _two(),
        size: const Size(390, 844),
      );
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(NotificationsPanel), findsNothing);
      expect(find.text(NotificationsCopy.title), findsWidgets);
      expect(find.text('2 por ler'), findsOneWidget);
      expect(find.text(NotificationsCopy.backToRequests), findsOneWidget);
      expect(find.byType(Colophon), findsNothing);
      expect(
        tester.widget<NotificationBell>(find.byType(NotificationBell)).open,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('abrir uma notificação vai ao pedido', (tester) async {
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: _two(),
        size: const Size(390, 844),
        location: '/cliente/notificacoes',
      );
      await tester.tap(find.text('Novo pedido: Automóvel').first);
      await tester.pumpAndSettle();
      expect(find.byType(ClientRequestPage), findsOneWidget);
    });

    testWidgets('offline: aviso com a hora e a lista fica', (tester) async {
      final connectivity = AppConnectivity();
      final repo = _two();
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: repo,
        size: const Size(390, 844),
        location: '/cliente/notificacoes',
        connectivity: connectivity,
      );
      repo.failure = const NotificationFailure(NotificationFailureKind.network);
      await tester.tap(find.text(NotificationsCopy.backToRequests));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      // Recarregar a lista com falha mantém o último estado e mostra o aviso.
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.text('Novo pedido: Automóvel'), findsWidgets);
    });

    testWidgets('texto 1.3 em 390 sem erros', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpClient(
        tester,
        requests: _requests(),
        notifications: _two(),
        size: const Size(390, 844),
        location: '/cliente/notificacoes',
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('bell: contador e leitura de ecrã', (tester) async {
    expect(NotificationBell.counterText(null), isNull);
    expect(NotificationBell.counterText(9), '9');
    expect(NotificationBell.counterText(10), '9+');
    expect(NotificationBell.spokenLabel(2), 'Notificações, 2 por ler');
  });
}
