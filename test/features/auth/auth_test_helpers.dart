import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/auth/data/entry_tab_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';
import 'package:promediacao/features/auth/domain/auth_repository.dart';

/// Repositório de teste: sem rede, tudo controlável.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  AppSession? session;

  /// Contas válidas: email -> (palavra-passe, papel).
  final Map<String, (String, AppRole)> accounts = {};
  AuthFailure? nextFailure;
  AuthFailure? restoreFailure;
  bool reachable = true;

  final signalsController = StreamController<AuthSignal>.broadcast();
  final List<String> linkRequests = [];
  final List<String> resets = [];
  String? updatedPassword;
  int signOuts = 0;

  @override
  Stream<AuthSignal> get signals => signalsController.stream;

  @override
  Future<AppSession?> restoreSession() async {
    if (restoreFailure != null) throw restoreFailure!;
    return session;
  }

  @override
  Future<AppSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (nextFailure != null) throw nextFailure!;
    final acc = accounts[email];
    if (acc == null || acc.$1 != password) {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    }
    return session = AppSession(userId: 'u-${acc.$2.name}', role: acc.$2);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (nextFailure != null) throw nextFailure!;
    resets.add(email);
  }

  @override
  Future<void> requestClientLink(String email) async {
    if (nextFailure != null) throw nextFailure!;
    linkRequests.add(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    updatedPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    session = null;
  }

  @override
  Future<bool> isReachable() async => reachable;
}

/// Larguras exigidas: telemóvel, tablet, desktop.
const testWidths = <String, double>{
  'telemóvel': 390,
  'tablet': 900,
  'desktop': 1280,
};

Future<AppServices> pumpAuthApp(
  WidgetTester tester,
  FakeAuthRepository repo, {
  double width = 1280,
  double height = 900,
  String? location,
  EntryTabStore? store,
  AppConnectivity? connectivity,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(
    auth: repo,
    tabStore: store ?? MemoryEntryTabStore(),
    connectivity: connectivity ?? AppConnectivity(probe: repo.isReachable),
  );
  await tester.pumpWidget(
    ProMediacaoApp(services: services, initialLocation: location),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return services;
}
