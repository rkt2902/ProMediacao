import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/password_rules.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'new_password_field.dart';

/// Ecrã 1b (definir): vindo da recuperação (qualquer perfil) ou do convite
/// de mediador. Exige sessão (o router manda para o link expirado se não
/// houver). Regras da 1d em tempo real; o botão só fica desativado offline
/// e durante o envio.
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _password = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  bool _showErrors = false;
  String? _formError;

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
      await services.session.updatePassword(_password.text);
      services.connectivity.reportReachable();
      final role = services.session.role;
      if (mounted && role != null) context.go(homeFor(role));
    } on AuthFailure catch (f) {
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      if (mounted) {
        setState(() {
          _formError = switch (f.kind) {
            AuthFailureKind.network => AuthCopy.networkError,
            AuthFailureKind.weakPassword => AuthCopy.weakServer,
            _ => AuthCopy.saveFailed,
          };
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final session = services.session.session;
    final invited =
        session?.method == SignInMethod.invite && session?.officeName != null;
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      children: [
        const AuthTitle(AuthCopy.setTitle),
        if (invited) ...[
          const SizedBox(height: AppSpace.s8),
          Text.rich(
            TextSpan(
              style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
              children: [
                const TextSpan(text: AuthCopy.invitedBefore),
                TextSpan(text: session!.officeName, style: AppType.corpoForte),
                const TextSpan(text: '.'),
              ],
            ),
            semanticsLabel: AuthCopy.invitedTo(session.officeName!),
          ),
        ],
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
                  label: AuthCopy.saveAndEnter,
                  loadingLabel: AuthCopy.saving,
                  loading: _loading,
                  principal: true,
                  expand: true,
                  onPressed: online ? _submit : null,
                  disabledReason: online ? null : AuthCopy.offlineSaveReason,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
