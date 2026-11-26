import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_copy.dart';
import 'session_colophon.dart';

/// Estrutura comum dos ecrãs de entrada e de palavra-passe (03-design.md,
/// ecrãs 1, 1b, 1c e 2): `PageFrame` com o separador, faixa offline, coluna
/// de `larguraFormulario` 400 encostada à esquerda da moldura (a toda a
/// largura em compacto), título a `s32` da régua e colofão no fim.
///
/// Sem sessão ([signedIn] falso): separador "Acesso", sem conta e colofão sem
/// sessão. Com sessão: "Sair" na linha do separador e colofão do perfil.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.children,
    this.tabLabel = AuthCopy.tabAccess,
    this.offlineMessage,
    this.signedIn = false,
  });

  final List<Widget> children;
  final String tabLabel;
  final String? offlineMessage;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final connectivity = services.connectivity;
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => PageFrame(
        tabLabel: tabLabel,
        maxWidth: AppSize.larguraFormulario,
        onSignOut: signedIn ? services.session.signOut : null,
        accountName: signedIn ? accountNameFor(services.session.session) : null,
        banner: offlineMessage == null
            ? null
            : OfflineBar(
                visible: !connectivity.online,
                message: offlineMessage!,
              ),
        colophon: signedIn
            ? const SessionColophon()
            : const Colophon.signedOut(),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpace.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Título dos ecrãs de autenticação (`titulo`, 26 em compacto), marcado como
/// cabeçalho. Com [focus], recebe o foco ao abrir em médio/largo.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key, this.focus = false});

  final String text;
  final bool focus;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final title = Semantics(
      header: true,
      child: Text(text, style: AppType.tituloPara(bp)),
    );
    if (!focus) return title;
    return Focus(autofocus: bp != Breakpoint.compacto, child: title);
  }
}
