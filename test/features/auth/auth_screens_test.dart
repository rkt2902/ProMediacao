import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/app_scope.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/core/design/tokens.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/auth/data/password_prompt_store.dart';
import 'package:promediacao/features/auth/domain/auth_models.dart';

import 'auth_test_helpers.dart';

Finder field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabeledField)),
  matching: find.byType(EditableText),
);

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final f = find.widgetWithText(PrimaryButton, label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> tapSecondary(WidgetTester tester, String label) async {
  final f = find.widgetWithText(SecondaryButton, label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

const linkButton = 'Receber link de acesso por email';
const signedOutLine =
    'O dossiê dos seus seguros, partilhado só com quem autorizar.';

void main() {
  for (final size in testSizes.entries) {
    group('${size.key} (${size.value.width.toInt()})', () {
      final w = size.value.width;
      final h = size.value.height;

      testWidgets('entrar: um só formulário, separador "Acesso", colofão', (
        tester,
      ) async {
        await pumpAuthApp(tester, FakeAuthRepository(), width: w, height: h);
        expect(find.text('Acesso'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Palavra-passe'), findsOneWidget);
        expect(find.text('Esqueci-me da palavra-passe'), findsOneWidget);
        expect(find.text(linkButton), findsOneWidget);
        expect(find.text('Sou cliente'), findsNothing);
        // Sem sessão: sem conta na linha do separador.
        expect(find.text('Sair'), findsNothing);
        await tester.ensureVisible(find.text(signedOutLine));
        expect(find.text('ProDossier'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('entrar: credenciais erradas, mensagem única e dica', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        repo.accounts['ana@exemplo.pt'] = ('Segura#2026', AppRole.mediador);
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'ana@exemplo.pt');
        await tester.enterText(field('Palavra-passe'), 'errada');
        await tapButton(tester, 'Entrar');
        expect(find.text('Email ou palavra-passe incorretos.'), findsOneWidget);
        expect(
          find.text(
            'Se ainda não criou palavra-passe, use Receber link de acesso por '
            'email.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('entrar: validação de campos vazios', (tester) async {
        await pumpAuthApp(tester, FakeAuthRepository(), width: w, height: h);
        await tapButton(tester, 'Entrar');
        expect(find.text('Escreva o seu email.'), findsOneWidget);
        await tester.enterText(field('Email'), 'nome@exemplo');
        await tapButton(tester, 'Entrar');
        expect(
          find.text('Escreva um email completo, por exemplo nome@exemplo.pt.'),
          findsOneWidget,
        );
        await tester.enterText(field('Email'), 'nome@exemplo.pt');
        await tapButton(tester, 'Entrar');
        expect(find.text('Escreva a palavra-passe.'), findsOneWidget);
      });

      testWidgets('entrar com palavra-passe leva ao ecrã do papel', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        repo.accounts['ana@exemplo.pt'] = ('Segura#2026', AppRole.mediador);
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'ana@exemplo.pt');
        await tester.enterText(field('Palavra-passe'), 'Segura#2026');
        await tapButton(tester, 'Entrar');
        expect(find.text('Clientes'), findsOneWidget);
        expect(find.text('Sair'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('link: usa o email de cima e ignora a palavra-passe', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'sem-arroba');
        await tapSecondary(tester, linkButton);
        expect(
          find.text('Escreva um email completo, por exemplo nome@exemplo.pt.'),
          findsOneWidget,
        );
        expect(find.text('Escreva a palavra-passe.'), findsNothing);
        expect(repo.linkRequests, isEmpty);
      });

      testWidgets('link: confirmação, bloqueio de 60 s e voltar', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tapSecondary(tester, linkButton);
        expect(repo.linkRequests, ['maria@exemplo.pt']);
        // O formulário inteiro é substituído pela confirmação.
        expect(find.text('Palavra-passe'), findsNothing);
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(
          find.text('Pode enviar outra vez daqui a 1 minuto.'),
          findsWidgets,
        );
        await tester.tap(find.text('Enviar outra vez'), warnIfMissed: false);
        await tester.pump();
        expect(repo.linkRequests.length, 1);
        await tester.pump(const Duration(seconds: 61));
        await tapText(tester, 'Enviar outra vez');
        expect(repo.linkRequests.length, 2);
        await tapText(tester, 'Entrar com palavra-passe');
        expect(find.text('Palavra-passe'), findsOneWidget);
        expect(find.text('maria@exemplo.pt'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('link: "Usar outro email" limpa o campo', (tester) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tapSecondary(tester, linkButton);
        await tapText(tester, 'Usar outro email');
        expect(find.text(linkButton), findsOneWidget);
        expect(find.text('maria@exemplo.pt'), findsNothing);
      });

      testWidgets('link: too_soon do servidor mostra a mesma confirmação', (
        tester,
      ) async {
        final repo = FakeAuthRepository()
          ..nextFailure = const AuthFailure(
            AuthFailureKind.tooSoon,
            retryAfterSeconds: 30,
          );
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tapSecondary(tester, linkButton);
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(
          find.text('Pode enviar outra vez daqui a 30 segundos.'),
          findsWidgets,
        );
      });

      testWidgets('link expirado: link novo e "Entrar com ela"', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(
          tester,
          repo,
          width: w,
          height: h,
          location: '/link-invalido',
        );
        expect(find.text('Acesso'), findsOneWidget);
        expect(find.text('Este link já não é válido'), findsOneWidget);
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tapText(tester, 'Já tem palavra-passe? Entrar com ela');
        // Entrar com o email já preenchido.
        expect(find.text('Palavra-passe'), findsOneWidget);
        expect(find.text('maria@exemplo.pt'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('link expirado: pede link novo com a mesma confirmação', (
        tester,
      ) async {
        final repo = FakeAuthRepository();
        await pumpAuthApp(
          tester,
          repo,
          width: w,
          height: h,
          location: '/link-invalido',
        );
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tapButton(tester, 'Enviar link novo');
        expect(repo.linkRequests, ['maria@exemplo.pt']);
        expect(find.textContaining('maria@exemplo.pt'), findsOneWidget);
        expect(find.text('Já tem palavra-passe? Entrar com ela'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('erro de rede: aviso, faixa offline e botões com razão', (
        tester,
      ) async {
        final repo = FakeAuthRepository()
          ..nextFailure = const AuthFailure(AuthFailureKind.network)
          ..reachable = false;
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'maria@exemplo.pt');
        await tester.enterText(field('Palavra-passe'), 'qualquer');
        await tapButton(tester, 'Entrar');
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
        final entrar = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'Entrar'),
        );
        expect(entrar.onPressed, isNull);
        final linkBtn = tester.widget<SecondaryButton>(
          find.widgetWithText(SecondaryButton, linkButton),
        );
        expect(linkBtn.onPressed, isNull);
        expect(
          find.text('Sem ligação. Tente quando voltar a ligação.'),
          findsNWidgets(2),
        );
        // A ligação volta: o teste periódico reativa os botões.
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
        await pumpAuthApp(tester, repo, width: w, height: h);
        await tester.enterText(field('Email'), 'ninguem@exemplo.pt');
        await tapText(tester, 'Esqueci-me da palavra-passe');
        expect(find.text('Recuperar palavra-passe'), findsOneWidget);
        expect(find.text('Acesso'), findsOneWidget);
        // O email passa para a recuperação.
        expect(find.text('ninguem@exemplo.pt'), findsOneWidget);
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
        expect(find.text(linkButton), findsOneWidget);
      });

      testWidgets('criar palavra-passe depois do link: regras e guardar', (
        tester,
      ) async {
        final repo = FakeAuthRepository(session: linkClient());
        await pumpAuthApp(tester, repo, width: w, height: h);
        expect(find.text('Criar palavra-passe'), findsOneWidget);
        expect(find.text('Os meus dados'), findsOneWidget);
        expect(find.text('Sair'), findsOneWidget);
        expect(find.text('maria.figueiredo@exemplo.pt'), findsOneWidget);
        expect(find.text('A palavra-passe precisa de ter:'), findsOneWidget);

        // Regras em tempo real: 3 de 5.
        await tester.enterText(field('Nova palavra-passe'), 'Maria2026');
        await tester.pump();
        expect(
          find.bySemanticsLabel('Cumprida: Uma letra maiúscula.'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Por cumprir: Pelo menos 10 caracteres.'),
          findsOneWidget,
        );

        // O botão nunca fica desativado pelas regras; ao carregar, erro.
        final save = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'Guardar palavra-passe'),
        );
        expect(save.onPressed, isNotNull);
        await tapButton(tester, 'Guardar palavra-passe');
        expect(repo.updatedPassword, isNull);
        expect(
          find.text(
            'A palavra-passe ainda não é segura. Falta cumprir 2 regras.',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Em falta: Um carácter especial, como ! ? # @.',
          ),
          findsOneWidget,
        );

        await tester.enterText(field('Nova palavra-passe'), 'Maria#2026');
        await tester.pump();
        expect(find.textContaining('ainda não é segura'), findsNothing);
        await tapButton(tester, 'Guardar palavra-passe');
        expect(repo.updatedPassword, 'Maria#2026');
        expect(find.text('Com quem partilho'), findsOneWidget);
        expect(
          find.text(
            'Palavra-passe criada. Da próxima vez pode entrar com o seu email '
            'e esta palavra-passe.',
          ),
          findsOneWidget,
        );
        expect(find.text('Alterar palavra-passe'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('entrar em 320 de largura', () {
    testWidgets('sem overflow nem scroll horizontal', (tester) async {
      await pumpAuthApp(tester, FakeAuthRepository(), width: 320, height: 640);
      expect(find.text(linkButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout dos ecrãs de entrada', () {
    testWidgets('desktop: coluna de 400 à esquerda da moldura centrada', (
      tester,
    ) async {
      await pumpAuthApp(
        tester,
        FakeAuthRepository(),
        width: 1280,
        height: 1000,
      );
      // Moldura de 1040 centrada: começa em 120.
      final tab = tester.getTopLeft(find.byType(FolderTab));
      expect(tab.dx, 120);
      final email = tester.getRect(find.byType(LabeledField).first);
      expect(email.left, 120);
      expect(email.width, AppSize.larguraFormulario);
      // A régua do colofão corre a largura da moldura.
      final rule = tester.getRect(
        find.descendant(
          of: find.byType(Colophon),
          matching: find.byType(AppRule),
        ),
      );
      expect(rule.width, AppSize.larguraLista);
      // Conteúdo curto: o colofão encosta ao fundo da janela.
      expect(tester.getBottomLeft(find.byType(Colophon)).dy, 1000);
    });

    testWidgets('telemóvel: coluna à largura toda menos 16', (tester) async {
      await pumpAuthApp(tester, FakeAuthRepository(), width: 390, height: 844);
      final email = tester.getRect(find.byType(LabeledField).first);
      expect(email.left, AppSpace.s16);
      expect(email.width, 390 - 2 * AppSpace.s16);
    });
  });

  group('convite para criar palavra-passe', () {
    testWidgets('"Agora não" segue e não volta nesta entrada', (tester) async {
      final prompts = MemoryPasswordPromptStore();
      final repo = FakeAuthRepository(session: linkClient());
      final services = await pumpAuthApp(tester, repo, prompts: prompts);
      expect(find.text('Agora não'), findsOneWidget);
      await tapSecondary(tester, 'Agora não');
      expect(find.text('Com quem partilho'), findsOneWidget);
      expect(find.text('Criar palavra-passe'), findsOneWidget); // na conta

      // A mesma entrada (recarregar): não volta.
      await services.session.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Agora não'), findsNothing);
    });

    testWidgets('volta na entrada seguinte por link', (tester) async {
      final prompts = MemoryPasswordPromptStore()
        ..value =
            'u-cliente:${DateTime.utc(2026, 11, 20).millisecondsSinceEpoch}';
      await pumpAuthApp(
        tester,
        FakeAuthRepository(session: linkClient()),
        prompts: prompts,
      );
      expect(find.text('Agora não'), findsOneWidget);
    });

    testWidgets('nunca antes do consentimento', (tester) async {
      await pumpAuthApp(
        tester,
        FakeAuthRepository(session: linkClient()),
        location: '/cliente/pedido/abc',
      );
      expect(find.text('Pedido de acesso'), findsWidgets);
      expect(find.text('Agora não'), findsNothing);
    });

    testWidgets('nunca a quem entrou com palavra-passe', (tester) async {
      final repo = FakeAuthRepository();
      repo.accounts['maria@exemplo.pt'] = ('Maria#2026', AppRole.cliente);
      await pumpAuthApp(tester, repo);
      await tester.enterText(field('Email'), 'maria@exemplo.pt');
      await tester.enterText(field('Palavra-passe'), 'Maria#2026');
      await tapButton(tester, 'Entrar');
      expect(find.text('Com quem partilho'), findsOneWidget);
      expect(find.text('Agora não'), findsNothing);
    });

    testWidgets('falha ao guardar: aviso, sessão mantém-se', (tester) async {
      final repo = FakeAuthRepository(session: linkClient())
        ..updateFailure = const AuthFailure(AuthFailureKind.unknown);
      await pumpAuthApp(tester, repo);
      await tester.enterText(field('Nova palavra-passe'), 'Maria#2026');
      await tapButton(tester, 'Guardar palavra-passe');
      expect(
        find.text(
          'Não foi possível guardar a palavra-passe. Nada foi alterado. '
          'Tente de novo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Criar palavra-passe'), findsOneWidget);
    });

    testWidgets('offline: "Guardar" desativado com razão, "Agora não" ativo', (
      tester,
    ) async {
      final connectivity = AppConnectivity()..reportNetworkFailure();
      await pumpAuthApp(
        tester,
        FakeAuthRepository(session: linkClient()),
        connectivity: connectivity,
      );
      final save = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Guardar palavra-passe'),
      );
      expect(save.onPressed, isNull);
      expect(find.text('Precisa de ligação para guardar.'), findsOneWidget);
      final notNow = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'Agora não'),
      );
      expect(notNow.onPressed, isNotNull);
    });

    testWidgets('a partir da conta: alterar com "Cancelar"', (tester) async {
      final repo = FakeAuthRepository(
        session: linkClient(passwordSetAt: DateTime.utc(2026, 11, 20)),
      );
      await pumpAuthApp(tester, repo);
      expect(find.text('Com quem partilho'), findsOneWidget);
      expect(find.text('Criada a 20 nov 2026.'), findsOneWidget);
      await tapSecondary(tester, 'Alterar palavra-passe');
      expect(
        find.text(
          'A palavra-passe antiga deixa de funcionar. O link de acesso '
          'continua a funcionar.',
        ),
        findsOneWidget,
      );
      expect(find.text('Agora não'), findsNothing);
      await tapSecondary(tester, 'Cancelar');
      expect(find.text('Com quem partilho'), findsOneWidget);
    });
  });

  group('rotas por papel', () {
    for (final r in {
      AppRole.admin: 'Plataforma',
      AppRole.mediador: 'Clientes',
      AppRole.cliente: 'Com quem partilho',
    }.entries) {
      testWidgets('${r.key.name}: sessão guardada abre o seu ecrã', (
        tester,
      ) async {
        final repo = FakeAuthRepository(
          session: AppSession(userId: 'u', role: r.key),
        );
        await pumpAuthApp(tester, repo);
        expect(find.text(r.value), findsOneWidget);
      });
    }

    testWidgets('sem sessão: qualquer rota protegida vai para a entrada', (
      tester,
    ) async {
      await pumpAuthApp(tester, FakeAuthRepository(), location: '/admin');
      expect(find.text(linkButton), findsOneWidget);
    });

    testWidgets('mediador a abrir /admin volta ao seu ecrã', (tester) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.mediador),
      );
      await pumpAuthApp(tester, repo, location: '/admin');
      expect(find.text('Clientes'), findsOneWidget);
    });

    testWidgets('com sessão, a entrada redireciona para o ecrã do papel', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.admin),
      );
      await pumpAuthApp(tester, repo, location: '/entrar');
      expect(find.text('Plataforma'), findsOneWidget);
    });

    testWidgets('sair volta à entrada com o email preenchido', (tester) async {
      final repo = FakeAuthRepository(
        session: linkClient(passwordSetAt: DateTime.utc(2026, 11, 20)),
      );
      await pumpAuthApp(tester, repo);
      await tapText(tester, 'Sair');
      expect(repo.signOuts, 1);
      expect(find.text(linkButton), findsOneWidget);
      expect(find.text('maria.figueiredo@exemplo.pt'), findsOneWidget);
      expect(find.textContaining('A sua sessão terminou'), findsNothing);
    });

    testWidgets('sessão que termina sozinha mostra o aviso', (tester) async {
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

    testWidgets('recuperação: definir com as 5 regras, botão sempre ativo', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(userId: 'u', role: AppRole.mediador),
      );
      await pumpAuthApp(tester, repo);
      repo.signalsController.add(AuthSignal.passwordRecovery);
      await tester.pumpAndSettle();
      expect(find.text('Definir palavra-passe'), findsOneWidget);
      expect(find.text('Acesso'), findsOneWidget);
      await tester.enterText(field('Nova palavra-passe'), 'curta');
      await tester.pump();
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
      await tapButton(tester, 'Guardar e entrar');
      expect(repo.updatedPassword, isNull);
      expect(find.textContaining('Falta cumprir 4 regras'), findsOneWidget);
      await tester.enterText(field('Nova palavra-passe'), 'Uma-Palavra-1');
      await tapButton(tester, 'Guardar e entrar');
      expect(repo.updatedPassword, 'Uma-Palavra-1');
      expect(find.text('Clientes'), findsOneWidget);
    });

    testWidgets('convite de mediador sem palavra-passe vai a definir', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        session: const AppSession(
          userId: 'u',
          role: AppRole.mediador,
          method: SignInMethod.invite,
          officeName: 'Ribeira Seguros',
        ),
      );
      await pumpAuthApp(tester, repo);
      expect(find.text('Definir palavra-passe'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Foi convidado para a Ribeira Seguros.'),
        findsOneWidget,
      );
    });

    testWidgets('não foi possível confirmar a sessão: tentar de novo', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..restoreFailure = const AuthFailure(AuthFailureKind.network);
      await pumpAuthApp(tester, repo);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text(signedOutLine), findsOneWidget);
      repo.restoreFailure = null;
      await tapText(tester, 'Tentar de novo');
      expect(find.text(linkButton), findsOneWidget);
    });
  });

  group('transição de página', () {
    testWidgets('cross-fade em 200 ms, sem deslizar', (tester) async {
      await pumpAuthApp(tester, FakeAuthRepository(), width: 1280, height: 800);
      await tester.tap(find.text('Esqueci-me da palavra-passe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // A meio: os dois ecrãs visíveis, nenhum deslocado.
      expect(find.text('Recuperar palavra-passe'), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
      final fades = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((f) => f.opacity.value)
          .where((v) => v > 0 && v < 1);
      expect(fades, isNotEmpty);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text(linkButton), findsNothing);
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
