import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'client_link_form.dart';

/// Ecrã 2 (link expirado ou inválido). `forPassword` é a variante de quem
/// abriu um link de definir/recuperar palavra-passe (escritório).
class ExpiredLinkPage extends StatelessWidget {
  const ExpiredLinkPage({super.key, this.forPassword = false});

  final bool forPassword;

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        AuthCopy.linkInvalidTitle,
        style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
      ),
    );
    if (forPassword) {
      return AuthLayout(
        offlineMessage: AuthCopy.offlineLink,
        tabs: const FolderTab(label: AuthCopy.tabOffice),
        children: [
          const SizedBox(height: AppSpace.s32),
          title,
          const SizedBox(height: AppSpace.s16),
          Text(AuthCopy.linkInvalidPassword, style: _body),
          const SizedBox(height: AppSpace.s24),
          PrimaryButton(
            label: AuthCopy.recoverTitle,
            principal: true,
            expand: true,
            onPressed: () => context.go(AppRoutes.recover),
          ),
          const SizedBox(height: AppSpace.s8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextAction(
              label: AuthCopy.backToSignIn,
              onPressed: () => context.go(AppRoutes.entry),
            ),
          ),
        ],
      );
    }
    return AuthLayout(
      offlineMessage: AuthCopy.offlineLink,
      tabs: const FolderTab(label: AuthCopy.tabMyData),
      children: [
        const SizedBox(height: AppSpace.s32),
        title,
        const SizedBox(height: AppSpace.s16),
        Text(AuthCopy.linkInvalidClient, style: _body),
        const SizedBox(height: AppSpace.s24),
        const ClientLinkForm(
          submitLabel: AuthCopy.sendNew,
          footer: AuthCopy.linkInvalidMediator,
        ),
        const SizedBox(height: AppSpace.s8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextAction(
            label: AuthCopy.backToSignIn,
            onPressed: () => context.go(AppRoutes.entry),
          ),
        ),
      ],
    );
  }
}

final TextStyle _body = AppType.corpo;
