import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

void main() {
  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    testWidgets(
      'PageFrame: "Sair" responde em toda a área de 48 (${size.width.toInt()}x${size.height.toInt()})',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var taps = 0;
        await pumpApp(
          tester,
          PageFrame(
            tabLabel: 'Os meus dados',
            accountName: 'Ana Martins',
            onSignOut: () => taps++,
            child: const SizedBox(height: 100),
          ),
        );
        final rect = tester.getRect(find.byType(TextAction));
        expect(rect.height, greaterThanOrEqualTo(AppSize.alvoMinimo));
        final tab = tester.getRect(find.byType(FolderTab));
        expect(rect.center.dy, closeTo(tab.center.dy, 0.5));

        // Toques perto do topo e do fundo do alvo, fora do separador (40).
        for (final dy in [rect.top + 1, rect.bottom - 1]) {
          await tester.tapAt(Offset(rect.center.dx, dy));
        }
        expect(taps, 2);
      },
    );
  }

  test('Wordmark: itálico da Source Serif 4 declarado e incluído', () {
    expect(
      File('assets/fonts/SourceSerif4-Italic-Variable.ttf').existsSync(),
      isTrue,
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(
        'asset: assets/fonts/SourceSerif4-Italic-Variable.ttf\n'
        '          style: italic',
      ),
    );
  });
}
