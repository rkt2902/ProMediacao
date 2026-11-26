import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/auth/data/entry_tab_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import 'auth_test_helpers.dart';

Future<void> type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.byType(LabeledField).evaluate().length > 1
        ? find.ancestor(
            of: find.text(label),
            matching: find.byType(LabeledField),
          )
        : find.byType(LabeledField),
    matching: find.byType(EditableText),
  );
  await tester.enterText(field.first, text);
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final f = find.widgetWithText(PrimaryButton, label);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in testWidths.entries) {
    group('${entry.key} (${entry.value.toInt()})', () {
      final w = entry.value;

      testWidgets('entrada: primeira visita abre "Sou cliente", sem overflow', (
        tester,
      ) async {
        await pumpAuthApp(tester, FakeAuthRepository(), width: w);
        expect(find.text('Sou cliente'), findsOneWidget);
        expect(find.text('Enviar link de acesso'), findsOneWidget);
        expect(find.text('Palavra-passe'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('login: credenciais erradas mostram mensagem única', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        repo.accounts['ana@exemplo.pt'] = (
          'palavra-segura-1',
          AppRole.mediador,
        );
        await pumpAuthApp(tester, repo, width: w);
        await tapText(tester, 'Trabalho num escritório');
        await type(tester, 'Email', 'ana@exemplo.pt');
        await tester.enterText(
          find.descendant(
            of: find.ancestor(
              of: find.text('Palavra-passe'),
              matching: find.byType(LabeledField),
            ),
            matching: find.byType(EditableText),
          ),
          'errada',
        );
        await tapButton(tester, 'Entrar');
        expect(find.text('Email ou palavra-passe incorretos.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('login: validação de campos vazios', (tester) async {
        await pumpAuthApp(tester, FakeAuthRepository(), width: w);
        await tapText(tester, 'Trabalho num escritório');
        await tapButton(tester, 'Entrar');
        expect(find.text('Escreva o seu email.'), findsOneWidget);
        expect(find.text('Escreva a palavra-passe.'), findsOneWidget);
      });

      testWidgets('login com sucesso leva ao ecrã do papel', (tester) async {
        final repo = FakeAuthRepository();
        repo.accounts['ana@exemplo.pt'] = (
          'palavra-segura-1',
          AppRole.mediador,
        );
        await pumpAuthApp(tester, repo, width: w);
        await tapText(tester, 'Trabalho num escritório');
        final fields = find.byType(EditableText);
        await tester.enterText(fields.at(0), 'ana@exemplo.pt');
        await tester.enterText(fields.at(1), 'palavra-segura-1');
        await tapButton(tester, 'Entrar');
        expect(find.text('Clientes do escritório'), findsOneWidget);
        expect(find.text('Sair'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('cliente: email inválido não envia', (tester) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w);
        await tester.enterText(find.byType(EditableText), 'sem-arroba');
        await tapText(tester, 'Enviar link de acesso');
        expect(
          find.text('Escreva um email completo, por exemplo nome@exemplo.pt.'),
          findsOneWidget,
        );
        expect(repo.linkRequests, isEmpty);
      });

      testWidgets('cliente: confirmação e bloqueio de 60 s', (tester) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w);
        await tester.enterText(find.byType(EditableText), 'maria@exemplo.pt');
        await tapText(tester, 'Enviar link de acesso');
        expect(repo.linkRequests, ['maria@exemplo.pt']);
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(
          find.text('Pode enviar outra vez daqui a 1 minuto.'),
          findsWidgets,
        );
        // Bloqueado: tocar não envia.
        await tester.tap(find.text('Enviar outra vez'), warnIfMissed: false);
        await tester.pump();
        expect(repo.linkRequests.length, 1);
        await tester.pump(const Duration(seconds: 61));
        await tapText(tester, 'Enviar outra vez');
        expect(repo.linkRequests.length, 2);
        // "Usar outro email" volta ao formulário.
        await tapText(tester, 'Usar outro email');
        expect(find.text('Enviar link de acesso'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('cliente: too_soon do servidor mostra a mesma confirmação', (
        tester,
      ) async {
        final repo = FakeAuthRepository()
          ..nextFailure = const AuthFailure(
            AuthFailureKind.tooSoon,
            retryAfterSeconds: 30,
          );
        await pumpAuthApp(tester, repo, width: w);
        await tester.enterText(find.byType(EditableText), 'maria@exemplo.pt');
        await tapText(tester, 'Enviar link de acesso');
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(
          find.text('Pode enviar outra vez daqui a 30 segundos.'),
          findsWidgets,
        );
      });

      testWidgets('link expirado: pede link novo com a mesma confirmação', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w, location: '/link-invalido');
        expect(find.text('Este link já não é válido'), findsOneWidget);
        expect(
          find.text('Também pode pedir ao seu mediador que reenvie o pedido.'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(EditableText), 'maria@exemplo.pt');
        await tapText(tester, 'Enviar link novo');
        expect(repo.linkRequests, ['maria@exemplo.pt']);
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('erro de rede: aviso e faixa offline', (tester) async {
        final repo = FakeAuthRepository()
          ..nextFailure = const AuthFailure(AuthFailureKind.network)
          ..reachable = false;
        await pumpAuthApp(tester, repo, width: w);
        await tester.enterText(find.byType(EditableText), 'maria@exemplo.pt');
        await tapText(tester, 'Enviar link de acesso');
        expect(
          find.text(
            'Não foi possível ligar. Verifique a ligação e tente de novo.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Sem ligação à internet. Precisa de ligação para entrar.'),
          findsOneWidget,
        );
        // Ligação volta: o teste periódico reativa o botão.
        repo.reachable = true;
        repo.nextFailure = null;
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        expect(
          find.text('Sem ligação à internet. Precisa de ligação para entrar.'),
          findsNothing,
        );
      });

      testWidgets('recuperar palavra-passe: resposta igual', (tester) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w);
        await tapText(tester, 'Trabalho num escritório');
        await tapText(tester, 'Esqueci-me da palavra-passe');
        expect(find.text('Recuperar palavra-passe'), findsOneWidget);
        await tester.enterText(find.byType(EditableText), 'ninguem@exemplo.pt');
        await tapText(tester, 'Enviar link');
        expect(repo.resets, ['ninguem@exemplo.pt']);
        expect(
          find.text(
            'Se houver uma conta com este email, o link chega dentro de '
            'alguns minutos. Veja também a pasta de spam.',
          ),
          findsOneWidget,
        );
        await tapText(tester, 'Voltar a entrar');
        expect(find.text('Entrar'), findsWidgets);
      });
    });
  }

  group('rotas por papel', () {
    for (final r in {
      AppRole.admin: ('Painel do administrador', '/admin'),
      AppRole.mediador: ('Clientes do escritório', '/mediador'),
      AppRole.cliente: ('Com quem partilho', '/cliente'),
    }.entries) {
      testWidgets('${r.key.name}: sessão guardada abre o seu ecrã', (
        tester,
      ) async {
        final repo = FakeAuthRepository(
          session: AppSession(userId: 'u', role: r.key),
        );
        await pumpAuthApp(tester, repo);
        expect(find.text(r.value.$1), findsOneWidget);
      });
    }

    testWidgets('sem sessão: qualquer rota protegida vai para a entrada', (
      tester,
    ) async {
      await pumpAuthApp(tester, FakeAuthRepository(), location: '/admin');
      expect(find.text('Sou cliente'), findsOneWidget);
    });

    testWidgets('mediador a abrir /admin volta ao seu ecrã', (tester) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.mediador),
      );
      await pumpAuthApp(tester, repo, location: '/admin');
      expect(find.text('Clientes do escritório'), findsOneWidget);
    });

    testWidgets('cliente abre pedido concreto (marcador da tarefa 5)', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.cliente),
      );
      await pumpAuthApp(tester, repo, location: '/cliente/pedido/abc');
      expect(find.text('Pedido de acesso'), findsWidgets);
    });

    testWidgets('com sessão, a entrada redireciona para o ecrã do papel', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.admin),
      );
      await pumpAuthApp(tester, repo, location: '/entrar');
      expect(find.text('Painel do administrador'), findsOneWidget);
    });

    testWidgets('sair volta à entrada', (tester) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.cliente),
      );
      await pumpAuthApp(tester, repo);
      await tapText(tester, 'Sair');
      expect(repo.signOuts, 1);
      expect(find.text('Sou cliente'), findsOneWidget);
      expect(find.textContaining('A sua sessão terminou'), findsNothing);
    });

    testWidgets('sessão que termina sozinha mostra aviso no separador certo', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.mediador),
      );
      await pumpAuthApp(tester, repo);
      repo.session = null;
      repo.signalsController.add(AuthSignal.sessionChanged);
      await tester.pumpAndSettle();
      expect(
        find.text('A sua sessão terminou. Entre de novo para continuar.'),
        findsOneWidget,
      );
      expect(find.text('Palavra-passe'), findsOneWidget);
    });

    testWidgets('link com erro na URL vai para o link expirado', (
      tester,
    ) async {
      await pumpAuthApp(
        tester,
        FakeAuthRepository(),
        location: '/?error=access_denied&error_code=otp_expired',
      );
      expect(find.text('Este link já não é válido'), findsOneWidget);
    });

    testWidgets('definir palavra-passe sem sessão: link expirado', (
      tester,
    ) async {
      await pumpAuthApp(
        tester,
        FakeAuthRepository(),
        location: '/definir-palavra-passe',
      );
      expect(find.text('Este link já não é válido'), findsOneWidget);
      expect(
        find.textContaining('ou ao administrador, se foi convidado'),
        findsOneWidget,
      );
    });

    testWidgets('recuperação: define palavra-passe com a regra dos 10', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.mediador),
      );
      await pumpAuthApp(tester, repo);
      repo.signalsController.add(AuthSignal.passwordRecovery);
      await tester.pumpAndSettle();
      expect(find.text('Definir palavra-passe'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'curta');
      await tester.pump();
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
      await tester.enterText(find.byType(EditableText), 'uma-palavra-longa');
      await tester.pump();
      await tapText(tester, 'Guardar e entrar');
      expect(repo.updatedPassword, 'uma-palavra-longa');
      expect(find.text('Clientes do escritório'), findsOneWidget);
    });

    testWidgets('não foi possível confirmar a sessão: tentar de novo', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..restoreFailure = const AuthFailure(AuthFailureKind.network);
      await pumpAuthApp(tester, repo);
      expect(find.text('Tentar de novo'), findsOneWidget);
      repo.restoreFailure = null;
      await tapText(tester, 'Tentar de novo');
      expect(find.text('Sou cliente'), findsOneWidget);
    });
  });

  group('último separador', () {
    testWidgets('é lembrado e restaurado', (tester) async {
      final store = MemoryEntryTabStore();
      await pumpAuthApp(tester, FakeAuthRepository(), store: store);
      await tapText(tester, 'Trabalho num escritório');
      expect(store.value, EntryTab.office);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAuthApp(tester, FakeAuthRepository(), store: store);
      expect(find.text('Palavra-passe'), findsOneWidget);
    });

    testWidgets('falha do armazenamento não impede a entrada', (tester) async {
      await pumpAuthApp(tester, FakeAuthRepository(), store: _BrokenStore());
      await tapText(tester, 'Trabalho num escritório');
      expect(find.text('Palavra-passe'), findsOneWidget);
    });
  });

  test('AppConnectivity sem sonda fica offline até nova resposta', () {
    final c = AppConnectivity();
    c.reportNetworkFailure();
    expect(c.online, isFalse);
    c.reportReachable();
    expect(c.online, isTrue);
    c.dispose();
  });

  testWidgets('AppScope expõe os serviços', (tester) async {
    late AppServices got;
    final services = await pumpAuthApp(tester, FakeAuthRepository());
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: Builder(
          builder: (c) {
            got = AppScope.of(c);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(got, same(services));
  });
}

class _BrokenStore implements EntryTabStore {
  @override
  Future<EntryTab?> read() async => null;

  @override
  Future<void> write(EntryTab tab) async {}
}
