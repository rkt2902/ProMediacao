import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'sent_notice.dart';

/// Formulário "pedir link de acesso" do cliente. Usado no separador "Sou
/// cliente" e no ecrã de link expirado (mesmo comportamento e confirmação).
class ClientLinkForm extends StatefulWidget {
  const ClientLinkForm({
    super.key,
    this.help,
    this.submitLabel = AuthCopy.clientSend,
    this.footer,
  });

  final String? help;
  final String submitLabel;

  /// Texto por baixo do botão (só no estado de formulário).
  final String? footer;

  @override
  State<ClientLinkForm> createState() => _ClientLinkFormState();
}

class _ClientLinkFormState extends State<ClientLinkForm> {
  final _email = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = AppScope.of(context).clientLink.email;
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
    await AppScope.of(context).clientLink.send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final link = services.clientLink;
    return ListenableBuilder(
      listenable: Listenable.merge([link, services.connectivity]),
      builder: (context, _) {
        if (link.status == ClientLinkStatus.sent) return _sent(link);
        return _form(link, online: services.connectivity.online);
      },
    );
  }

  Widget _sent(dynamic link) {
    final locked = link.remaining > 0;
    return SentNotice(
      before: AuthCopy.sentBefore,
      emphasis: link.email as String,
      after: AuthCopy.sentAfter,
      children: [
        const SizedBox(height: AppSpace.s8),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSize.icone + AppSpace.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextAction(
                label: AuthCopy.sendAgain,
                onPressed: locked ? null : () => link.send(link.email),
                disabledReason: locked
                    ? AuthCopy.waitToResend(link.remaining as int)
                    : null,
              ),
              if (locked)
                Text(
                  AuthCopy.waitToResend(link.remaining as int),
                  style: AppType.corpoPequeno.copyWith(
                    color: AppColors.tintaMedia,
                  ),
                ),
              TextAction(
                label: AuthCopy.otherEmail,
                onPressed: link.useAnotherEmail,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(dynamic link, {required bool online}) {
    final sending = link.status == ClientLinkStatus.sending;
    final failed = link.status == ClientLinkStatus.failed;
    final blocked = !(link.canSend(_email.text) as bool);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.help != null) ...[
          Text(
            widget.help!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
          const SizedBox(height: AppSpace.s16),
        ],
        LabeledField(
          label: AuthCopy.email,
          controller: _email,
          readOnly: sending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          errorText: _error,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => online && !blocked ? _submit() : null,
        ),
        if (failed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            kind: NoticeKind.erro,
            message: link.failure == AuthFailureKind.network
                ? AuthCopy.networkError
                : AuthCopy.sendFailed,
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        PrimaryButton(
          label: widget.submitLabel,
          loadingLabel: AuthCopy.sending,
          loading: sending,
          principal: true,
          expand: true,
          onPressed: online && !blocked ? _submit : null,
          disabledReason: online ? null : AuthCopy.offlineReason,
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: AppSpace.s16),
          Text(
            widget.footer!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ],
    );
  }
}
