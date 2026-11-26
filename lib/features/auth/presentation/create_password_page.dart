import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/password_rules.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'new_password_field.dart';

enum CreatePasswordMode {
  /// Convite depois de entrar por link, com "Agora não".
  prompt,

  /// A partir de "A sua conta", com "Cancelar" (criar ou alterar).
  account,
}

/// Ecrã 1c (cliente): criar palavra-passe depois de entrar por link, ou
/// criar/alterar a partir da conta. Um só campo, sem confirmação, regras em
/// tempo real (1d). "Guardar palavra-passe" nunca fica desativado pelas
/// regras: só offline (com a razão escrita) e durante o envio.
class CreatePasswordPage extends StatefulWidget {
  const CreatePasswordPage({super.key, required this.mode});

  final CreatePasswordMode mode;

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  final _password = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  bool _showErrors = false;
  String? _formError;

  /// Fixado ao abrir: o título não muda a meio por causa de um refresh.
  late final bool _changing =
      widget.mode == CreatePasswordMode.account &&
      (AppScope.of(context).session.session?.hasPassword ?? false);

  @override
  void dispose() {
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!PasswordCheck(_password.text).ok) {
      setState(() {
        _showErrors = true;
        _formError = null;
      });
      _focus.requestFocus();
      return;
    }
    final services = AppScope.of(context);
    setState(() {
      _loading = true;
      _formError = null;
    });
    try {
      // O aviso fica pronto antes de mudar de ecrã: "Com quem partilho"
      // lê-o ao abrir.
      await services.session.updatePassword(
        _password.text,
        notice: _changing ? AuthCopy.changed : AuthCopy.created,
      );
      services.connectivity.reportReachable();
      if (mounted) context.go(AppRoutes.client);
      return;
    } on AuthFailure catch (f) {
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _formError = f.kind == AuthFailureKind.weakPassword
              ? AuthCopy.weakServer
              : AuthCopy.saveFailed;
        });
      }
    }
  }

  Future<void> _notNow() async {
    final session = AppScope.of(context).session;
    if (widget.mode == CreatePasswordMode.prompt) {
      await session.dismissPasswordPrompt();
    }
    if (mounted) context.go(AppRoutes.client);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final prompt = widget.mode == CreatePasswordMode.prompt;
    final email = services.session.session?.email ?? '';
    return AuthLayout(
      tabLabel: AuthCopy.tabMyData,
      signedIn: true,
      offlineMessage: AuthCopy.offlineGeneral,
      children: [
        AuthTitle(_changing ? AuthCopy.changeTitle : AuthCopy.createTitle),
        const SizedBox(height: AppSpace.s8),
        Text(
          _changing ? AuthCopy.changeHelp : AuthCopy.createHelp,
          style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s24),
        Text(AuthCopy.email, style: AppType.rotulo),
        const SizedBox(height: AppSpace.s8),
        SelectableText(email, style: AppType.corpo),
        const SizedBox(height: AppSpace.s24),
        ListenableBuilder(
          listenable: services.connectivity,
          builder: (context, _) {
            final online = services.connectivity.online;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                NewPasswordField(
                  controller: _password,
                  focusNode: _focus,
                  autofocus: true,
                  readOnly: _loading,
                  showErrors: _showErrors,
                  onSubmitted: online ? _submit : null,
                ),
                if (_formError != null) ...[
                  const SizedBox(height: AppSpace.s24),
                  InlineNotice(kind: NoticeKind.erro, message: _formError!),
                ],
                const SizedBox(height: AppSpace.s24),
                PrimaryButton(
                  label: AuthCopy.savePassword,
                  loadingLabel: AuthCopy.saving,
                  loading: _loading,
                  principal: true,
                  expand: true,
                  onPressed: online ? _submit : null,
                  disabledReason: online ? null : AuthCopy.offlineSaveReason,
                ),
                const SizedBox(height: AppSpace.s12),
                SecondaryButton(
                  label: prompt ? AuthCopy.notNow : AuthCopy.cancel,
                  principal: true,
                  expand: true,
                  // Não precisa de servidor: continua ativo offline.
                  onPressed: _loading ? null : _notNow,
                ),
                if (prompt) ...[
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    AuthCopy.createFooter,
                    style: AppType.corpoPequeno.copyWith(
                      color: AppColors.tintaMedia,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
