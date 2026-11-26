@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/features/admin/presentation/admin_home_page.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import '../../features/admin/fake_admin_repository.dart';
import '../../features/auth/auth_test_helpers.dart';
import 'review_helpers.dart';

const _sizes = <String, Size>{
  'desktop': Size(1280, 800),
  'telemovel': Size(390, 844),
};

const _admin = AppSession(
  userId: 'u-admin',
  role: AppRole.admin,
  email: 'admin@exemplo.pt',
  fullName: 'Nome Que Nunca Aparece',
  method: SignInMethod.password,
);

Future<void> _pump(WidgetTester tester, Size size) async {
  await loadReviewFonts();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(
    auth: FakeAuthRepository(session: _admin),
    connectivity: AppConnectivity(),
  );
  await services.session.start();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AppScope(services: services, child: child!),
      home: Scaffold(
        body: AdminHomePage(
          repository: FakeAdminRepository()..counts = null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
}

void main() {
  for (final e in _sizes.entries) {
    testWidgets('admin-${e.key}', (tester) async {
      await _pump(tester, e.value);
      await shoot(tester, 'admin-${e.key}');
    }, skip: skipReview);

    testWidgets('admin-criar-escritorio-${e.key}', (tester) async {
      await _pump(tester, e.value);
      await tester.tap(find.text('Criar escritório').first);
      await tester.pumpAndSettle();
      await shoot(tester, 'admin-criar-escritorio-${e.key}');
    }, skip: skipReview);

    testWidgets('admin-convidar-mediador-${e.key}', (tester) async {
      await _pump(tester, e.value);
      await tester.tap(find.text('Convidar mediador').first);
      await tester.pumpAndSettle();
      await shoot(tester, 'admin-convidar-mediador-${e.key}');
    }, skip: skipReview);
  }
}
