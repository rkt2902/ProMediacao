import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Estilos de texto (docs/design/DESIGN.md). Cor `tinta` por defeito;
/// usar `.copyWith(color: ...)` para secundário (`tintaMedia`) ou
/// metadados (`tintaTenue`).
///
/// As fontes vivem em `assets/fonts/` (ficheiros variáveis OFL). O eixo
/// `wght` é fixado com [FontVariation] para o peso ser o mesmo em todas as
/// plataformas.
abstract final class AppType {
  static const String serif = 'SourceSerif4';
  static const String sans = 'AtkinsonHyperlegibleNext';
  static const String mono = 'AtkinsonHyperlegibleMono';

  // Fallbacks explícitos caso uma fonte não carregue.
  static const List<String> _serifFallback = ['Georgia', 'Times New Roman'];
  static const List<String> _sansFallback = ['Roboto', 'Arial'];
  static const List<String> _monoFallback = ['Courier New', 'monospace'];

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _style({
    required String family,
    required List<String> fallback,
    required double size,
    required double line,
    required int weight,
    double letterSpacing = 0,
    List<FontFeature>? features,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      height: line / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
      letterSpacing: letterSpacing,
      fontFeatures: features,
      color: AppColors.tinta,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Contagens do admin: 56/60, 500.
  static final TextStyle numero = _style(
    family: serif,
    fallback: _serifFallback,
    size: 56,
    line: 60,
    weight: 500,
    features: _tabular,
  );

  /// Título do ecrã: 30/36, 600.
  static final TextStyle titulo = _style(
    family: serif,
    fallback: _serifFallback,
    size: 30,
    line: 36,
    weight: 600,
  );

  /// Título em compacto: 26/32, 600.
  static final TextStyle tituloCompacto = _style(
    family: serif,
    fallback: _serifFallback,
    size: 26,
    line: 32,
    weight: 600,
  );

  /// Nome do escritório numa linha, título de diálogo: 21/28, 600.
  static final TextStyle subtitulo = _style(
    family: serif,
    fallback: _serifFallback,
    size: 21,
    line: 28,
    weight: 600,
  );

  static final TextStyle corpoForte = _style(
    family: sans,
    fallback: _sansFallback,
    size: 17,
    line: 26,
    weight: 600,
  );

  static final TextStyle corpo = _style(
    family: sans,
    fallback: _sansFallback,
    size: 17,
    line: 26,
    weight: 400,
  );

  static final TextStyle corpoPequeno = _style(
    family: sans,
    fallback: _sansFallback,
    size: 15,
    line: 22,
    weight: 400,
  );

  /// Rótulos de campo e de coluna: 14/20, 600, +0.2.
  static final TextStyle rotulo = _style(
    family: sans,
    fallback: _sansFallback,
    size: 14,
    line: 20,
    weight: 600,
    letterSpacing: 0.2,
  );

  static final TextStyle botao = _style(
    family: sans,
    fallback: _sansFallback,
    size: 17,
    line: 24,
    weight: 600,
  );

  /// Texto dos carimbos: 13/16, 700, +0.6. O texto vem já em maiúsculas
  /// (ver `StatusStamp`).
  static final TextStyle carimbo = _style(
    family: sans,
    fallback: _sansFallback,
    size: 13,
    line: 16,
    weight: 700,
    letterSpacing: 0.6,
  );

  /// Datas, versões, horas: 13/18, 400, mono, tabular.
  static final TextStyle registo = _style(
    family: mono,
    fallback: _monoFallback,
    size: 13,
    line: 18,
    weight: 400,
    features: _tabular,
  );

  /// Título do ecrã conforme o breakpoint.
  static TextStyle tituloPara(Breakpoint b) =>
      b == Breakpoint.compacto ? tituloCompacto : titulo;
}
