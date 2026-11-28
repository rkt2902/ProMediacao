@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/mediator/presentation/new_request_page.dart';
import 'package:promediacao/features/mediator/presentation/new_request_sections.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../../features/mediator/request_test_helpers.dart';
import '../../features/requests/fake_requests_repository.dart';
import 'review_helpers.dart';

const _fromFile = NewRequestPage(clientId: 'c-maria', fromClientFile: true);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _check(WidgetTester tester, String code) =>
    _tap(tester, find.byKey(ValueKey('tipo-$code')));

Future<PageHarness> _pump(
  WidgetTester tester,
  Widget page, {
  required Size size,
  double scale = 1.0,
  FakeRequestsRepository? repo,
}) async {
  await loadReviewFonts();
  return pumpPage(
    tester,
    page,
    repo: repo ?? newRequestRepo(),
    size: size,
    textScale: scale,
  );
}

/// Estado populado das fixtures: Automóvel e Vida, condições particulares,
/// mensagem de 156, "Franquias" tirado e "Fotografias…" acrescentado.
Future<void> _populate(WidgetTester tester) async {
  await _check(tester, 'automovel');
  await _check(tester, 'vida');
  await _tap(tester, find.text('Permitir condições particulares'));
  await tester.enterText(find.byType(TextField).last, message156);
  await tester.pumpAndSettle();
  await _tap(
    tester,
    find.bySemanticsLabel(
      'Tirar Franquias (danos próprios) do pedido de Automóvel',
    ),
  );
  final add = find.descendant(
    of: find.byKey(const ValueKey('folha-automovel')),
    matching: find.text('Acrescentar item'),
  );
  await _tap(tester, add);
  await tester.enterText(
    find.descendant(
      of: find.byType(AddItemBox),
      matching: find.byType(TextField),
    ),
    'Fotografias do veículo (frente, traseira e lados)',
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  for (final v in mainVariants.entries) {
    testWidgets('novo-pedido-${v.key}', (tester) async {
      await _pump(tester, _fromFile, size: v.value.$1, scale: v.value.$2);
      await _populate(tester);
      await scrollToTop(tester);
      await shoot(tester, 'novo-pedido-${v.key}');
    }, skip: skipReview);
  }

  for (final k in ['telemovel', 'tablet', 'desktop']) {
    testWidgets('novo-pedido-completo-$k', (tester) async {
      await _pump(tester, _fromFile, size: reviewSizes[k]!);
      await _populate(tester);
      await growToFullPage(tester);
      await shoot(tester, 'novo-pedido-completo-$k');
    }, skip: skipReview);

    testWidgets('novo-pedido-escolher-cliente-$k', (tester) async {
      await _pump(tester, const NewRequestPage(), size: reviewSizes[k]!);
      await tester.enterText(find.byType(TextField).first, 'Ma');
      await tester.pumpAndSettle();
      await shoot(tester, 'novo-pedido-escolher-cliente-$k');
    }, skip: skipReview);
  }

  for (final k in ['telemovel', 'desktop']) {
    testWidgets('novo-pedido-repetido-$k', (tester) async {
      await _pump(tester, _fromFile, size: reviewSizes[k]!);
      await _check(tester, 'automovel');
      await _check(tester, 'multirriscos_habitacao');
      await growToFullPage(tester);
      await shoot(tester, 'novo-pedido-repetido-$k');
    }, skip: skipReview);

    testWidgets('novo-pedido-erro-$k', (tester) async {
      final repo = newRequestRepo()
        ..createFailure = const RequestFailure(RequestFailureKind.unknown);
      await _pump(tester, _fromFile, size: reviewSizes[k]!, repo: repo);
      await _check(tester, 'automovel');
      await _check(tester, 'vida');
      await _tap(tester, find.byType(PrimaryButton));
      await scrollToTop(tester);
      await shoot(tester, 'novo-pedido-erro-$k');
    }, skip: skipReview);

    testWidgets('novo-pedido-offline-$k', (tester) async {
      final h = await _pump(tester, _fromFile, size: reviewSizes[k]!);
      await _check(tester, 'automovel');
      await _check(tester, 'vida');
      h.connectivity.reportNetworkFailure();
      await tester.pumpAndSettle();
      await scrollToTop(tester);
      await shoot(tester, 'novo-pedido-offline-$k');
    }, skip: skipReview);
  }

  // Item tirado a meio da saída (pendente conhecido: sem animação).
  testWidgets('novo-pedido-tirar-meio-desktop', (tester) async {
    await _pump(tester, _fromFile, size: reviewSizes['desktop']!);
    await _check(tester, 'automovel');
    final f = find.bySemanticsLabel(
      'Tirar Coberturas pretendidas do pedido de Automóvel',
    );
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await shoot(tester, 'novo-pedido-tirar-meio-desktop');
    await tester.pumpAndSettle();
  }, skip: skipReview);
}
