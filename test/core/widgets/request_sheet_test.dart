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

Widget _sheet({
  bool editable = true,
  VoidCallback? onTirar,
  VoidCallback? onAdd,
  VoidCallback? onRestore,
  int removed = 1,
}) => SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(AppSpace.s16),
    child: RequestSheet(
      title: 'Automóvel',
      indexLabel: 'Pedido 1 de 2',
      notes: const [
        'Se o condutor habitual não for o tomador, envie também o Cartão de Cidadão.',
      ],
      editable: editable,
      onAddItem: onAdd,
      removedCount: removed,
      onRestore: onRestore,
      items: [
        RequestItemRow(
          kind: RequestItemKind.documento,
          text: 'Documento Único Automóvel (DUA / livrete)',
          contextLabel: 'do pedido de Automóvel',
          onAction: editable ? onTirar : null,
        ),
        RequestItemRow(
          kind: RequestItemKind.dado,
          text: 'Matrícula',
          free: true,
          onAction: editable ? onTirar : null,
        ),
      ],
    ),
  ),
);

void main() {
  for (final e in _sizes.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('RequestSheet ${e.key} x$scale sem overflow', (t) async {
        for (final editable in [true, false]) {
          await pumpApp(
            t,
            _sheet(
              editable: editable,
              onTirar: () {},
              onAdd: () {},
              onRestore: () {},
            ),
            width: e.value,
            textScale: scale,
          );
          expect(t.takeException(), isNull);
          expect(find.text('Acrescentado neste pedido'), findsOneWidget);
        }
      });
    }
  }

  testWidgets('RequestItemRow: alvo da ação >= 48 e semântica sem repetição', (
    t,
  ) async {
    final h = t.ensureSemantics();
    var n = 0;
    await pumpApp(
      t,
      RequestSheet(
        title: 'Automóvel',
        editable: true,
        onAddItem: () {},
        items: [
          RequestItemRow(
            kind: RequestItemKind.dado,
            text: 'Morada',
            contextLabel: 'do pedido de Automóvel',
            onAction: () => n++,
          ),
        ],
      ),
      width: 1280,
    );
    expect(find.bySemanticsLabel('Dado: Morada'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tirar Morada do pedido de Automóvel'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Acrescentar item do pedido de Automóvel'),
      findsOneWidget,
    );
    await t.tap(find.text('Tirar'));
    expect(n, 1);
    expect(
      t.getSize(find.byType(TextAction).first).height,
      greaterThanOrEqualTo(48),
    );
    h.dispose();
  });

  testWidgets(
    'RequestSheet leitura: sem rodapé nem superfície; vazio mostra aviso',
    (t) async {
      await pumpApp(
        t,
        const RequestSheet(items: [], emptyNotice: Text('Lista vazia')),
      );
      expect(find.text('Lista vazia'), findsOneWidget);
      expect(find.text('Acrescentar item'), findsNothing);
    },
  );

  testWidgets('RequestSheet editável: repor lista e contagem', (t) async {
    var restored = 0;
    await pumpApp(
      t,
      _sheet(onRestore: () => restored++, onAdd: () {}, removed: 2),
      width: 1280,
    );
    expect(find.text('2 itens tirados · '), findsOneWidget);
    await t.tap(find.text('Repor lista'));
    expect(restored, 1);
  });

  group('PageFrame com sino e regresso', () {
    for (final e in _sizes.entries) {
      testWidgets('${e.key}: sino antes de Sair, regresso, sem overflow', (
        t,
      ) async {
        var back = 0;
        var bell = 0;
        await pumpApp(
          t,
          PageFrame(
            tabLabel: 'Os meus dados',
            onSignOut: () {},
            onNotifications: () => bell++,
            unreadNotifications: 2,
            backLabel: 'Os meus pedidos',
            onBack: () => back++,
            child: const Text('conteúdo'),
          ),
          width: e.value,
          height: 800,
          textScale: 1.3,
        );
        expect(t.takeException(), isNull);
        expect(find.text('2'), findsOneWidget);
        final bellX = t.getCenter(find.byType(NotificationBell)).dx;
        final signX = t.getCenter(find.text('Sair')).dx;
        expect(bellX, lessThan(signX));
        await t.tap(find.byType(NotificationBell));
        await t.tap(find.text('Os meus pedidos'));
        expect(bell, 1);
        expect(back, 1);
      });
    }

    testWidgets('sem dados do sino não aparece', (t) async {
      await pumpApp(
        t,
        PageFrame(tabLabel: 'X', onSignOut: () {}, child: const Text('c')),
      );
      expect(find.byType(NotificationBell), findsNothing);
    });
  });
}
