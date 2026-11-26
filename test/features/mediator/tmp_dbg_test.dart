import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'mediator_screens_test.dart' as m;
void main() {
  testWidgets('dbg', (tester) async {
    final c = () => DateTime(2026,11,26,15,4,10);
    final repo = m.FakeMediatorRepository(c, m.fixtures());
    await m.pumpMediator(tester, repo, clock: c);
    await tester.tap(find.text('Criar cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Maria Teste');
    await tester.enterText(find.byType(EditableText).last, 'maria.teste@exemplo.pt');
    await tester.tap(find.text('Criar e enviar pedido'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      void walk(RenderObject r) {
        if (r is RenderFlex && r.hasSize && r.size.height == 24 && r.constraints.maxWidth < 150 && r.constraints.maxWidth>100) {
          r.visitChildren((ch) { if (ch is RenderParagraph) print('P ${ch.text.toPlainText()} ${ch.size}'); });
        }
        r.visitChildren(walk);
      }
      walk(tester.binding.renderViews.first);
      tester.takeException();
    }
  });
}
