import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/design/typography.dart';
import 'package:promediacao/core/format/dates.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

void main() {
  test('AppType.marca: serifa 19/24, -0.2; "Pro" itálico tintaMedia', () {
    expect(AppType.marca.fontFamily, AppType.serif);
    expect(AppType.marca.fontSize, 19);
    expect(AppType.marca.height! * 19, closeTo(24, 0.01));
    expect(AppType.marca.letterSpacing, -0.2);
    expect(AppType.marca.fontWeight, FontWeight.w600);
    expect(AppType.marcaPro.fontStyle, FontStyle.italic);
    expect(AppType.marcaPro.color, AppColors.tintaMedia);
  });

  testWidgets('Wordmark lê-se "ProDossier", numa palavra', (tester) async {
    await pumpApp(tester, const Wordmark());
    expect(find.bySemanticsLabel('ProDossier'), findsOneWidget);
  });

  test('datas por extenso curto', () {
    final d = DateTime(2026, 11, 26, 14, 32);
    expect(AppDates.date(d), '26 nov 2026');
    expect(AppDates.dateTime(d), '26 nov 2026, 14:32');
    expect(AppDates.date(DateTime(2026, 2, 3)), '3 fev 2026');
  });

  group('Colophon', () {
    const identity = 'Dossiê de Maria do Carmo Figueiredo';
    const record = 'Aberto a 12 nov 2026';

    Widget frame(Widget c) => SingleChildScrollView(child: c);

    testWidgets('largo: uma linha alinhada pela base', (tester) async {
      await pumpApp(
        tester,
        frame(const Colophon(identity: identity, record: record)),
        width: 1280,
      );
      final mark = tester.getRect(find.byType(Wordmark));
      final line = tester.getRect(find.text(identity));
      final reg = tester.getRect(find.text(record));
      expect(line.left, greaterThan(mark.right));
      expect(reg.left, greaterThan(line.right));
      expect(line.top, lessThan(mark.bottom));
    });

    testWidgets('compacto: empilhado à esquerda, sem reticências', (
      tester,
    ) async {
      await pumpApp(
        tester,
        frame(const Colophon(identity: identity, record: record)),
        width: 390,
      );
      final mark = tester.getRect(find.byType(Wordmark));
      final line = tester.getRect(find.text(identity));
      final reg = tester.getRect(find.text(record));
      expect(line.left, mark.left);
      expect(line.top, mark.bottom + AppSpace.s4);
      expect(reg.top, greaterThan(line.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('médio com escala 1.3 e nome longo: passa a empilhado', (
      tester,
    ) async {
      const long =
          'Dossiê de João Pedro Albuquerque de Vasconcelos Sampaio, Gabinete';
      await pumpApp(
        tester,
        frame(const Colophon(identity: long, record: record)),
        width: 768,
        textScale: 1.3,
      );
      final mark = tester.getRect(find.byType(Wordmark));
      expect(tester.getRect(find.text(long)).left, mark.left);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a carregar: só o wordmark; a linha entra depois', (
      tester,
    ) async {
      final id = ValueNotifier<String?>(null);
      addTearDown(id.dispose);
      await pumpApp(
        tester,
        frame(
          ValueListenableBuilder<String?>(
            valueListenable: id,
            builder: (context, v, _) => Colophon(identity: v),
          ),
        ),
        width: 1280,
      );
      expect(find.byType(Wordmark), findsOneWidget);
      expect(find.text(identity), findsNothing);
      id.value = identity;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final fading = tester.widget<Opacity>(
        find.ancestor(of: find.text(identity), matching: find.byType(Opacity)),
      );
      expect(fading.opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(find.text(identity), findsOneWidget);
    });

    testWidgets('sem sessão: frase sem registo; nada focável', (tester) async {
      await pumpApp(tester, frame(const Colophon.signedOut()));
      expect(find.text(Colophon.signedOutLine), findsOneWidget);
      expect(find.byType(AppPressable), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });
  });
}
