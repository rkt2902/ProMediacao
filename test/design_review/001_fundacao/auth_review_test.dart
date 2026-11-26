@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/auth_test_helpers.dart';
import 'review_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Size size,
  String location, {
  FakeAuthRepository? repo,
}) async {
  await loadReviewFonts();
  await pumpAuthApp(
    tester,
    repo ?? FakeAuthRepository(),
    width: size.width,
    height: size.height,
    location: location,
  );
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
  final all = {...reviewSizes, '320': smallSize};

  group('Entrar', () {
    for (final e in all.entries) {
      testWidgets('entrar-${e.key}', (tester) async {
        await _pump(tester, e.value, '/entrar');
        await shoot(tester, 'entrar-${e.key}');
      }, skip: skipReview);
    }
    testWidgets('entrar-telemovel-1.3', (tester) async {
      setTextScale(tester, 1.3);
      await _pump(tester, reviewSizes['telemovel']!, '/entrar');
      await shoot(tester, 'entrar-telemovel-1.3');
    }, skip: skipReview);
    for (final k in ['telemovel', 'desktop']) {
      testWidgets('entrar-erro-$k', (tester) async {
        await _pump(tester, reviewSizes[k]!, '/entrar');
        await _fill(tester, 'Email', 'maria.figueiredo@exemplo.pt');
        await _fill(tester, 'Palavra-passe', 'Errada-2026');
        await tester.tap(find.text('Entrar').last);
        await tester.pumpAndSettle();
        await shoot(tester, 'entrar-erro-$k');
      }, skip: skipReview);
    }
  });

  group('Recuperar e link expirado', () {
    for (final e in reviewSizes.entries) {
      testWidgets('recuperar-${e.key}', (tester) async {
        await _pump(tester, e.value, '/recuperar');
        await shoot(tester, 'recuperar-${e.key}');
      }, skip: skipReview);
      testWidgets('link-expirado-${e.key}', (tester) async {
        await _pump(tester, e.value, '/link-invalido');
        await shoot(tester, 'link-expirado-${e.key}');
      }, skip: skipReview);
    }
    testWidgets('link-expirado-320-1.3', (tester) async {
      setTextScale(tester, 1.3);
      await _pump(tester, smallSize, '/link-invalido');
      await shoot(tester, 'link-expirado-320-1.3');
    }, skip: skipReview);
  });

  group('Criar palavra-passe (cliente)', () {
    final variants = {...all, 'telemovel-1.3': reviewSizes['telemovel']!};
    for (final e in variants.entries) {
      testWidgets('criar-palavra-passe-${e.key}', (tester) async {
        if (e.key.endsWith('1.3')) setTextScale(tester, 1.3);
        final repo = FakeAuthRepository(session: linkClient());
        await _pump(
          tester,
          e.value,
          '/cliente/criar-palavra-passe',
          repo: repo,
        );
        await _fill(tester, 'Nova palavra-passe', 'Ribeira2026');
        await tester.pumpAndSettle();
        await shoot(tester, 'criar-palavra-passe-${e.key}');
      }, skip: skipReview);
    }
  });
}
