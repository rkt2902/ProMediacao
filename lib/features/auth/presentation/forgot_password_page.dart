import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/client_link_controller.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'sent_notice.dart';

/// Ecrã 1b (recuperar): um campo; confirmação igual exista ou não a conta e
/// bloqueio de 60 s depois de cada envio (como o pedido de link).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  String? _error;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = AppScope.of(context);
    _email.text = services.session.lastEmail;
    services.passwordReset.resetForNewScreen();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateEmail(_email.text);
    setState(() => _error = error);
    if (error != null) return;
    // O controlador trata o "demasiado cedo" do Auth como envio: a
    // confirmação e o bloqueio de 60 s são iguais exista ou não a conta.
    await AppScope.of(context).passwordReset.send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final reset = services.passwordReset;
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      children: [
        const AuthTitle(AuthCopy.recoverTitle),
        const SizedBox(height: AppSpace.s16),
        ListenableBuilder(
          listenable: Listenable.merge([reset, services.connectivity]),
          builder: (context, _) {
            if (reset.status == ClientLinkStatus.sent) {
              return SentNotice(
                before: AuthCopy.recoverSent,
                children: [
                  const SizedBox(height: AppSpace.s16),
                  TextAction(
                    label: AuthCopy.backToSignIn,
                    icon: Icons.arrow_back,
                    onPressed: () => context.go(AppRoutes.entry),
                  ),
                ],
              );
            }
            return _form(reset, online: services.connectivity.online);
          },
        ),
      ],
    );
  }

  Widget _form(ClientLinkController reset, {required bool online}) {
    final sending = reset.status == ClientLinkStatus.sending;
    final blocked = !reset.canSend(_email.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AuthCopy.recoverHelp,
          style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s16),
        LabeledField(
          label: AuthCopy.email,
          controller: _email,
          readOnly: sending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofocus: true,
          autofillHints: const [AutofillHints.email],
          errorText: _error,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => online && !blocked ? _submit() : null,
        ),
        if (reset.status == ClientLinkStatus.failed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            kind: NoticeKind.erro,
            message: reset.failure == AuthFailureKind.network
                ? AuthCopy.networkError
                : AuthCopy.sendFailed,
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        PrimaryButton(
          label: AuthCopy.recoverSend,
          loadingLabel: AuthCopy.sending,
          loading: sending,
          principal: true,
          expand: true,
          onPressed: online && !blocked ? _submit : null,
          disabledReason: !online
              ? AuthCopy.offlineReason
              : (blocked && !sending
                    ? AuthCopy.waitToResend(reset.remaining)
                    : null),
        ),
        const SizedBox(height: AppSpace.s8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextAction(
            label: AuthCopy.backToSignIn,
            icon: Icons.arrow_back,
            onPressed: () => context.go(AppRoutes.entry),
          ),
        ),
      ],
    );
  }
}
