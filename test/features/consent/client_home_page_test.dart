import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/consent/domain/consent_models.dart';
import 'package:promediacao/features/consent/presentation/consent_copy.dart';
import 'package:promediacao/features/consent/presentation/consent_page.dart';
import 'package:promediacao/features/notifications/domain/notification_models.dart';

import '../notifications/fake_notifications_repository.dart';
import 'consent_test_helpers.dart';

List<ConsentGrant> _all() => [
  pendingGrant(
    office: 'Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda.',
    mediator: 'Rui Costa',
  ),
  activeGrant(),
  withdrawnGrant(),
  declinedGrant(),
];

void main() {
  group('Com quem partilho: tamanhos', () {
    for (final entry in consentSizes.entries) {
      testWidgets('populado em ${entry.key}', (tester) async {
        final repo = FakeConsentRepository(grants: _all());
        await pumpClientApp(tester, repo, size: entry.value);

        expect(find.text('Os meus dados'), findsOneWidget);
        expect(find.text(ConsentCopy.homeTitle), findsOneWidget);
        expect(find.text(ConsentCopy.pendingTitle), findsOneWidget);
        expect(find.text(ConsentCopy.pendingHelp(1)), findsOneWidget);
        expect(find.text('Enviado por Rui Costa'), findsOneWidget);
        expect(find.text(ConsentCopy.respond), findsOneWidget);
        expect(find.text(ConsentCopy.summary(1)), findsOneWidget);
        expect(find.text(ConsentCopy.withAccess), findsOneWidget);
        expect(find.text(ConsentCopy.withoutAccess), findsOneWidget);
        expect(find.text('ATIVO'), findsOneWidget);
        expect(find.text('RETIRADO'), findsOneWidget);
        expect(find.text('RECUSADO'), findsOneWidget);
        expect(find.text('PENDENTE'), findsOneWidget);
        expect(
          find.text(ConsentCopy.since(DateTime.utc(2026, 11, 12, 10, 4))),
          findsOneWidget,
        );
        // Só os ativos têm ações.
        expect(find.text(ConsentCopy.withdraw), findsOneWidget);
        expect(find.text(ConsentCopy.readAccepted), findsOneWidget);
        // "A sua conta" no fim.
        await tester.scrollUntilVisible(
          find.text('A sua conta'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('A sua conta'), findsOneWidget);
        expect(find.text(ConsentCopy.footer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('compacto: Retirar a toda a largura; largo: à direita', (
      tester,
    ) async {
      final repo = FakeConsentRepository(grants: [activeGrant()]);
      await pumpClientApp(tester, repo, size: const Size(390, 844));
      final compact = tester.getRect(
        find
            .ancestor(
              of: find.text(ConsentCopy.withdraw),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(compact.width, greaterThan(300));
      await tester.pumpWidget(const SizedBox.shrink());

      await pumpClientApp(tester, repo, size: const Size(1280, 800));
      final wide = tester.getRect(
        find
            .ancestor(
              of: find.text(ConsentCopy.withdraw),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final name = tester.getRect(find.text('Ribeira Seguros'));
      expect(wide.width, lessThan(300));
      expect(wide.top, lessThan(name.bottom));
    });
  });

  testWidgets('vazio', (tester) async {
    await pumpClientApp(tester, FakeConsentRepository());
    expect(find.text(ConsentCopy.emptyTitle), findsOneWidget);
    expect(find.text(ConsentCopy.emptyHelp), findsOneWidget);
    expect(find.text(ConsentCopy.pendingTitle), findsNothing);
    expect(find.text('A sua conta'), findsOneWidget);
  });

  testWidgets('a carregar: skeleton, nunca o bloco pendente', (tester) async {
    final repo = FakeConsentRepository(grants: _all())
      ..listGate = Completer<void>();
    await pumpClientApp(tester, repo, settle: false);
    expect(find.byType(SkeletonRows), findsOneWidget);
    expect(find.text(ConsentCopy.pendingTitle), findsNothing);
    repo.listGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonRows), findsNothing);
    expect(find.text(ConsentCopy.pendingTitle), findsOneWidget);
  });

  testWidgets('erro ao carregar e tentar de novo', (tester) async {
    final repo = FakeConsentRepository(grants: _all())
      ..listFailure = const ConsentFailure(ConsentFailureKind.unknown);
    await pumpClientApp(tester, repo);
    expect(find.text(ConsentCopy.loadFailed), findsOneWidget);
    expect(find.text('ATIVO'), findsNothing);
    repo.listFailure = null;
    await tester.tap(find.text(ConsentCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('ATIVO'), findsOneWidget);
  });

  testWidgets('offline: Retirar e Responder desativados com a razão', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: _all());
    final connectivity = AppConnectivity();
    await pumpClientApp(
      tester,
      repo,
      connectivity: connectivity,
      size: const Size(390, 844),
    );
    connectivity.reportNetworkFailure();
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
    expect(find.text(ConsentCopy.offlineShort), findsNWidgets(2));
    await tester.tap(find.text(ConsentCopy.respond));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentPage), findsNothing);
    final withdraw = tester.widget<SecondaryButton>(
      find.widgetWithText(SecondaryButton, ConsentCopy.withdraw),
    );
    expect(withdraw.onPressed, isNull);
    expect(withdraw.disabledReason, ConsentCopy.offlineShort);
  });

  testWidgets('sem rede ao carregar: faixa e erro', (tester) async {
    final repo = FakeConsentRepository(grants: _all())
      ..listFailure = const ConsentFailure(ConsentFailureKind.network);
    // Sem rede para tudo: o contador do sino também falha (uma resposta com
    // sucesso voltaria a marcar a app como online).
    final bell = FakeNotificationsRepository()
      ..failure = const NotificationFailure(NotificationFailureKind.network);
    await pumpClientApp(tester, repo, notifications: bell);
    expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
    expect(find.text(ConsentCopy.loadFailed), findsOneWidget);
  });

  testWidgets('aviso de outro ecrã aparece uma vez', (tester) async {
    final repo = FakeConsentRepository(grants: [activeGrant()]);
    final services = await pumpClientApp(
      tester,
      repo,
      notice: 'Palavra-passe criada.',
    );
    expect(find.text('Palavra-passe criada.'), findsOneWidget);
    expect(services.session.takeNotice(), isNull);
  });

  testWidgets('Responder abre o pedido (sem email nem link)', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(tester, repo, size: const Size(768, 1024));
    await tester.tap(find.text(ConsentCopy.respond));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentPage), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
  });

  group('Retirar acesso', () {
    for (final entry in {
      'telemóvel': const Size(390, 844),
      'desktop': const Size(1280, 800),
    }.entries) {
      testWidgets('cancelar não muda nada (${entry.key})', (tester) async {
        final repo = FakeConsentRepository(grants: [activeGrant()]);
        await pumpClientApp(tester, repo, size: entry.value);
        await tester.tap(find.text(ConsentCopy.withdraw));
        await tester.pumpAndSettle();
        expect(
          find.text(ConsentCopy.withdrawTitle('Ribeira Seguros')),
          findsOneWidget,
        );
        expect(find.text(ConsentCopy.withdrawMessage), findsOneWidget);
        await tester.tap(find.text(ConsentCopy.cancel));
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmSheet), findsNothing);
        expect(repo.calls.where((c) => c.startsWith('retirada')), isEmpty);
        expect(find.text('ATIVO'), findsOneWidget);
      });

      testWidgets('confirmar retira só com o servidor (${entry.key})', (
        tester,
      ) async {
        final repo = FakeConsentRepository(grants: [activeGrant()]);
        await pumpClientApp(tester, repo, size: entry.value);
        await tester.tap(find.text(ConsentCopy.withdraw));
        await tester.pumpAndSettle();
        repo.writeGate = Completer<void>();
        final confirm = find.descendant(
          of: find.byType(ConfirmSheet),
          matching: find.text(ConsentCopy.withdraw),
        );
        await tester.tap(confirm);
        await tester.pump();
        expect(find.text(ConsentCopy.withdrawing), findsWidgets);
        expect(find.text('RETIRADO'), findsNothing);
        expect(find.text('ATIVO'), findsOneWidget);

        repo.writeGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmSheet), findsNothing);
        expect(
          find.text(ConsentCopy.withdrawn('Ribeira Seguros')),
          findsOneWidget,
        );
        expect(find.text('RETIRADO'), findsOneWidget);
        expect(find.text(ConsentCopy.withdrawnOn(repo.now)), findsOneWidget);
        expect(find.text(ConsentCopy.withAccess), findsNothing);
        expect(find.text(ConsentCopy.withoutAccess), findsOneWidget);
        expect(find.text(ConsentCopy.summary(0)), findsOneWidget);
      });
    }

    testWidgets('falha do servidor: erro na folha, continua ativo', (
      tester,
    ) async {
      final repo = FakeConsentRepository(grants: [activeGrant()])
        ..writeFailure = const ConsentFailure(ConsentFailureKind.unknown);
      await pumpClientApp(tester, repo);
      await tester.tap(find.text(ConsentCopy.withdraw));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmSheet),
          matching: find.text(ConsentCopy.withdraw),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmSheet), findsOneWidget);
      expect(find.text(ConsentCopy.withdrawFailed), findsOneWidget);
      await tester.tap(find.text(ConsentCopy.cancel));
      await tester.pumpAndSettle();
      expect(find.text('ATIVO'), findsOneWidget);
      expect(find.text('RETIRADO'), findsNothing);
    });

    testWidgets('sem rede: não diz que retirou nem que continua', (
      tester,
    ) async {
      final repo = FakeConsentRepository(grants: [activeGrant()])
        ..writeFailure = const ConsentFailure(ConsentFailureKind.network);
      await pumpClientApp(tester, repo);
      await tester.tap(find.text(ConsentCopy.withdraw));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmSheet),
          matching: find.text(ConsentCopy.withdraw),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ConsentCopy.withdrawUnconfirmed), findsOneWidget);
      expect(find.text('RETIRADO'), findsNothing);
    });

    testWidgets('já retirada noutra sessão: mostra o estado do servidor', (
      tester,
    ) async {
      final repo = FakeConsentRepository(grants: [activeGrant()]);
      await pumpClientApp(tester, repo);
      repo.grants = [
        ConsentGrant(
          id: 'g-ativa',
          officeId: 'o-g-ativa',
          officeName: 'Ribeira Seguros',
          status: GrantStatus.retirada,
          consentVersion: 'v0',
          createdAt: DateTime.utc(2026, 11, 10, 9),
          acceptedAt: DateTime.utc(2026, 11, 12, 10, 4),
          withdrawnAt: DateTime.utc(2026, 11, 26, 8),
        ),
      ];
      await tester.tap(find.text(ConsentCopy.withdraw));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmSheet),
          matching: find.text(ConsentCopy.withdraw),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmSheet), findsNothing);
      expect(
        find.text(ConsentCopy.withdrawnOn(DateTime.utc(2026, 11, 26, 8))),
        findsOneWidget,
      );
    });
  });

  testWidgets('ler o texto aceite (só leitura)', (tester) async {
    final repo = FakeConsentRepository(grants: [activeGrant()]);
    await pumpClientApp(tester, repo, size: const Size(768, 1024));
    await tester.tap(find.text(ConsentCopy.readAccepted));
    await tester.pumpAndSettle();
    expect(find.text(ConsentCopy.acceptedTextTitle), findsOneWidget);
    expect(repo.calls, contains('text:v0'));
    expect(
      find.text('Autoriza o Ribeira Seguros a ver os dados.'),
      findsOneWidget,
    );
    expect(find.text(ConsentCopy.version('v0')), findsOneWidget);
    expect(find.text(ConsentCopy.withdraw), findsOneWidget); // só a da linha
    await tester.tap(find.text(ConsentCopy.close));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmSheet), findsNothing);
  });
}
