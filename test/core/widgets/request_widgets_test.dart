import 'dart:ui' show CheckedState;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

const _sizes = <String, double>{
  'telemovel': 390,
  'tablet': 768,
  'desktop': 1280,
};
const _steps = [
  StageStripStep(name: 'Pedido criado', date: '27 nov 2026, 10:14'),
  StageStripStep(name: 'Enviado'),
  StageStripStep(name: 'Recebido'),
  StageStripStep(name: 'Concluído'),
];

Color _segColor(WidgetTester t, int i) =>
    t.widget<Container>(find.byKey(ValueKey('segmento-$i'))).color!;

void main() {
  test('tokens 002', () {
    expect(AppStroke.etapa, 4);
    expect(AppSize.colunaEtapa, 200);
    expect(AppSize.segmentoEtapa, 16);
    expect(AppSize.colunaNatureza, 120);
    expect(AppSize.campoMensagem, 128);
    expect(AppSize.marcaNaoLida, 8);
  });

  for (final e in _sizes.entries) {
    for (final scale in [1.0, 1.3]) {
      final tag = '${e.key} x$scale';
      group('002 $tag', () {
        testWidgets('StageTrack e TagLabel sem overflow', (t) async {
          await pumpApp(
            t,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StageTrack(stage: 1, label: 'Pedido criado'),
                TagLabel('Condições particulares'),
              ],
            ),
            width: e.value,
            textScale: scale,
          );
          expect(t.takeException(), isNull);
        });

        testWidgets('StageStrip sem overflow', (t) async {
          await pumpApp(
            t,
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s16),
                child: StageStrip(steps: _steps, current: 2),
              ),
            ),
            width: e.value,
            textScale: scale,
          );
          expect(t.takeException(), isNull);
          expect(find.text('Por fazer'), findsNWidgets(2));
        });

        testWidgets('CheckRow e NotificationBell sem overflow', (t) async {
          await pumpApp(
            t,
            Column(
              children: [
                CheckRow(
                  label: 'Cartão de cidadão',
                  description: 'Frente e verso',
                  checked: true,
                  onChanged: (_) {},
                  trailing: const TagLabel('Documento'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: NotificationBell(onPressed: () {}, unread: 12),
                ),
              ],
            ),
            width: e.value,
            textScale: scale,
          );
          expect(t.takeException(), isNull);
          expect(find.text('9+'), findsOneWidget);
        });
      });
    }
  }

  group('StageTrack', () {
    testWidgets('segmentos e uma só frase', (t) async {
      final h = t.ensureSemantics();
      await pumpApp(t, const StageTrack(stage: 2, label: 'Enviado'));
      expect(_segColor(t, 0), AppColors.tinta);
      expect(_segColor(t, 1), AppColors.tinta);
      expect(_segColor(t, 2), AppColors.regua);
      expect(
        t.getSize(find.byKey(const ValueKey('segmento-0'))),
        const Size(AppSize.segmentoEtapa, AppStroke.etapa),
      );
      expect(find.bySemanticsLabel('Etapa 2 de 4: Enviado'), findsOneWidget);
      expect(find.bySemanticsLabel('Enviado'), findsNothing);
      h.dispose();
    });
  });

  group('StageStrip semântica', () {
    testWidgets('4 itens, feita/por fazer', (t) async {
      final h = t.ensureSemantics();
      await pumpApp(t, StageStrip(steps: _steps, current: 1), width: 1280);
      expect(
        find.bySemanticsLabel(
          'Etapa 1, Pedido criado, feita a 27 nov 2026, 10:14',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Etapa 2, Enviado, por fazer'),
        findsOneWidget,
      );
      h.dispose();
    });
  });

  group('CheckRow', () {
    testWidgets('alterna por toque e teclado, alvo >= 48, semântica única', (
      t,
    ) async {
      final h = t.ensureSemantics();
      var checked = false;
      await pumpApp(
        t,
        StatefulBuilder(
          builder: (c, set) => CheckRow(
            label: 'Recibo',
            checked: checked,
            onChanged: (v) => set(() => checked = v),
          ),
        ),
      );
      expect(t.getSize(find.byType(CheckRow)).height, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel('Recibo'), findsOneWidget);
      await t.tap(find.text('Recibo'));
      await t.pump();
      expect(checked, isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(checked, isFalse);
      final data = t.getSemantics(find.bySemanticsLabel('Recibo'));
      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
      h.dispose();
    });

    testWidgets('desativada não reage', (t) async {
      await pumpApp(
        t,
        const CheckRow(label: 'X', checked: false, onChanged: null),
      );
      await t.tap(find.text('X'));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('NotificationBell', () {
    test('texto do contador', () {
      expect(NotificationBell.counterText(null), isNull);
      expect(NotificationBell.counterText(0), isNull);
      expect(NotificationBell.counterText(1), '1');
      expect(NotificationBell.counterText(9), '9');
      expect(NotificationBell.counterText(10), '9+');
    });

    testWidgets('oculto a 0, visível com 2, leitura única', (t) async {
      final h = t.ensureSemantics();
      await pumpApp(
        t,
        NotificationBell(onPressed: () {}, unread: 0),
        width: 1280,
      );
      expect(find.bySemanticsLabel('Notificações'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await pumpApp(
        t,
        NotificationBell(onPressed: () {}, unread: 2),
        width: 1280,
      );
      await t.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.bySemanticsLabel('Notificações, 2 por ler'), findsOneWidget);
      h.dispose();
    });

    testWidgets('compacto sem palavra; dispara onPressed; alvo 48', (t) async {
      var n = 0;
      await pumpApp(
        t,
        NotificationBell(onPressed: () => n++, unread: 3),
        width: 390,
      );
      expect(find.text('Notificações'), findsNothing);
      final size = t.getSize(find.byType(NotificationBell));
      expect(size.height, greaterThanOrEqualTo(48));
      await t.tap(find.byType(NotificationBell));
      expect(n, 1);
    });
  });

  group('StatusStamp.acessoRetirado', () {
    testWidgets('palavra e leitura', (t) async {
      final h = t.ensureSemantics();
      await pumpApp(t, const StatusStamp(status: StampStatus.acessoRetirado));
      expect(find.text('ACESSO RETIRADO'), findsOneWidget);
      expect(find.bySemanticsLabel('Estado: acesso retirado'), findsOneWidget);
      h.dispose();
    });
  });
}
