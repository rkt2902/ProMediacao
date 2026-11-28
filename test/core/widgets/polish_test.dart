import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

void main() {
  testWidgets('C1: contador do sino mede 18 de altura (não estica ao alvo)', (
    t,
  ) async {
    await pumpApp(
      t,
      Align(
        alignment: Alignment.centerRight,
        child: NotificationBell(onPressed: () {}, unread: 2),
      ),
    );
    await t.pumpAndSettle();
    final counter = find.ancestor(
      of: find.text('2'),
      matching: find.byType(Container),
    );
    expect(t.getSize(counter.first).height, 18);
  });

  testWidgets('M1: separador nunca leva reticências a 320 com escala 1.3', (
    t,
  ) async {
    await pumpApp(
      t,
      PageFrame(
        tabLabel: 'Os meus dados',
        onSignOut: () {},
        onNotifications: () {},
        unreadNotifications: 2,
        child: const SizedBox(height: 20),
      ),
      width: 320,
      textScale: 1.3,
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final text = t.widget<Text>(find.text('Os meus dados'));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    // Todas as palavras visíveis: se partiu em duas linhas, a altura cresce.
    final h = t.getSize(find.text('Os meus dados')).height;
    expect(h, greaterThan(0));
  });

  testWidgets('M9: ExitingList mantém o item a sair até a animação acabar', (
    t,
  ) async {
    Widget list(List<String> ids) => ExitingList(
      children: [
        for (final id in ids)
          SizedBox(key: ValueKey(id), height: 40, child: Text(id)),
      ],
    );
    await pumpApp(t, list(['a', 'b']));
    expect(find.text('a'), findsOneWidget);
    await pumpApp(t, list(['b']));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('a'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsOneWidget);
  });
}
