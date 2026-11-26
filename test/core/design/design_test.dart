import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/design/typography.dart';

void main() {
  test('breakpoints: compacto < 640, medio 640 a 1100, largo > 1100', () {
    expect(AppBreakpoints.of(639), Breakpoint.compacto);
    expect(AppBreakpoints.of(640), Breakpoint.medio);
    expect(AppBreakpoints.of(1100), Breakpoint.medio);
    expect(AppBreakpoints.of(1101), Breakpoint.largo);
  });

  test('margens laterais 16 / 32 / 48', () {
    expect(AppBreakpoints.margin(Breakpoint.compacto), 16);
    expect(AppBreakpoints.margin(Breakpoint.medio), 32);
    expect(AppBreakpoints.margin(Breakpoint.largo), 48);
  });

  test('tokens principais batem com o DESIGN.md', () {
    expect(AppColors.papel, const Color(0xFFF6F3EC));
    expect(AppColors.estadoInativo, AppColors.tintaTenue);
    expect(AppColors.sobreTinta, AppColors.papel);
    expect(AppSize.alvoMinimo, 48);
    expect(AppSize.alvoPrincipal, 56);
    expect(AppSize.campo, 52);
    expect(AppRadius.carimbo, 3);
    expect(AppStroke.controlo, 1.5);
  });

  test('tipografia: tamanhos, alturas e famílias', () {
    expect(AppType.numero.fontSize, 56);
    expect(AppType.numero.height! * 56, closeTo(60, 0.001));
    expect(AppType.titulo.fontFamily, AppType.serif);
    expect(AppType.tituloCompacto.fontSize, 26);
    expect(AppType.corpo.fontFamily, AppType.sans);
    expect(AppType.registo.fontFamily, AppType.mono);
    expect(AppType.carimbo.fontWeight, FontWeight.w700);
    expect(AppType.tituloPara(Breakpoint.compacto), AppType.tituloCompacto);
    expect(AppType.tituloPara(Breakpoint.largo), AppType.titulo);
  });

  test('tema: papel como fundo, tinta como primária, sem AppBar', () {
    final t = AppTheme.light();
    expect(t.useMaterial3, isTrue);
    expect(t.scaffoldBackgroundColor, AppColors.papel);
    expect(t.colorScheme.primary, AppColors.tinta);
    expect(t.colorScheme.error, AppColors.erro);
    expect(t.textTheme.bodyLarge!.fontFamily, AppType.corpo.fontFamily);
    expect(t.textTheme.bodyLarge!.fontSize, AppType.corpo.fontSize);
    expect(t.textTheme.bodyLarge!.color, AppColors.tinta);
  });
}
