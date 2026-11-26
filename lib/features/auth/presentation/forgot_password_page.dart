import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'sent_notice.dart';

/// Ecrã 1b (recuperar): um campo; confirmação igual exista ou não a conta.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  String? _error;
  String? _formError;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateEmail(_email.text);
    setState(() {
      _error = error;
      _formError = null;
    });
    if (error != null) return;
    final services = AppScope.of(context);
    setState(() => _loading = true);
    try {
      await services.auth.sendPasswordReset(_email.text.trim());
      services.connectivity.reportReachable();
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (f) {
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      if (mounted) {
        setState(() {
          _formError = f.kind == AuthFailureKind.network
              ? AuthCopy.networkError
              : AuthCopy.sendFailed;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      tabs: const FolderTab(label: AuthCopy.tabOffice),
      children: [
        const SizedBox(height: AppSpace.s32),
        Semantics(
          header: true,
          child: Text(
            AuthCopy.recoverTitle,
            style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        if (_sent)
          SentNotice(
            before: AuthCopy.recoverSent,
            children: [
              const SizedBox(height: AppSpace.s8),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSize.icone + AppSpace.s12,
                ),
                child: TextAction(
                  label: AuthCopy.backToSignIn,
                  onPressed: () => context.go(AppRoutes.entry),
                ),
              ),
            ],
          )
        else
          ListenableBuilder(
            listenable: services.connectivity,
            builder: (context, _) {
              final online = services.connectivity.online;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AuthCopy.recoverHelp,
                    style: AppType.corpoPequeno.copyWith(
                      color: AppColors.tintaMedia,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  LabeledField(
                    label: AuthCopy.email,
                    controller: _email,
                    readOnly: _loading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    autofillHints: const [AutofillHints.email],
                    errorText: _error,
                    onSubmitted: (_) => online && !_loading ? _submit() : null,
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: AppSpace.s16),
                    InlineNotice(kind: NoticeKind.erro, message: _formError!),
                  ],
                  const SizedBox(height: AppSpace.s24),
                  PrimaryButton(
                    label: AuthCopy.recoverSend,
                    loadingLabel: AuthCopy.sending,
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
                      label: AuthCopy.backToSignIn,
                      onPressed: () => context.go(AppRoutes.entry),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
