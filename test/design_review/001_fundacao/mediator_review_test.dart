@Tags(['design-review'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/features/mediator/domain/mediator_models.dart';

import '../../features/mediator/mediator_screens_test.dart'
    show FakeMediatorRepository, fixtures, pumpMediator;
import 'review_helpers.dart';

DateTime _now() => DateTime(2026, 11, 26, 15, 4);

/// Criar fica "a criar…" até se libertar, para ver o botão a carregar.
class _SlowCreate extends FakeMediatorRepository {
  _SlowCreate() : super(_now, fixtures());
  final gateCreate = Completer<void>();
  @override
  Future<void> createClient({
    required String fullName,
    required String email,
  }) => gateCreate.future;
}

Future<FakeMediatorRepository> _pump(
  WidgetTester tester,
  Size size, {
  FakeMediatorRepository? repo,
  double scale = 1.0,
}) async {
  await loadReviewFonts();
  final r = repo ?? FakeMediatorRepository(_now, fixtures());
  r.countWorks = true;
  await pumpMediator(tester, r, size: size, textScale: scale, clock: _now);
  return r;
}

Future<void> _openCreate(WidgetTester tester) async {
  await tester.tap(find.text('Criar cliente').first);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String label, String text) async {
  final f = find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(EditableText),
  );
  await tester.enterText(f.first, text);
  await tester.pump();
}

void main() {
  final variants = <String, (Size, double)>{
    for (final e in reviewSizes.entries) e.key: (e.value, 1.0),
    '320': (smallSize, 1.0),
    'telemovel-1.3': (reviewSizes['telemovel']!, 1.3),
    'desktop-1.3': (reviewSizes['desktop']!, 1.3),
  };

  for (final v in variants.entries) {
    testWidgets('clientes-${v.key}', (tester) async {
      await _pump(tester, v.value.$1, scale: v.value.$2);
      await shoot(tester, 'clientes-${v.key}');
    }, skip: skipReview);
  }

  for (final e in reviewSizes.entries) {
    testWidgets('criar-cliente-${e.key}', (tester) async {
      await _pump(tester, e.value);
      await _openCreate(tester);
      await shoot(tester, 'criar-cliente-${e.key}');
    }, skip: skipReview);
  }

  for (final k in ['telemovel', 'desktop']) {
    testWidgets('criar-cliente-a-criar-$k', (tester) async {
      await _pump(tester, reviewSizes[k]!, repo: _SlowCreate());
      await _openCreate(tester);
      await _fill(tester, 'Nome completo', 'Joana Ribeiro Antunes');
      await _fill(tester, 'Email', 'joana.antunes@exemplo.pt');
      await tester.tap(find.text('Criar e enviar pedido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await shoot(tester, 'criar-cliente-a-criar-$k');
    }, skip: skipReview);
  }

  testWidgets('clientes-reenviado-app-desktop', (tester) async {
    final repo = FakeMediatorRepository(_now, fixtures())
      ..resendDelivery = ResendDelivery.none;
    await _pump(tester, reviewSizes['desktop']!, repo: repo);
    await tester.tap(find.text('Reenviar pedido').last);
    await tester.pumpAndSettle();
    await shoot(tester, 'clientes-reenviado-app-desktop');
  }, skip: skipReview);

  testWidgets('clientes-reenviado-app-telemovel', (tester) async {
    final repo = FakeMediatorRepository(_now, fixtures())
      ..resendDelivery = ResendDelivery.none;
    await _pump(tester, reviewSizes['telemovel']!, repo: repo);
    await tester.tap(find.text('Reenviar pedido').last);
    await tester.pumpAndSettle();
    await shoot(tester, 'clientes-reenviado-app-telemovel');
  }, skip: skipReview);

  testWidgets('clientes-vazio-telemovel', (tester) async {
    await _pump(
      tester,
      reviewSizes['telemovel']!,
      repo: FakeMediatorRepository(_now, []),
    );
    await shoot(tester, 'clientes-vazio-telemovel');
  }, skip: skipReview);
}
