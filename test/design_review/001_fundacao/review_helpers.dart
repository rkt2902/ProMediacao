// Goldens de revisão de design (tarefa 9 da 001). Não são regressão: os
// renders mudam entre Linux e Windows. Só correm com `--update-goldens`:
//   flutter test --update-goldens test/design_review/001_fundacao
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Fora do `flutter test` normal: só correm quando se pede para gerar.
bool get skipReview => !autoUpdateGoldenFiles;

bool _fontsLoaded = false;

/// Carrega as fontes reais (FontManifest: Source Serif 4, Atkinson
/// Hyperlegible Next e Mono, Material Icons). Sem isto o texto sai em Ahem.
Future<void> loadReviewFonts() async {
  if (_fontsLoaded) return;
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

const reviewSizes = <String, Size>{
  'telemovel': Size(390, 844),
  'tablet': Size(768, 1024),
  'desktop': Size(1280, 800),
};

const smallSize = Size(320, 700);

/// Escala de texto global (vale também para a app com router).
void setTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> shoot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('goldens/$name.png'),
  );
}
