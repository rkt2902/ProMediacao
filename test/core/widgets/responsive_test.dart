import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

const _sizes = <(String, double, double)>[
  ('390x844', 390, 844),
  ('768x1024', 768, 1024),
  ('1280x800', 1280, 800),
  ('320x640', 320, 640),
];

void main() {
  group('tokens de responsividade', () {
    test('valores do DESIGN.md', () {
      expect(AppSize.larguraFormulario, 400);
      expect(AppSize.textoMinimo, 240);
      expect(AppSize.linhaTabela, 72);
      expect(AppSize.colunaEstado, 152);
      expect(AppSize.colunaData, 248);
      expect(AppSize.colunaAcao, 160);
      expect(AppBreakpoints.alturaBaixa, 480);
    });
  });

  group('PageFrame', () {
    for (final (name, w, h) in _sizes) {
      testWidgets('$name: sem overflow, moldura e barra alinhadas', (
        tester,
      ) async {
        await pumpApp(
          tester,
          PageFrame(
            tabLabel: 'Os meus dados',
            maxWidth: AppSize.larguraLeitura,
            accountName: 'Ana Martins',
            onSignOut: () {},
            bottom: const SizedBox(
              key: Key('bar'),
              height: 56,
              width: double.infinity,
            ),
            child: const SizedBox(
              key: Key('c'),
              height: 10,
              width: double.infinity,
            ),
          ),
          width: w,
          height: h,
        );
        expect(tester.takeException(), isNull);
        final bp = AppBreakpoints.of(w);
        final margin = AppBreakpoints.margin(bp);
        final frameLeft = bp == Breakpoint.largo
            ? (w - AppSize.larguraLista) / 2
            : margin;
        final content = tester.getRect(find.byKey(const Key('c')));
        final bar = tester.getRect(find.byKey(const Key('bar')));
        final tab = tester.getRect(find.byType(FolderTab));
        expect(content.left, frameLeft);
        // Sem marca nem cabeçalho: o separador é a primeira linha.
        expect(find.text('ProDossier'), findsNothing);
        expect(tab.left, frameLeft);
        expect(
          tab.top,
          bp == Breakpoint.compacto ? AppSpace.s16 : AppSpace.s24,
        );
        // "Sair" na linha do separador, centrado com ele.
        final sair = tester.getRect(find.byType(AppPressable));
        // (se o separador passar a duas linhas, "Sair" fica com a 1.ª linha).
        expect(
          sair.center.dy,
          closeTo(tab.top + AppSize.separadorAltura / 2, 0.5),
        );
        expect(sair.height, greaterThanOrEqualTo(AppSize.alvoMinimo));
        // Régua por baixo do separador à largura da moldura.
        final frameWidth = bp == Breakpoint.largo
            ? AppSize.larguraLista
            : w - 2 * margin;
        final rule = tester.getRect(find.byType(AppRule).first);
        expect(rule.top, tab.bottom);
        expect(rule.width, frameWidth);
        expect(bar.left, content.left);
        expect(bar.width, content.width);
        expect(content.right, lessThanOrEqualTo(w - margin));
        // Fundo da barra ocupa a largura da janela.
        final bg = tester.getRect(
          find
              .ancestor(
                of: find.byKey(const Key('bar')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(bg.width, w);
      });
    }

    testWidgets('largo: separador e conta nas pontas da moldura de 1040', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PageFrame(
          tabLabel: 'Ribeira Seguros',
          accountName: 'Ana Martins',
          onSignOut: () {},
          child: const SizedBox(height: 10),
        ),
        width: 1280,
        height: 800,
      );
      expect(tester.getTopLeft(find.byType(FolderTab)).dx, 120);
      final sair = tester.getRect(find.text('Sair'));
      expect(sair.right, lessThanOrEqualTo(120 + AppSize.larguraLista));
      expect(sair.right, greaterThan(120 + AppSize.larguraLista - 40));
    });

    testWidgets('conta: compacto só "Sair"; médio e largo com nome', (
      tester,
    ) async {
      Future<void> pump(double w) => pumpApp(
        tester,
        PageFrame(
          tabLabel: 'Ribeira Seguros',
          accountName: 'Ana Martins',
          onSignOut: () {},
          child: const SizedBox(height: 10),
        ),
        width: w,
        height: 800,
      );
      await pump(390);
      expect(find.text('Ana Martins'), findsNothing);
      expect(find.text('Sair'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sair da conta de Ana Martins'),
        findsOneWidget,
      );
      final size = tester.getSize(find.byType(AppPressable));
      expect(size.height, greaterThanOrEqualTo(AppSize.alvoMinimo));
      expect(size.width, greaterThanOrEqualTo(AppSize.alvoMinimo));
      for (final w in [768.0, 1280.0]) {
        await pump(w);
        expect(find.text('Ana Martins'), findsOneWidget);
        expect(find.text('Sair'), findsOneWidget);
      }
    });

    for (final (name, w, h) in _sizes) {
      testWidgets('$name: colofão encosta ao fundo quando o conteúdo é curto', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const PageFrame(
            tabLabel: 'Acesso',
            maxWidth: AppSize.larguraFormulario,
            colophon: Colophon.signedOut(),
            child: SizedBox(height: 10),
          ),
          width: w,
          height: h,
        );
        expect(tester.takeException(), isNull);
        final colophon = tester.getRect(find.byType(Colophon));
        expect(colophon.bottom, h);
        final bp = AppBreakpoints.of(w);
        final frameWidth = bp == Breakpoint.largo
            ? AppSize.larguraLista
            : w - 2 * AppBreakpoints.margin(bp);
        // Régua do colofão à largura da moldura, mesmo com coluna de 400.
        final rule = tester.getRect(
          find.descendant(
            of: find.byType(Colophon),
            matching: find.byType(AppRule),
          ),
        );
        expect(rule.width, frameWidth);
      });
    }

    testWidgets('colofão só no fim do scroll quando o conteúdo é longo', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const PageFrame(
          tabLabel: 'Acesso',
          colophon: Colophon.signedOut(),
          child: SizedBox(height: 2000),
        ),
        width: 390,
        height: 844,
      );
      expect(find.text(Colophon.signedOutLine), findsNothing);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text(Colophon.signedOutLine), findsOneWidget);
    });

    testWidgets('altura baixa: barra com padding s8', (tester) async {
      await pumpApp(
        tester,
        const PageFrame(
          tabLabel: 'Pedido de acesso',
          bottom: SizedBox(key: Key('bar'), height: 48),
          child: SizedBox(height: 10),
        ),
        width: 640,
        height: 360,
      );
      final bar = tester.getRect(find.byKey(const Key('bar')));
      expect(tester.getSize(find.byType(Material).first).height, 360);
      expect(360 - bar.bottom, AppSpace.s8);
    });
  });

  group('TextAction', () {
    testWidgets('desativado escreve a razão por baixo', (tester) async {
      await pumpApp(
        tester,
        const TextAction(
          label: 'Enviar outra vez',
          onPressed: null,
          disabledReason: 'Pode pedir outro link dentro de 60 segundos.',
        ),
        width: 390,
      );
      final action = tester.getRect(find.text('Enviar outra vez'));
      final reason = tester.getRect(
        find.text('Pode pedir outro link dentro de 60 segundos.'),
      );
      expect(reason.top, greaterThanOrEqualTo(action.bottom));
      expect(find.byType(Tooltip), findsNothing);
    });

    for (final (name, w, h) in _sizes) {
      testWidgets('$name: alvo >= 48 e foco automático só fora de compacto', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const TextAction(
            label: 'Sair',
            icon: Icons.logout,
            onPressed: _noop,
            autofocus: true,
          ),
          width: w,
          height: h,
        );
        final r = tester.getRect(find.byType(AppPressable));
        expect(r.height, greaterThanOrEqualTo(AppSize.alvoMinimo));
        expect(r.width, greaterThanOrEqualTo(AppSize.alvoMinimo));
        final focused = FocusManager.instance.primaryFocus;
        final compact = AppBreakpoints.of(w) == Breakpoint.compacto;
        expect(focused != null && _isInside(focused), !compact);
      });
    }
  });

  group('ConfirmSheet', () {
    final originKey = GlobalKey();
    Widget launcher({bool readOnly = false}) => Builder(
      builder: (context) => TextAction(
        key: originKey,
        label: 'abrir',
        autofocus: true,
        onPressed: () => showConfirmSheet<bool>(
          context,
          readOnly: readOnly,
          builder: (ctx) => ConfirmSheet(
            title: readOnly ? 'Texto aceite' : 'Retirar o acesso?',
            message: readOnly ? null : 'Ninguém verá os seus dados.',
            body: readOnly
                ? Text(List.filled(200, 'Texto de consentimento.').join(' '))
                : null,
            confirmLabel: readOnly ? null : 'Retirar acesso',
            cancelLabel: readOnly ? 'Fechar' : 'Cancelar',
            onConfirm: readOnly ? null : () => Navigator.of(ctx).pop(true),
          ),
        ),
      ),
    );

    for (final (name, w, h) in _sizes) {
      testWidgets('$name: decisão sem overflow, foco inicial em Cancelar', (
        tester,
      ) async {
        await pumpApp(tester, launcher(), width: w, height: h);
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final compact = AppBreakpoints.of(w) == Breakpoint.compacto;
        expect(find.byType(BottomSheet).evaluate().length, compact ? 1 : 0);
        if (!compact) {
          // Enter com o foco inicial cancela, nunca retira o acesso.
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.byType(ConfirmSheet), findsNothing);
        }
      });

      testWidgets('$name: só de leitura, texto longo com scroll', (
        tester,
      ) async {
        await pumpApp(tester, launcher(readOnly: true), width: w, height: h);
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final sheet = tester.getRect(find.byType(ConfirmSheet));
        final compact = AppBreakpoints.of(w) == Breakpoint.compacto;
        if (compact) {
          expect(sheet.width, w);
          expect(sheet.top, greaterThanOrEqualTo(AppSpace.s48 - 1));
          expect(sheet.height, greaterThan(h / 2));
        } else {
          expect(sheet.width, AppSize.larguraLeitura);
          expect(sheet.height, lessThanOrEqualTo(h - 2 * AppSpace.s48));
        }
        // "Fechar" fica visível sem fazer scroll.
        expect(
          tester.getRect(find.text('Fechar')).bottom,
          lessThanOrEqualTo(h),
        );
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    }

    testWidgets('altura baixa: folha ocupa a janela menos s16', (tester) async {
      await pumpApp(tester, launcher(readOnly: true), width: 560, height: 360);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(find.byType(BottomSheet));
      expect(sheet.top, AppSpace.s16);
    });

    testWidgets('"voltar" fecha a folha (compacto e largo)', (tester) async {
      for (final w in [390.0, 1280.0]) {
        await pumpApp(tester, launcher(), width: w, height: 800);
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmSheet), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmSheet), findsNothing);
      }
    });

    testWidgets('Esc fecha a folha em compacto', (tester) async {
      await pumpApp(tester, launcher(), width: 390, height: 800);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmSheet), findsNothing);
    });

    testWidgets('ao fechar, o foco volta ao botão de origem', (tester) async {
      await pumpApp(tester, launcher(), width: 1280, height: 800);
      await tester.pump();
      expect(_isInside(FocusManager.instance.primaryFocus!), isTrue);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_isInside(FocusManager.instance.primaryFocus!), isTrue);
    });
  });
}

void _noop() {}

bool _isInside(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return false;
  var found = false;
  ctx.visitAncestorElements((e) {
    if (e.widget is AppPressable) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
