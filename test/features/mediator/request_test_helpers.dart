import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/app/routes.dart';
import 'package:promediacao/core/design/app_theme.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';
import 'package:promediacao/features/requests/data/fake_request_email_sender.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../auth/auth_test_helpers.dart';
import '../requests/fake_requests_repository.dart';

final mediatorSession = AppSession(
  userId: 'u-med',
  role: AppRole.mediador,
  email: 'ana@ribeira.pt',
  fullName: 'Ana Martins',
  createdAt: DateTime.utc(2026, 11, 3),
  method: SignInMethod.password,
  officeName: 'Ribeira Seguros',
  officeJoinedAt: DateTime.utc(2026, 11, 3),
);

/// Ecrã de teste com um router mínimo: `/teste` é a página; a ficha e a
/// lista de Clientes são marcadores de texto para ver a navegação.
class PageHarness {
  PageHarness(this.services, this.repo, this.email, this.router);

  final AppServices services;
  final FakeRequestsRepository repo;
  final FakeRequestEmailSender email;
  final GoRouter router;

  AppConnectivity get connectivity => services.connectivity;

  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;
}

Future<PageHarness> pumpPage(
  WidgetTester tester,
  Widget page, {
  FakeRequestsRepository? repo,
  FakeRequestEmailSender? email,
  Size size = const Size(1280, 800),
  double textScale = 1.0,
  void Function(AppServices services)? beforePump,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = repo ?? FakeRequestsRepository();
  final mail = email ?? FakeRequestEmailSender(recipientEmail: null);
  final auth = FakeAuthRepository(session: mediatorSession);
  final services = AppServices(
    auth: auth,
    prompts: MemoryPasswordPromptStore(),
    connectivity: AppConnectivity(probe: auth.isReachable),
    requests: fake,
    requestEmail: mail,
  );
  await services.session.start();
  beforePump?.call(services);
  final router = GoRouter(
    initialLocation: '/teste',
    routes: [
      GoRoute(path: '/teste', builder: (_, _) => page),
      GoRoute(
        path: AppRoutes.mediator,
        builder: (_, _) => const Text('LISTA DE CLIENTES'),
      ),
      GoRoute(
        path: AppRoutes.mediatorClientPattern,
        builder: (_, s) => Text('FICHA ${s.pathParameters['clientId']}'),
        routes: [
          GoRoute(
            path: 'novo-pedido',
            builder: (_, s) =>
                Text('NOVO PEDIDO ${s.pathParameters['clientId']}'),
          ),
          GoRoute(
            path: 'pedidos/:requestId',
            builder: (_, s) => Text('PEDIDO ${s.pathParameters['requestId']}'),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    services.dispose();
  });
  return PageHarness(services, fake, mail, router);
}

RequestDetail sampleDetail({
  String id = 'r1',
  bool policy = true,
  String? message =
      'Bom dia, D. Maria. Preciso destes elementos até ao fim do mês.',
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
  stage: RequestStage.created,
  allowPolicyConditions: policy,
  message: message,
  authorName: 'Ana Martins',
  createdAt: DateTime.utc(2026, 11, 27, 10, 14),
  accessWithdrawn: false,
  items: const [
    RequestItem(
      id: 'a',
      position: 1,
      kind: ItemKind.document,
      label: 'Cartão de Cidadão',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'b',
      position: 2,
      kind: ItemKind.data,
      label: 'Morada',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'c',
      position: 3,
      kind: ItemKind.document,
      label: 'Fotografias do veículo',
      source: ItemSource.free,
    ),
  ],
);
