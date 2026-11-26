import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
      final e = tester.takeException();
      if (e != null) { print('STEP $i: ${e.toString().split("\n").first}'); }
    }
  });
}
