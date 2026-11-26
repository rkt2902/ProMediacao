import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/design/app_theme.dart';

/// Monta [child] com o tema da app e uma largura de ecrã controlada.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  double width = 800,
  double height = 900,
  bool disableAnimations = false,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: c!,
      ),
      home: Scaffold(body: child),
    ),
  );
}
