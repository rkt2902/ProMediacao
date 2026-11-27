// Tarefa 3 da 002: rotas novas por papel, "Os meus pedidos" como ecrã
// inicial do cliente e o link do email (`/pedidos`) que passa por Entrar e
// volta ao destino.
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/app/app.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/route_builders.dart';
import 'package:promediacao/app/router.dart';
import 'package:promediacao/app/routes.dart';
import 'package:promediacao/features/auth/application/session_controller.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import '../features/auth/auth_test_helpers.dart';

Future<SessionController> _session(AppSession? s) async {
  final c = SessionController(FakeAuthRepository(session: s));
  await c.start();
  addTearDown(c.dispose);
  return c;
}

AppSession _as(AppRole role) => AppSession(
  userId: 'u-${role.name}',
  role: role,
  email: '${role.name}@exemplo.pt',
  method: SignInMethod.password,
);

String? _go(SessionController s, String location) =>
    redirectFor(s, Uri.parse(location));

/// Segue os redirects como o GoRouter (até 5).
String _follow(SessionController s, String location) {
  var at = location;
  for (var i = 0; i < 5; i++) {
    final next = _go(s, at);
    if (next == null) return at;
    at = next;
  }
  fail('Redirects em ciclo a partir de $location');
}

/// Ecrãs falsos: mostram o nome e os argumentos que receberam.
RouteBuilders _builders() => RouteBuilders(
  adminHome: (c) => const Text('admin: início'),
  mediatorHome: (c) => const Text('mediador: Clientes'),
  clientSharing: (c) => const Text('cliente: Com quem partilho'),
  newRequest: (c, a) =>
      Text('novo pedido: ${a.clientId ?? '-'} ficha=${a.fromClientFile}'),
  clientFile: (c, id) => Text('ficha: $id'),
  mediatorRequest: (c, cid, rid) => Text('pedido mediador: $cid $rid'),
  clientRequest: (c, id) => Text('pedido cliente: $id'),
  notifications: (c) => const Text('notificações'),
);

Future<GoRouter> _pump(
  WidgetTester tester,
  AppSession? session, {
  String? location,
  RouteBuilders? builders,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository(session: session);
  final services = AppServices(
    auth: auth,
    prompts: MemoryPasswordPromptStore(),
  );
  await tester.pumpWidget(
    ProMediacaoApp(
      services: services,
      initialLocation: location,
      builders: builders ?? _builders(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  return GoRouter.of(tester.element(find.byType(Navigator).first));
}

String _location(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('redirect: link do email /pedidos', () {
    test('sem sessão passa por Entrar com o destino', () async {
      final s = await _session(null);
      expect(_go(s, '/pedidos'), '/entrar?de=%2Fpedidos');
      expect(_go(s, '/pedidos/r1'), '/entrar?de=%2Fpedidos%2Fr1');
      // Entrar com destino continua a ser pública.
      expect(_go(s, '/entrar?de=%2Fpedidos'), isNull);
      // As outras rotas como na 001 (sem destino).
      expect(_go(s, AppRoutes.client), AppRoutes.entry);
    });

    test('a validar a sessão: volta ao link e daí a Entrar', () async {
      final restoring = SessionController(FakeAuthRepository());
      addTearDown(restoring.dispose);
      expect(_go(restoring, '/pedidos'), '/a-validar?de=%2Fpedidos');
      final s = await _session(null);
      expect(_follow(s, '/a-validar?de=%2Fpedidos'), '/entrar?de=%2Fpedidos');
    });

    test('depois de entrar volta ao destino; o cliente cai nos seus '
        'pedidos', () async {
      final s = await _session(_as(AppRole.cliente));
      expect(_go(s, '/entrar?de=%2Fpedidos'), '/pedidos');
      expect(_follow(s, '/entrar?de=%2Fpedidos'), AppRoutes.client);
      expect(
        _follow(s, '/entrar?de=%2Fpedidos%2Fr%201'),
        AppRoutes.clientRequest('r 1'),
      );
    });

    test('mediador e admin vão ao seu ecrã inicial', () async {
      final m = await _session(_as(AppRole.mediador));
      expect(_follow(m, '/pedidos'), AppRoutes.mediator);
      final a = await _session(_as(AppRole.admin));
      expect(_follow(a, '/pedidos/r1'), AppRoutes.admin);
    });

    test('destino de outro site nunca é seguido', () async {
      final s = await _session(_as(AppRole.cliente));
      for (final bad in [
        '//exemplo.com/x',
        'https://exemplo.com',
        '/\\exemplo.com',
        '/entrar',
        '/',
      ]) {
        expect(
          _go(s, '/entrar?de=${Uri.encodeComponent(bad)}'),
          AppRoutes.client,
          reason: bad,
        );
      }
      expect(safeReturnPath('/cliente/pedidos/r1'), '/cliente/pedidos/r1');
    });
  });

  group('redirect: rotas novas por papel', () {
    test('o cliente não abre as do mediador e vice-versa', () async {
      final c = await _session(_as(AppRole.cliente));
      for (final p in [
        AppRoutes.mediatorNewRequest,
        AppRoutes.mediatorClient('c1'),
        AppRoutes.mediatorClientNewRequest('c1'),
        AppRoutes.mediatorRequest('c1', 'r1'),
      ]) {
        expect(_go(c, p), AppRoutes.client, reason: p);
      }
      expect(_go(c, AppRoutes.clientRequest('r1')), isNull);
      expect(_go(c, AppRoutes.clientNotifications), isNull);
      expect(_go(c, AppRoutes.clientSharing), isNull);

      for (final role in [AppRole.mediador, AppRole.admin]) {
        final s = await _session(_as(role));
        for (final p in [
          AppRoutes.clientRequest('r1'),
          AppRoutes.clientNotifications,
          AppRoutes.clientSharing,
        ]) {
          expect(_go(s, p), homeFor(role), reason: '$role $p');
        }
      }
      final m = await _session(_as(AppRole.mediador));
      expect(_go(m, AppRoutes.mediatorRequest('c1', 'r1')), isNull);
      expect(_go(m, AppRoutes.mediatorNewRequestFor('c1')), isNull);
    });

    test('caminhos com caracteres especiais são codificados', () {
      expect(
        AppRoutes.mediatorNewRequestFor('a b'),
        '/mediador/novo-pedido?cliente=a+b',
      );
      expect(AppRoutes.mediatorClient('a/b'), '/mediador/clientes/a%2Fb');
      expect(
        AppRoutes.mediatorNewRequestFor(null),
        AppRoutes.mediatorNewRequest,
      );
    });
  });

  group('ecrãs por papel', () {
    testWidgets('cliente entra em "Os meus pedidos" e passa a "Com quem '
        'partilho"', (tester) async {
      final router = await _pump(
        tester,
        _as(AppRole.cliente),
        builders: RouteBuilders(
          adminHome: (c) => const Text('admin: início'),
          mediatorHome: (c) => const Text('mediador: Clientes'),
          clientSharing: (c) => const Text('cliente: Com quem partilho'),
        ),
      );
      expect(_location(router), AppRoutes.client);
      // Marcador por omissão (a tarefa 5 põe o ecrã real).
      expect(find.text('Os meus pedidos'), findsOneWidget);
      await tester.tap(find.text('Ver com quem partilho'));
      await tester.pumpAndSettle();
      expect(_location(router), AppRoutes.clientSharing);
      expect(find.text('cliente: Com quem partilho'), findsOneWidget);
    });

    testWidgets('mediador e admin entram como antes', (tester) async {
      var router = await _pump(tester, _as(AppRole.mediador));
      expect(_location(router), AppRoutes.mediator);
      expect(find.text('mediador: Clientes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());

      router = await _pump(tester, _as(AppRole.admin));
      expect(_location(router), AppRoutes.admin);
      expect(find.text('admin: início'), findsOneWidget);
    });

    testWidgets('mediador: Novo pedido, ficha e pedido abrem com os '
        'argumentos certos', (tester) async {
      final cases = {
        AppRoutes.mediatorNewRequest: 'novo pedido: - ficha=false',
        AppRoutes.mediatorNewRequestFor('c1'): 'novo pedido: c1 ficha=false',
        AppRoutes.mediatorClientNewRequest('c1'): 'novo pedido: c1 ficha=true',
        AppRoutes.mediatorClient('c1'): 'ficha: c1',
        AppRoutes.mediatorRequest('c1', 'r1'): 'pedido mediador: c1 r1',
        AppRoutes.mediatorNewClient: 'mediador: Clientes',
      };
      for (final e in cases.entries) {
        await _pump(tester, _as(AppRole.mediador), location: e.key);
        expect(find.text(e.value), findsOneWidget, reason: e.key);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('cliente: pedido e notificações', (tester) async {
      await _pump(
        tester,
        _as(AppRole.cliente),
        location: AppRoutes.clientRequest('r1'),
      );
      expect(find.text('pedido cliente: r1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(
        tester,
        _as(AppRole.cliente),
        location: AppRoutes.clientNotifications,
      );
      expect(find.text('notificações'), findsOneWidget);
    });

    testWidgets('marcadores por omissão das tarefas 4 e 5 abrem e o '
        'regresso funciona', (tester) async {
      final router = await _pump(
        tester,
        _as(AppRole.mediador),
        location: AppRoutes.mediatorClientNewRequest('c1'),
        builders: RouteBuilders(
          mediatorHome: (c) => const Text('mediador: Clientes'),
        ),
      );
      expect(find.text('Novo pedido'), findsOneWidget);
      await tester.tap(find.text('Cliente'));
      await tester.pumpAndSettle();
      expect(_location(router), AppRoutes.mediatorClient('c1'));
      expect(find.text('Ficha do cliente'), findsOneWidget);
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();
      expect(_location(router), AppRoutes.mediator);
    });

    testWidgets('sem sessão, o link do email abre Entrar com o destino', (
      tester,
    ) async {
      final router = await _pump(tester, null, location: '/pedidos');
      expect(_location(router), '/entrar?de=%2Fpedidos');
    });
  });
}
