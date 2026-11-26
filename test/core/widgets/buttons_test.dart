import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

void main() {
  testWidgets('PrimaryButton chama onPressed e tem alvo >= 48', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: PrimaryButton(label: 'Entrar', onPressed: () => taps++),
      ),
    );
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(PrimaryButton)).height,
      greaterThanOrEqualTo(AppSize.alvoMinimo),
    );
  });

  testWidgets('PrimaryButton principal tem 56 de altura', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: PrimaryButton(
          label: 'Aceitar',
          principal: true,
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(PrimaryButton)).height,
      AppSize.alvoPrincipal,
    );
  });

  testWidgets('desativado mostra a razão por baixo e não reage', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: PrimaryButton(
          label: 'Responder',
          onPressed: null,
          disabledReason: 'Precisa de ligação.',
        ),
      ),
    );
    expect(find.text('Precisa de ligação.'), findsOneWidget);
  });

  testWidgets('a carregar: não reage e o spinner é só do botão', (
    tester,
  ) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: PrimaryButton(
          label: 'Enviar link',
          loadingLabel: 'A enviar…',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('A enviar…'), findsOneWidget);
  });

  testWidgets('Enter ativa o botão focado (teclado)', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: SecondaryButton(label: 'Cancelar', onPressed: () => taps++),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('DestructiveButton e SecondaryButton disparam', (tester) async {
    var a = 0, b = 0;
    await pumpApp(
      tester,
      Column(
        children: [
          DestructiveButton(label: 'Retirar acesso', onPressed: () => a++),
          SecondaryButton(label: 'Cancelar', onPressed: () => b++),
        ],
      ),
    );
    await tester.tap(find.byType(DestructiveButton));
    await tester.tap(find.byType(SecondaryButton));
    expect([a, b], [1, 1]);
  });

  testWidgets('TextAction desativada escreve a razão por baixo', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: TextAction(
          label: 'Enviar outra vez',
          onPressed: null,
          disabledReason: 'Pode enviar outra vez daqui a 1 minuto.',
        ),
      ),
    );
    expect(
      find.text('Pode enviar outra vez daqui a 1 minuto.'),
      findsOneWidget,
    );
  });

  testWidgets('TextAction ativa dispara', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      Center(
        child: TextAction(label: 'Reenviar pedido', onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Reenviar pedido'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(TextAction)).height,
      greaterThanOrEqualTo(AppSize.alvoMinimo),
    );
  });
}
