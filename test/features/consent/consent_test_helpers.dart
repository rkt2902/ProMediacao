import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/app/route_builders.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/consent/application/consent_scope.dart';
import 'package:promediacao/features/consent/domain/consent_models.dart';
import 'package:promediacao/features/consent/domain/consent_repository.dart';
import 'package:promediacao/features/consent/presentation/client_home_page.dart';
import 'package:promediacao/features/consent/presentation/consent_page.dart';

import '../auth/auth_test_helpers.dart';
import '../notifications/fake_notifications_repository.dart';

/// Repositório de teste que imita o servidor: só muda estados permitidos
/// (pendente -> ativa | recusada, ativa -> retirada) e devolve o que
/// "confirmou". Falhas e atrasos controláveis.
class FakeConsentRepository implements ConsentRepository {
  FakeConsentRepository({List<ConsentGrant>? grants, this.version = 'v0'})
    : grants = grants ?? [];

  List<ConsentGrant> grants;
  String version;
  final Map<String, String> texts = {
    'v0': 'Autorização de acesso.\n\nAutoriza o {escritório} a ver os dados.',
  };

  ConsentFailure? listFailure;
  ConsentFailure? textFailure;
  ConsentFailure? writeFailure;

  /// Se não nulo, as escritas esperam por ele (estado "a enviar").
  Completer<void>? writeGate;
  Completer<void>? listGate;

  final List<String> calls = [];
  String? acceptedVersion;
  DateTime now = DateTime.utc(2026, 11, 26, 14, 32);

  @override
  Future<List<ConsentGrant>> myConsents() async {
    calls.add('list');
    if (listGate != null) await listGate!.future;
    if (listFailure != null) throw listFailure!;
    return List.of(grants);
  }

  @override
  Future<String> currentVersion() async {
    calls.add('version');
    if (textFailure != null) throw textFailure!;
    return version;
  }

  @override
  Future<ConsentText> text(String v) async {
    calls.add('text:$v');
    if (textFailure != null) throw textFailure!;
    final t = texts[v];
    if (t == null) throw const ConsentFailure(ConsentFailureKind.notFound);
    return ConsentText(version: v, content: t);
  }

  Future<ConsentGrant> _move(
    ConsentGrant g,
    GrantStatus from,
    GrantStatus to, {
    String? v,
  }) async {
    calls.add('${to.name}:${g.id}');
    if (writeGate != null) await writeGate!.future;
    if (writeFailure != null) throw writeFailure!;
    final i = grants.indexWhere((x) => x.id == g.id);
    if (i < 0 || grants[i].status != from) {
      throw const ConsentFailure(ConsentFailureKind.stateChanged);
    }
    final cur = grants[i];
    final updated = cur.withServerRow({
      'id': cur.id,
      'status': to.name,
      'consent_version': v ?? cur.consentVersion,
      'accepted_at': (to == GrantStatus.ativa ? now : cur.acceptedAt)
          ?.toIso8601String(),
      'declined_at': (to == GrantStatus.recusada ? now : null)
          ?.toIso8601String(),
      'withdrawn_at': (to == GrantStatus.retirada ? now : null)
          ?.toIso8601String(),
    });
    grants[i] = updated;
    return updated;
  }

  @override
  Future<ConsentGrant> accept(ConsentGrant grant, {required String version}) {
    acceptedVersion = version;
    return _move(grant, GrantStatus.pendente, GrantStatus.ativa, v: version);
  }

  @override
  Future<ConsentGrant> decline(ConsentGrant grant) =>
      _move(grant, GrantStatus.pendente, GrantStatus.recusada);

  @override
  Future<ConsentGrant> withdraw(ConsentGrant grant) =>
      _move(grant, GrantStatus.ativa, GrantStatus.retirada);

  @override
  Future<String> reaccept({
    required String officeId,
    required String version,
  }) async {
    calls.add('reaccept:$officeId');
    if (writeFailure != null) throw writeFailure!;
    return 'novo';
  }
}

/// Fixtures do 03-design.md.
ConsentGrant pendingGrant({
  String id = 'g-pend',
  String office = 'Ribeira Seguros',
  String? mediator = 'Ana Martins',
}) => ConsentGrant(
  id: id,
  officeId: 'o-$id',
  officeName: office,
  mediatorName: mediator,
  status: GrantStatus.pendente,
  consentVersion: 'v0',
  createdAt: DateTime.utc(2026, 11, 25, 15, 4),
);

ConsentGrant activeGrant({
  String id = 'g-ativa',
  String office = 'Ribeira Seguros',
}) => ConsentGrant(
  id: id,
  officeId: 'o-$id',
  officeName: office,
  mediatorName: 'Ana Martins',
  status: GrantStatus.ativa,
  consentVersion: 'v0',
  createdAt: DateTime.utc(2026, 11, 10, 9),
  acceptedAt: DateTime.utc(2026, 11, 12, 10, 4),
);

ConsentGrant declinedGrant({String id = 'g-rec'}) => ConsentGrant(
  id: id,
  officeId: 'o-$id',
  officeName: 'Mediação Norte Exemplo',
  status: GrantStatus.recusada,
  consentVersion: 'v0',
  createdAt: DateTime.utc(2026, 11, 19, 9),
  declinedAt: DateTime.utc(2026, 11, 20, 9, 12),
);

ConsentGrant withdrawnGrant({String id = 'g-ret'}) => ConsentGrant(
  id: id,
  officeId: 'o-$id',
  officeName: 'Seguros Lima & Viana (exemplo)',
  status: GrantStatus.retirada,
  consentVersion: 'v0',
  createdAt: DateTime.utc(2026, 11, 1, 9),
  acceptedAt: DateTime.utc(2026, 11, 2, 9),
  withdrawnAt: DateTime.utc(2026, 11, 18, 11, 20),
);

const consentSizes = <String, Size>{
  '320': Size(320, 700),
  'telemóvel': Size(390, 844),
  'tablet': Size(768, 1024),
  'desktop': Size(1280, 800),
};

/// App completa (router real) com o cliente já com sessão e palavra-passe
/// (sem o convite "Criar palavra-passe" pelo meio).
Future<AppServices> pumpClientApp(
  WidgetTester tester,
  FakeConsentRepository consent, {
  Size size = const Size(1280, 800),
  String location = '/cliente',
  AppConnectivity? connectivity,
  bool settle = true,
  String? notice,
  FakeNotificationsRepository? notifications,
}) async {
  ConsentHandoff.take();
  final auth = FakeAuthRepository(
    session: linkClient(passwordSetAt: DateTime.utc(2026, 11, 20, 9)),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final services = AppServices(
    auth: auth,
    prompts: MemoryPasswordPromptStore(),
    connectivity: connectivity ?? AppConnectivity(),
    notifications: notifications ?? FakeNotificationsRepository(),
  );
  if (notice != null) services.session.setNotice(notice);
  await tester.pumpWidget(
    ProMediacaoApp(
      services: services,
      initialLocation: location,
      builders: RouteBuilders(
        clientHome: (c) =>
            ConsentScope(repository: consent, child: const ClientHomePage()),
        clientSharing: (c) =>
            ConsentScope(repository: consent, child: const ClientHomePage()),
        consent: (c, id) => ConsentScope(
          repository: consent,
          child: ConsentPage(grantId: id),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return services;
}
