import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/client_link_controller.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'sent_notice.dart';

/// Ecrã 2 (link expirado ou inválido), separador "Acesso". O cliente pede
/// um link novo (mesmo comportamento e confirmação da entrada) ou entra com
/// a palavra-passe. `forPassword` é a variante de quem abriu um link de
/// definir/recuperar palavra-passe.
class ExpiredLinkPage extends StatefulWidget {
  const ExpiredLinkPage({super.key, this.forPassword = false});

  final bool forPassword;

  @override
  State<ExpiredLinkPage> createState() => _ExpiredLinkPageState();
}

class _ExpiredLinkPageState extends State<ExpiredLinkPage> {
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  String? _error;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = AppScope.of(context);
    _email.text = services.session.lastEmail;
    services.clientLink.resetForNewScreen();
    // O erro já está explicado aqui: daqui em diante pode ir a Entrar.
    services.session.consumeLinkFailure();
  }

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = validateEmail(_email.text);
    setState(() => _error = error);
    if (error != null) {
      _emailFocus.requestFocus();
      return;
    }
    await AppScope.of(context).clientLink.send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forPassword) {
      return AuthLayout(
        offlineMessage: AuthCopy.offlineLink,
        children: [
          const AuthTitle(AuthCopy.linkInvalidTitle, focus: true),
          const SizedBox(height: AppSpace.s16),
          Text(AuthCopy.linkInvalidPassword, style: AppType.corpo),
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
              icon: Icons.arrow_back,
              onPressed: () => context.go(AppRoutes.entry),
            ),
          ),
        ],
      );
    }

    final services = AppScope.of(context);
    final link = services.clientLink;
    return AuthLayout(
      offlineMessage: AuthCopy.offlineLink,
      children: [
        const AuthTitle(AuthCopy.linkInvalidTitle, focus: true),
        const SizedBox(height: AppSpace.s16),
        Text(AuthCopy.linkInvalidClient, style: AppType.corpo),
        const SizedBox(height: AppSpace.s24),
        ListenableBuilder(
          listenable: Listenable.merge([link, services.connectivity]),
          builder: (context, _) {
            final sent = link.status == ClientLinkStatus.sent;
            return AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.base),
              switchInCurve: AppMotion.mudar,
              switchOutCurve: AppMotion.mudar,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: sent
                  ? KeyedSubtree(
                      key: const ValueKey('sent'),
                      child: LinkSentNotice(
                        onUseAnotherEmail: () {
                          _email.clear();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _emailFocus.requestFocus();
                          });
                        },
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('form'),
                      child: _form(link, online: services.connectivity.online),
                    ),
            );
          },
        ),
        const SizedBox(height: AppSpace.s24),
        Text(
          AuthCopy.linkInvalidMediator,
          style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
      ],
    );
  }

  Widget _form(ClientLinkController link, {required bool online}) {
    final sending = link.status == ClientLinkStatus.sending;
    final blocked = !link.canSend(_email.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledField(
          label: AuthCopy.email,
          controller: _email,
          focusNode: _emailFocus,
          readOnly: sending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          errorText: _error,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => online && !blocked ? _submit() : null,
        ),
        if (link.status == ClientLinkStatus.failed) ...[
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
          label: AuthCopy.sendNew,
          loadingLabel: AuthCopy.sending,
          loading: sending,
          principal: true,
          expand: true,
          onPressed: online && !blocked ? _submit : null,
          disabledReason: !online
              ? AuthCopy.offlineReason
              : (blocked && !sending
                    ? AuthCopy.waitToResend(link.remaining)
                    : null),
        ),
        const SizedBox(height: AppSpace.s16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextAction(
            label: AuthCopy.hasPassword,
            onPressed: sending
                ? null
                : () {
                    AppScope.of(context).session.lastEmail = _email.text;
                    context.go(AppRoutes.entry);
                  },
          ),
        ),
      ],
    );
  }
}
