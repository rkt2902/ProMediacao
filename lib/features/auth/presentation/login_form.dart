import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';

/// Separador "Trabalho num escritório": email e palavra-passe.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onForgot});

  final VoidCallback onForgot;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_email.text);
    final passwordError = _password.text.isEmpty
        ? AuthCopy.passwordEmpty
        : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (emailError != null || passwordError != null) return;

    final services = AppScope.of(context);
    setState(() => _loading = true);
    try {
      await services.session.signIn(_email.text.trim(), _password.text);
      services.connectivity.reportReachable();
    } on AuthFailure catch (f) {
      if (!mounted) return;
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      setState(() {
        _loading = false;
        _formError = switch (f.kind) {
          AuthFailureKind.invalidCredentials => AuthCopy.badCredentials,
          AuthFailureKind.network => AuthCopy.networkError,
          _ => AuthCopy.genericError,
        };
      });
      if (f.kind == AuthFailureKind.invalidCredentials) {
        _emailFocus.requestFocus();
      }
      return;
    }
    // Sucesso: o router já mudou de ecrã.
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = AppScope.of(context).connectivity;
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        final online = connectivity.online;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AuthCopy.officeHelp,
              style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
            ),
            const SizedBox(height: AppSpace.s16),
            LabeledField(
              label: AuthCopy.email,
              controller: _email,
              focusNode: _emailFocus,
              readOnly: _loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              errorText: _emailError,
            ),
            const SizedBox(height: AppSpace.s16),
            LabeledField(
              label: AuthCopy.password,
              controller: _password,
              readOnly: _loading,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              errorText: _passwordError,
              onSubmitted: (_) => online && !_loading ? _submit() : null,
              trailing: TextAction(
                label: _obscure ? AuthCopy.show : AuthCopy.hide,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppSpace.s16),
              InlineNotice(kind: NoticeKind.erro, message: _formError!),
            ],
            const SizedBox(height: AppSpace.s24),
            PrimaryButton(
              label: AuthCopy.signIn,
              loadingLabel: AuthCopy.signingIn,
              loading: _loading,
              principal: true,
              expand: true,
              onPressed: online ? _submit : null,
              disabledReason: online ? null : AuthCopy.offlineReason,
            ),
            const SizedBox(height: AppSpace.s8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextAction(
                label: AuthCopy.forgot,
                onPressed: _loading ? null : widget.onForgot,
              ),
            ),
          ],
        );
      },
    );
  }
}
