import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
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
  AuthFailure? updateFailure;
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
    return session = AppSession(
      userId: 'u-${acc.$2.name}',
      role: acc.$2,
      email: email,
      method: SignInMethod.password,
    );
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
  Future<AppSession?> updatePassword(String newPassword) async {
    if (updateFailure != null) throw updateFailure!;
    updatedPassword = newPassword;
    final s = session;
    if (s == null) return null;
    return session = AppSession(
      userId: s.userId,
      role: s.role,
      email: s.email,
      fullName: s.fullName,
      createdAt: s.createdAt,
      method: s.method,
      signedInAt: s.signedInAt,
      passwordSetAt: DateTime.utc(2026, 11, 26, 14, 32),
      officeName: s.officeName,
      officeJoinedAt: s.officeJoinedAt,
    );
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    session = null;
  }

  @override
  Future<bool> isReachable() async => reachable;
}

/// Tamanhos exigidos: telemóvel, tablet, desktop (03-design.md).
const testSizes = <String, Size>{
  'telemóvel': Size(390, 844),
  'tablet': Size(768, 1024),
  'desktop': Size(1280, 800),
};

/// Cliente que entrou por link, sem palavra-passe (fixtures do 03-design).
AppSession linkClient({DateTime? passwordSetAt}) => AppSession(
  userId: 'u-cliente',
  role: AppRole.cliente,
  email: 'maria.figueiredo@exemplo.pt',
  fullName: 'Maria do Carmo Figueiredo',
  createdAt: DateTime.utc(2026, 11, 12, 10, 4),
  method: SignInMethod.link,
  signedInAt: DateTime.utc(2026, 11, 26, 14, 0),
  passwordSetAt: passwordSetAt,
);

Future<AppServices> pumpAuthApp(
  WidgetTester tester,
  FakeAuthRepository repo, {
  double width = 1280,
  double height = 900,
  String? location,
  PasswordPromptStore? prompts,
  AppConnectivity? connectivity,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(
    auth: repo,
    prompts: prompts ?? MemoryPasswordPromptStore(),
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
