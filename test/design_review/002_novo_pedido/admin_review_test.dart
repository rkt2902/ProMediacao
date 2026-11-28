@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/features/admin/domain/admin_models.dart';
import 'package:promediacao/features/admin/presentation/admin_home_page.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import '../../features/admin/fake_admin_repository.dart';
import '../../features/auth/auth_test_helpers.dart';
import 'review_helpers.dart';

const _admin = AppSession(
  userId: 'u-admin',
  role: AppRole.admin,
  email: 'admin@exemplo.pt',
  fullName: 'Nome Que Nunca Aparece',
  method: SignInMethod.password,
);

/// Admin: desktop e um tamanho pequeno (regra "Design primeiro"), mais 1.3.
const _variants = <String, (Size, double)>{
  'desktop': (Size(1280, 800), 1.0),
  'telemovel': (Size(390, 844), 1.0),
  '320': (Size(320, 700), 1.0),
  'desktop-1.3': (Size(1280, 800), 1.3),
};

void main() {
  for (final v in _variants.entries) {
    testWidgets('admin-${v.key}', (tester) async {
      await loadReviewFonts();
      if (v.value.$2 != 1.0) setTextScale(tester, v.value.$2);
      tester.view.physicalSize = v.value.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final services = AppServices(
        auth: FakeAuthRepository(session: _admin),
        connectivity: AppConnectivity(),
      );
      await services.session.start();
      // 4 contagens, com um número de 4 algarismos para ver a largura.
      final repo = FakeAdminRepository(
        counts: const AdminCounts(
          offices: 3,
          mediators: 4,
          clients: 128,
          requests: 1046,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              AppScope(services: services, child: child!),
          home: Scaffold(body: AdminHomePage(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
      await shoot(tester, 'admin-${v.key}');
    }, skip: skipReview);
  }
}
