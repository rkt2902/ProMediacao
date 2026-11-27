import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/format/dates.dart';
import 'package:promediacao/features/consent/domain/consent_models.dart';
import 'package:promediacao/features/consent/presentation/client_home_page.dart';
import 'package:promediacao/features/consent/presentation/consent_copy.dart';
import 'package:promediacao/features/consent/presentation/consent_page.dart';

import 'consent_test_helpers.dart';

const _route = '/cliente/pedido/g-pend';

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(AnimatedContainer),
);

void main() {
  group('Consentimento: tamanhos', () {
    for (final entry in consentSizes.entries) {
      testWidgets('populado em ${entry.key}', (tester) async {
        final repo = FakeConsentRepository(grants: [pendingGrant()]);
        await pumpClientApp(tester, repo, size: entry.value, location: _route);

        expect(find.byType(ConsentPage), findsOneWidget);
        expect(find.text('Pedido de acesso'), findsOneWidget);
        expect(find.text('Ribeira Seguros'), findsOneWidget);
        expect(find.text(ConsentCopy.requestsAccess), findsOneWidget);
        expect(find.text('Enviado por Ana Martins'), findsOneWidget);
        expect(find.text(ConsentCopy.summarySees), findsOneWidget);
        expect(find.text(ConsentCopy.recorded), findsOneWidget);
        expect(find.text(ConsentCopy.backToHome), findsOneWidget);
        // Texto da versão corrente, com o escritório no sítio.
        expect(
          find.text('Autoriza o Ribeira Seguros a ver os dados.'),
          findsOneWidget,
        );
        // Recusar e Aceitar: mesmo tamanho, lado a lado, Recusar à esquerda.
        final decline = tester.getRect(_button('Recusar').first);
        final accept = tester.getRect(_button('Aceitar').first);
        expect(decline.width, moreOrLessEquals(accept.width, epsilon: 0.5));
        expect(decline.height, accept.height);
        expect(decline.height, greaterThanOrEqualTo(56));
        expect(decline.top, accept.top);
        expect(decline.left, lessThan(accept.left));
        // A barra fica visível na janela.
        expect(accept.bottom, lessThanOrEqualTo(entry.value.height));
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('a carregar: skeleton e botões desativados', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()])
      ..listGate = Completer<void>();
    await pumpClientApp(tester, repo, location: _route, settle: false);
    expect(find.text('Ribeira Seguros'), findsNothing);
    expect(find.text(ConsentCopy.recorded), findsOneWidget);
    await tester.tap(find.text('Aceitar'));
    await tester.pump();
    expect(repo.calls.where((c) => c.startsWith('ativa')), isEmpty);
    repo.listGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Ribeira Seguros'), findsOneWidget);
  });

  testWidgets('aceitar: só mostra ativo depois da confirmação do servidor', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(tester, repo, location: _route);
    repo.writeGate = Completer<void>();

    await tester.tap(find.text('Aceitar'));
    await tester.pump();
    expect(find.text(ConsentCopy.registering), findsWidgets);
    expect(find.text('ATIVO'), findsNothing);
    // O outro botão fica desativado durante o envio.
    await tester.tap(find.text('Recusar'));
    await tester.pump();
    expect(repo.calls.where((c) => c.startsWith('recusada')), isEmpty);

    repo.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.acceptedVersion, 'v0');
    expect(find.text('ATIVO'), findsOneWidget);
    expect(find.text(ConsentCopy.activeSince(repo.now)), findsOneWidget);
    expect(find.text(ConsentCopy.seeHome), findsOneWidget);
    // A barra de ações sai.
    expect(find.text('Aceitar'), findsNothing);
    expect(find.text('Recusar'), findsNothing);
  });

  testWidgets('recusar: resultado recusado confirmado', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(
      tester,
      repo,
      location: _route,
      size: const Size(390, 844),
    );
    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();
    expect(repo.grants.single.status, GrantStatus.recusada);
    expect(find.text('RECUSADO'), findsOneWidget);
    expect(find.text(ConsentCopy.declinedOn(repo.now)), findsOneWidget);
    expect(
      find.text(ConsentCopy.declinedResult('Ribeira Seguros')),
      findsOneWidget,
    );
  });

  testWidgets('erro do servidor: mensagem, nada aceite, botões de volta', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()])
      ..writeFailure = const ConsentFailure(ConsentFailureKind.unknown);
    await pumpClientApp(tester, repo, location: _route);
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(find.text(ConsentCopy.respondFailed), findsOneWidget);
    expect(find.text('ATIVO'), findsNothing);
    expect(repo.grants.single.status, GrantStatus.pendente);

    // Tentar de novo resulta.
    repo.writeFailure = null;
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(find.text('ATIVO'), findsOneWidget);
    expect(find.text(ConsentCopy.respondFailed), findsNothing);
  });

  testWidgets('recusa do servidor com o pedido ainda pendente', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()])
      ..writeFailure = const ConsentFailure(ConsentFailureKind.stateChanged);
    await pumpClientApp(tester, repo, location: _route);
    final before = repo.calls.where((c) => c == 'list').length;
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    // Voltou a ler o servidor: continua pendente, por isso nada mudou.
    expect(repo.calls.where((c) => c == 'list').length, before + 1);
    expect(find.text(ConsentCopy.respondFailed), findsOneWidget);
    expect(find.text('ATIVO'), findsNothing);
  });

  testWidgets('pedido já respondido noutra sessão: mostra o estado real', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(tester, repo, location: _route);
    // Outro dispositivo recusou entretanto.
    repo.grants = [
      ConsentGrant(
        id: 'g-pend',
        officeId: 'o-g-pend',
        officeName: 'Ribeira Seguros',
        status: GrantStatus.recusada,
        consentVersion: 'v0',
        createdAt: DateTime.utc(2026, 11, 25, 15, 4),
        declinedAt: DateTime.utc(2026, 11, 26, 9),
      ),
    ];
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(find.text('ATIVO'), findsNothing);
    expect(find.text('RECUSADO'), findsOneWidget);
  });

  testWidgets('sem rede ao responder: não afirma nada e liga a faixa', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()])
      ..writeFailure = const ConsentFailure(ConsentFailureKind.network);
    final connectivity = AppConnectivity();
    await pumpClientApp(
      tester,
      repo,
      location: _route,
      connectivity: connectivity,
    );
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    expect(connectivity.online, isFalse);
    expect(find.text(ConsentCopy.respondUnconfirmed), findsOneWidget);
    expect(find.text(ConsentCopy.offlineRespond), findsOneWidget);
    expect(find.text('ATIVO'), findsNothing);
  });

  testWidgets('offline: botões desativados com a razão escrita', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    final connectivity = AppConnectivity();
    await pumpClientApp(
      tester,
      repo,
      location: _route,
      connectivity: connectivity,
      size: const Size(390, 844),
    );
    connectivity.reportNetworkFailure();
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
    expect(find.text(ConsentCopy.offlineRespond), findsOneWidget);
    await tester.tap(find.text('Aceitar'));
    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c.contains(':g-pend')), isEmpty);

    connectivity.reportReachable();
    await tester.pumpAndSettle();
    expect(find.text(ConsentCopy.recorded), findsOneWidget);
  });

  testWidgets('texto não carregou: erro e tentar de novo', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()])
      ..textFailure = const ConsentFailure(ConsentFailureKind.unknown);
    await pumpClientApp(tester, repo, location: _route);
    expect(find.text(ConsentCopy.textFailed), findsOneWidget);
    expect(find.text('Aceitar'), findsNothing);
    repo.textFailure = null;
    await tester.tap(find.text(ConsentCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('Aceitar'), findsOneWidget);
  });

  testWidgets('pedido já respondido: vai para Com quem partilho com aviso', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [activeGrant(id: 'g-pend')]);
    await pumpClientApp(tester, repo, location: _route);
    expect(find.byType(ClientHomePage), findsOneWidget);
    expect(
      find.text(ConsentCopy.alreadyAnswered(DateTime.utc(2026, 11, 12, 10, 4))),
      findsOneWidget,
    );
  });

  testWidgets('pedido inexistente: não revela nada e volta ao início', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant(id: 'outro')]);
    await pumpClientApp(tester, repo, location: _route);
    expect(find.byType(ClientHomePage), findsOneWidget);
    expect(find.text(ConsentCopy.requestUnavailable), findsOneWidget);
  });

  testWidgets('depois de aceitar, "Ver com quem partilho" leva o resultado', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(tester, repo, location: _route);
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(ConsentCopy.seeHome));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ConsentCopy.seeHome));
    await tester.pumpAndSettle();
    expect(find.byType(ClientHomePage), findsOneWidget);
    expect(
      find.text(ConsentCopy.acceptedResult('Ribeira Seguros')),
      findsOneWidget,
    );
    expect(find.text(ConsentCopy.withAccess), findsOneWidget);
    expect(find.text(ConsentCopy.since(repo.now)), findsOneWidget);
  });

  testWidgets('sair sem responder não regista nada', (tester) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(tester, repo, location: _route);
    await tester.tap(find.text(ConsentCopy.backToHome));
    await tester.pumpAndSettle();
    expect(find.byType(ClientHomePage), findsOneWidget);
    expect(repo.grants.single.status, GrantStatus.pendente);
    expect(find.text(ConsentCopy.pendingTitle), findsOneWidget);
  });

  testWidgets('altura baixa: a linha de apoio passa para o texto', (
    tester,
  ) async {
    final repo = FakeConsentRepository(grants: [pendingGrant()]);
    await pumpClientApp(
      tester,
      repo,
      location: _route,
      size: const Size(844, 390),
    );
    expect(find.text(ConsentCopy.recorded), findsOneWidget);
    expect(
      tester.getRect(_button('Aceitar').first).bottom,
      lessThanOrEqualTo(390),
    );
    expect(tester.takeException(), isNull);
  });

  test('datas por extenso usadas no ecrã', () {
    expect(
      ConsentCopy.activeSince(DateTime.utc(2026, 11, 26, 14, 32)),
      'Partilha ativa desde ${AppDates.dateTime(DateTime.utc(2026, 11, 26, 14, 32))}',
    );
  });
}
