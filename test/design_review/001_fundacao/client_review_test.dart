@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/features/consent/presentation/consent_copy.dart';

import '../../features/consent/consent_test_helpers.dart';
import 'review_helpers.dart';

/// Texto real da versão em vigor (migração 001, rascunho para o jurista).
const _text =
    'RASCUNHO, A VALIDAR PELO JURISTA. Ao aceitar, autoriza este escritório '
    'de mediação (todos os mediadores do escritório) a aceder aos dados e '
    'documentos que partilha na plataforma, para tratar os seus pedidos. Pode '
    'retirar este acesso a qualquer momento e o escritório deixa de ver os '
    'seus dados de imediato. Este texto não é final.';

FakeConsentRepository _repo(List grants) {
  final r = FakeConsentRepository(grants: grants.cast());
  r.texts['v0'] = _text;
  return r;
}

FakeConsentRepository _full() => _repo([
  pendingGrant(),
  activeGrant(
    id: 'g-a2',
    office: 'Gabinete de Mediação Vale do Sousa & Filhos, Lda.',
  ),
  declinedGrant(),
  withdrawnGrant(),
]);

void main() {
  final variants = <String, (Size, double)>{
    for (final e in reviewSizes.entries) e.key: (e.value, 1.0),
    '320': (smallSize, 1.0),
    'telemovel-1.3': (reviewSizes['telemovel']!, 1.3),
    '320-1.3': (smallSize, 1.3),
  };

  for (final v in variants.entries) {
    testWidgets('consentimento-${v.key}', (tester) async {
      await loadReviewFonts();
      if (v.value.$2 != 1.0) setTextScale(tester, v.value.$2);
      await pumpClientApp(
        tester,
        _repo([pendingGrant()]),
        size: v.value.$1,
        location: '/cliente/pedido/g-pend',
      );
      await shoot(tester, 'consentimento-${v.key}');
    }, skip: skipReview);

    testWidgets('com-quem-partilho-${v.key}', (tester) async {
      await loadReviewFonts();
      if (v.value.$2 != 1.0) setTextScale(tester, v.value.$2);
      await pumpClientApp(tester, _full(), size: v.value.$1);
      await shoot(tester, 'com-quem-partilho-${v.key}');
    }, skip: skipReview);
  }

  for (final e in reviewSizes.entries) {
    testWidgets('retirar-acesso-${e.key}', (tester) async {
      await loadReviewFonts();
      await pumpClientApp(tester, _repo([activeGrant()]), size: e.value);
      await tester.tap(find.text(ConsentCopy.withdraw).first);
      await tester.pumpAndSettle();
      await shoot(tester, 'retirar-acesso-${e.key}');
    }, skip: skipReview);
  }

  testWidgets('acesso-retirado-telemovel', (tester) async {
    await loadReviewFonts();
    await pumpClientApp(
      tester,
      _repo([activeGrant()]),
      size: reviewSizes['telemovel']!,
    );
    await tester.tap(find.text(ConsentCopy.withdraw).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ConsentCopy.withdraw).last);
    await tester.pump(const Duration(milliseconds: 400));
    await shoot(tester, 'acesso-retirado-telemovel');
  }, skip: skipReview);

  testWidgets('com-quem-partilho-vazio-telemovel', (tester) async {
    await loadReviewFonts();
    await pumpClientApp(tester, _repo([]), size: reviewSizes['telemovel']!);
    await shoot(tester, 'com-quem-partilho-vazio-telemovel');
  }, skip: skipReview);

  testWidgets('consentimento-aceite-telemovel', (tester) async {
    await loadReviewFonts();
    await pumpClientApp(
      tester,
      _repo([pendingGrant()]),
      size: reviewSizes['telemovel']!,
      location: '/cliente/pedido/g-pend',
    );
    await tester.tap(find.text(ConsentCopy.accept).last);
    await tester.pumpAndSettle();
    await shoot(tester, 'consentimento-aceite-telemovel');
  }, skip: skipReview);
}
