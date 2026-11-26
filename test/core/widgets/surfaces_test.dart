import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';

import '../test_app.dart';

void main() {
  group('FolderTab / FolderTabs / PageFrame', () {
    testWidgets('FolderTab usa cartolina e altura do separador', (
      tester,
    ) async {
      await pumpApp(tester, const FolderTab(label: 'Ribeira Seguros'));
      expect(find.text('Ribeira Seguros'), findsOneWidget);
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Ribeira Seguros'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((box.decoration! as BoxDecoration).color, AppColors.cartolina);
      expect(
        tester.getSize(find.text('Ribeira Seguros')).height,
        lessThanOrEqualTo(AppSize.separadorAltura),
      );
    });

    testWidgets('FolderTabs: troca de separador e alvo >= 48', (tester) async {
      var selected = 0;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FolderTabs(
            items: const [
              FolderTabItem(label: 'Sou cliente'),
              FolderTabItem(label: 'Trabalho num escritório'),
            ],
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      );
      final a = tester.getSize(find.text('Sou cliente'));
      expect(a.width, greaterThan(0));
      await tester.tap(find.text('Trabalho num escritório'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      final semantics = tester.getSemantics(find.byType(AppPressable).last);
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    });

    testWidgets('FolderTabs reparte 50/50', (tester) async {
      await pumpApp(
        tester,
        FolderTabs(
          items: const [
            FolderTabItem(label: 'A'),
            FolderTabItem(label: 'B'),
          ],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        width: 400,
      );
      final r = tester.getRect(find.byType(AppPressable).first);
      expect(r.width, 200);
      expect(r.height, greaterThanOrEqualTo(AppSize.alvoMinimo));
    });

    testWidgets('PageFrame: margens por breakpoint e largura máxima', (
      tester,
    ) async {
      Future<Rect> content(double w) async {
        await pumpApp(
          tester,
          const PageFrame(
            tabLabel: 'Os meus dados',
            maxWidth: AppSize.larguraLeitura,
            child: SizedBox(key: Key('c'), height: 10, width: double.infinity),
          ),
          width: w,
        );
        return tester.getRect(find.byKey(const Key('c')));
      }

      final compact = await content(390);
      expect(compact.left, AppSpace.s16);
      expect(compact.width, 390 - 2 * AppSpace.s16);
      final medium = await content(800);
      expect(medium.left, AppSpace.s32);
      final wide = await content(1400);
      expect(wide.left, AppSpace.s48);
      expect(wide.width, AppSize.larguraLeitura);
      expect(find.text('ProDossier'), findsOneWidget);
    });

    testWidgets('PageFrame mantém a barra fixa visível', (tester) async {
      await pumpApp(
        tester,
        const PageFrame(
          tabLabel: 'Pedido de acesso',
          bottom: Text('barra'),
          child: SizedBox(height: 3000),
        ),
        height: 600,
      );
      expect(find.text('barra'), findsOneWidget);
    });
  });

  group('StatusStamp', () {
    testWidgets('mostra ícone + palavra para cada estado', (tester) async {
      await pumpApp(
        tester,
        const Column(
          children: [
            StatusStamp(status: StampStatus.ativo),
            StatusStamp(status: StampStatus.pendente),
            StatusStamp(status: StampStatus.recusado),
            StatusStamp(status: StampStatus.retirado),
          ],
        ),
      );
      for (final w in ['ATIVO', 'PENDENTE', 'RECUSADO', 'RETIRADO']) {
        expect(find.text(w), findsOneWidget);
      }
      expect(find.byType(Icon), findsNWidgets(4));
    });

    testWidgets('semântica em texto e cross-fade ao mudar de estado', (
      tester,
    ) async {
      Widget stamp(StampStatus s) => StatusStamp(
        status: s,
        semanticsDetail: 'desde 12 de novembro de 2026',
      );
      await pumpApp(tester, stamp(StampStatus.pendente));
      expect(
        find.bySemanticsLabel('Estado: pendente desde 12 de novembro de 2026'),
        findsOneWidget,
      );
      await pumpApp(tester, stamp(StampStatus.ativo));
      await tester.pumpAndSettle();
      expect(find.text('PENDENTE'), findsNothing);
      expect(find.text('ATIVO'), findsOneWidget);
    });

    testWidgets('contorno de 1.5 na cor do estado e fundo folha', (
      tester,
    ) async {
      await pumpApp(tester, const StatusStamp(status: StampStatus.ativo));
      final deco =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(StatusStamp),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(deco.color, AppColors.folha);
      final border = deco.border! as Border;
      expect(border.top.color, AppColors.estadoAtivo);
      expect(border.top.width, AppStroke.controlo);
    });
  });

  group('LabeledField', () {
    testWidgets('rótulo por cima e erro por baixo com ícone', (tester) async {
      final c = TextEditingController();
      await pumpApp(
        tester,
        LabeledField(
          label: 'Email',
          controller: c,
          errorText: 'Escreva o seu email.',
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Escreva o seu email.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      final labelY = tester.getTopLeft(find.text('Email')).dy;
      final fieldY = tester.getTopLeft(find.byType(TextField)).dy;
      final errY = tester.getTopLeft(find.text('Escreva o seu email.')).dy;
      expect(labelY, lessThan(fieldY));
      expect(errY, greaterThan(fieldY));
    });

    testWidgets('escreve e notifica; sem erro não há ícone', (tester) async {
      String? last;
      await pumpApp(
        tester,
        LabeledField(label: 'Email', onChanged: (v) => last = v),
      );
      await tester.enterText(find.byType(TextField), 'a@b.pt');
      expect(last, 'a@b.pt');
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(AppSize.campo),
      );
    });

    testWidgets('readOnly bloqueia escrita (a carregar)', (tester) async {
      final c = TextEditingController(text: 'x');
      await pumpApp(
        tester,
        LabeledField(label: 'Email', controller: c, readOnly: true),
      );
      await tester.enterText(find.byType(TextField), 'y');
      expect(c.text, 'x');
    });
  });

  group('RuledList / RuledRow / SkeletonRows', () {
    testWidgets('linhas sem onTap não são clicáveis; com onTap são', (
      tester,
    ) async {
      var taps = 0;
      await pumpApp(
        tester,
        RuledList(
          children: [
            const RuledRow(child: Text('Sem ação')),
            RuledRow(onTap: () => taps++, child: const Text('Com ação')),
          ],
        ),
      );
      await tester.tap(find.text('Sem ação'));
      expect(taps, 0);
      await tester.tap(find.text('Com ação'));
      expect(taps, 1);
      // Réguas: topo + entre linhas + fundo = 3.
      expect(find.byType(AppRule), findsNWidgets(3));
    });

    testWidgets('realce desvanece até desaparecer', (tester) async {
      await pumpApp(
        tester,
        const RuledRow(highlight: true, child: Text('Nova')),
      );
      ColoredBox box() => tester.widget<ColoredBox>(
        find
            .ancestor(of: find.text('Nova'), matching: find.byType(ColoredBox))
            .first,
      );
      expect(box().color, isNot(AppColors.nenhuma));
      await tester.pumpAndSettle();
      expect(box().color, AppColors.nenhuma);
    });

    testWidgets('SkeletonRows pulsa e respeita reduzir movimento', (
      tester,
    ) async {
      await pumpApp(tester, const SkeletonRows(count: 3));
      expect(find.bySemanticsLabel('A carregar'), findsOneWidget);
      final fade = find.descendant(
        of: find.byType(SkeletonRows),
        matching: find.byType(FadeTransition),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final op = tester.widget<FadeTransition>(fade.first).opacity.value;
      expect(op, lessThan(1));
      expect(op, greaterThanOrEqualTo(0.55));

      await pumpApp(
        tester,
        const SkeletonRows(count: 3),
        disableAnimations: true,
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
    });
  });

  group('OfflineBar / InlineNotice', () {
    testWidgets('OfflineBar entra e sai', (tester) async {
      Widget bar(bool v) => OfflineBar(visible: v);
      await pumpApp(tester, bar(false));
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      await pumpApp(tester, bar(true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.textContaining('Sem ligação à internet'), findsOneWidget);
      await pumpApp(tester, bar(false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets('InlineNotice mostra mensagem, ícone e ação', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        InlineNotice(
          message: 'Não foi possível carregar a lista.',
          kind: NoticeKind.erro,
          actionLabel: 'Tentar de novo',
          onAction: () => taps++,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar a lista.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      expect(taps, 1);
    });

    testWidgets('InlineNotice sem movimento aparece logo', (tester) async {
      await pumpApp(
        tester,
        const InlineNotice(message: 'Acesso retirado.'),
        disableAnimations: true,
      );
      await tester.pump();
      expect(find.text('Acesso retirado.'), findsOneWidget);
    });
  });

  group('ConfirmSheet', () {
    Widget launcher({
      bool destructive = true,
      bool readOnly = false,
      bool short = false,
    }) {
      return Builder(
        builder: (context) => TextAction(
          label: 'abrir',
          onPressed: () => showConfirmSheet<bool>(
            context,
            builder: (ctx) => ConfirmSheet(
              title: 'Retirar o acesso da Ribeira Seguros?',
              message: 'A partir de agora, ninguém vê os seus dados.',
              confirmLabel: readOnly
                  ? null
                  : (short ? 'Sim' : 'Retirar acesso'),
              cancelLabel: readOnly ? 'Fechar' : (short ? 'Não' : 'Cancelar'),
              destructive: destructive,
              onConfirm: readOnly ? null : () => Navigator.of(ctx).pop(true),
            ),
          ),
        ),
      );
    }

    testWidgets('compacto: folha inferior, destrutivo em cima do Cancelar', (
      tester,
    ) async {
      await pumpApp(tester, launcher(), width: 390);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      final confirm = tester.getTopLeft(find.text('Retirar acesso')).dy;
      final cancel = tester.getTopLeft(find.text('Cancelar')).dy;
      expect(confirm, lessThan(cancel));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('largo: diálogo de 480 com botões lado a lado', (tester) async {
      await pumpApp(tester, launcher(short: true), width: 1280);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      final dialog = tester.getRect(
        find
            .ancestor(
              of: find.byType(ConfirmSheet),
              matching: find.byType(Material),
            )
            .last,
      );
      expect(dialog.width, lessThanOrEqualTo(AppSize.dialogo));
      final confirm = tester.getTopLeft(find.text('Sim'));
      final cancel = tester.getTopLeft(find.text('Não'));
      expect(confirm.dy, cancel.dy);
      expect(cancel.dx, lessThan(confirm.dx));
      await tester.tap(find.text('Sim'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmSheet), findsNothing);
    });

    testWidgets('Esc fecha o diálogo', (tester) async {
      await pumpApp(tester, launcher(), width: 1280);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmSheet), findsNothing);
    });

    testWidgets('a enviar: cancelar fica desativado; erro aparece dentro', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ConfirmSheet(
          title: 'T',
          confirmLabel: 'Retirar acesso',
          loadingLabel: 'A retirar…',
          loading: true,
          errorMessage: 'Não foi possível retirar o acesso.',
          onConfirm: () {},
        ),
        width: 1280,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('A retirar…'), findsOneWidget);
      expect(find.text('Não foi possível retirar o acesso.'), findsOneWidget);
      final cancel = tester.widget<SecondaryButton>(
        find.byType(SecondaryButton),
      );
      expect(cancel.onPressed, isNull);
    });

    testWidgets('só de leitura: um único botão de fechar', (tester) async {
      await pumpApp(tester, launcher(readOnly: true), width: 1280);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(DestructiveButton), findsNothing);
      expect(find.text('Fechar'), findsOneWidget);
    });
  });
}
