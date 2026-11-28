import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/app/route_builders.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/client_requests/presentation/client_request_page.dart';
import 'package:promediacao/features/client_requests/presentation/my_requests_page.dart';
import 'package:promediacao/features/consent/application/consent_scope.dart';
import 'package:promediacao/features/consent/presentation/client_home_page.dart';
import 'package:promediacao/features/consent/presentation/consent_page.dart';
import 'package:promediacao/features/notifications/presentation/notifications_page.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../auth/auth_test_helpers.dart';
import '../consent/consent_test_helpers.dart';
import '../notifications/fake_notifications_repository.dart';
import '../requests/fake_requests_repository.dart';

const sizes = <String, Size>{
  'telemóvel': Size(390, 844),
  'tablet': Size(768, 1024),
  'desktop': Size(1280, 800),
};

/// Pedido aberto de exemplo (Automóvel, da Ribeira Seguros).
RequestDetail detail({
  String id = 'r-1',
  bool withdrawn = false,
  String? message = 'Bom dia, D. Maria. Preciso destes elementos.',
  bool policy = true,
  RequestStage stage = RequestStage.created,
}) => RequestDetail(
  id: id,
  clientId: 'c-maria',
  clientName: 'Maria do Carmo Figueiredo',
  officeId: 'o-ribeira',
  officeName: 'Ribeira Seguros',
  typeCode: 'automovel',
  typeName: 'Automóvel',
  typeNote: 'Se o condutor habitual não for o tomador, envie também o CC.',
  origin: RequestOrigin.mediador,
  stage: stage,
  allowPolicyConditions: policy,
  message: message,
  authorName: 'Ana Martins',
  createdAt: DateTime.utc(2026, 11, 27, 10, 14),
  documentsSentAt: stage.number >= 2 ? DateTime.utc(2026, 11, 28, 9) : null,
  accessWithdrawn: withdrawn,
  accessWithdrawnAt: withdrawn ? DateTime.utc(2026, 11, 26, 15, 2) : null,
  items: const [
    RequestItem(
      id: 'i1',
      position: 1,
      kind: ItemKind.document,
      label: 'Carta de condução',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i2',
      position: 2,
      kind: ItemKind.data,
      label: 'Morada',
      source: ItemSource.catalog,
    ),
  ],
);

/// App completa (router real) com o cliente em [location] e os fakes dos
/// pedidos, notificações e consentimentos.
Future<AppServices> pumpClient(
  WidgetTester tester, {
  required FakeRequestsRepository requests,
  FakeNotificationsRepository? notifications,
  FakeConsentRepository? consent,
  Size size = const Size(1280, 800),
  String location = '/cliente',
  AppConnectivity? connectivity,
  bool settle = true,
}) async {
  final consentRepo = consent ?? FakeConsentRepository(grants: [activeGrant()]);
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
    requests: requests,
    notifications: notifications ?? FakeNotificationsRepository(),
  );
  Widget scoped(Widget w) => ConsentScope(repository: consentRepo, child: w);
  await tester.pumpWidget(
    ProMediacaoApp(
      services: services,
      initialLocation: location,
      builders: RouteBuilders(
        clientHome: (c) => scoped(const MyRequestsPage()),
        clientSharing: (c) => scoped(const ClientHomePage()),
        consent: (c, id) => scoped(ConsentPage(grantId: id)),
        clientRequest: (c, id) => ClientRequestPage(requestId: id),
        notifications: (c) => const NotificationsPage(),
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

/// Sem erros de layout.
void expectNoLayoutErrors(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
