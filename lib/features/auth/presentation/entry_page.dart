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

/// Ecrã 1 (03-design.md): um só formulário para todos (email e
/// palavra-passe), "Esqueci-me da palavra-passe" e, separada por uma régua,
/// a alternativa só para clientes "Receber link de acesso por email", que
/// usa o email de cima.
class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

enum _FormError { credentials, network, generic }

class _EntryPageState extends State<EntryPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;
  _FormError? _formError;
  bool _signingIn = false;
  bool _obscure = true;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = AppScope.of(context);
    _email.text = services.session.lastEmail;
    services.clientLink.resetForNewScreen();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final emailError = validateEmail(_email.text);
    final passwordError = _password.text.isEmpty
        ? AuthCopy.passwordEmpty
        : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    final services = AppScope.of(context);
    setState(() => _signingIn = true);
    try {
      await services.session.signIn(_email.text.trim(), _password.text);
      services.connectivity.reportReachable();
    } on AuthFailure catch (f) {
      if (!mounted) return;
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      setState(() {
        _signingIn = false;
        _formError = switch (f.kind) {
          AuthFailureKind.invalidCredentials => _FormError.credentials,
          AuthFailureKind.network => _FormError.network,
          _ => _FormError.generic,
        };
      });
      if (f.kind == AuthFailureKind.invalidCredentials) {
        _emailFocus.requestFocus();
      }
      return;
    }
    // Sucesso: o router já mudou de ecrã.
    if (mounted) setState(() => _signingIn = false);
  }

  Future<void> _requestLink() async {
    // Só o email conta; a palavra-passe é ignorada.
    final emailError = validateEmail(_email.text);
    setState(() {
      _emailError = emailError;
      _passwordError = null;
      _formError = null;
    });
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    await AppScope.of(context).clientLink.send(_email.text);
  }

  void _backToForm({bool clearEmail = false}) {
    if (clearEmail) _email.clear();
    AppScope.of(context).clientLink.useAnotherEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final link = services.clientLink;
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      children: [
        const AuthTitle(AuthCopy.title),
        ListenableBuilder(
          listenable: services.session,
          builder: (context, _) {
            if (!services.session.sessionEnded) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(top: AppSpace.s24),
              child: InlineNotice(
                kind: NoticeKind.aviso,
                message: AuthCopy.sessionEnded,
              ),
            );
          },
        ),
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
                      child: _sentView(),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('form'),
                      child: _form(link, online: services.connectivity.online),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _sentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinkSentNotice(onUseAnotherEmail: () => _backToForm(clearEmail: true)),
        const SizedBox(height: AppSpace.s16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextAction(
            label: AuthCopy.backToPassword,
            icon: Icons.arrow_back,
            onPressed: _backToForm,
          ),
        ),
      ],
    );
  }

  Widget _form(ClientLinkController link, {required bool online}) {
    final sendingLink = link.status == ClientLinkStatus.sending;
    final busy = _signingIn || sendingLink;
    final linkBlocked = !link.canSend(_email.text);
    final linkFailed = link.status == ClientLinkStatus.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: AuthCopy.email,
                controller: _email,
                focusNode: _emailFocus,
                autofocus: true,
                readOnly: busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                errorText: _emailError,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpace.s16),
              LabeledField(
                label: AuthCopy.password,
                controller: _password,
                focusNode: _passwordFocus,
                readOnly: busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.password],
                errorText: _passwordError,
                // Enter submete sempre "Entrar", nunca o link.
                onSubmitted: (_) => online && !busy ? _signIn() : null,
                trailing: TextAction(
                  label: _obscure ? AuthCopy.show : AuthCopy.hide,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ],
          ),
        ),
        if (_formError != null) ...[
          const SizedBox(height: AppSpace.s24),
          InlineNotice(
            kind: NoticeKind.erro,
            message: switch (_formError!) {
              _FormError.credentials => AuthCopy.badCredentials,
              _FormError.network => AuthCopy.networkError,
              _FormError.generic => AuthCopy.genericError,
            },
            detail: _formError == _FormError.credentials
                ? AuthCopy.badCredentialsHint
                : null,
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        PrimaryButton(
          label: AuthCopy.signIn,
          loadingLabel: AuthCopy.signingIn,
          loading: _signingIn,
          principal: true,
          expand: true,
          onPressed: online && !sendingLink ? _signIn : null,
          disabledReason: online ? null : AuthCopy.offlineReason,
        ),
        const SizedBox(height: AppSpace.s8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextAction(
            label: AuthCopy.forgot,
            onPressed: busy
                ? null
                : () {
                    AppScope.of(context).session.lastEmail = _email.text;
                    context.go(AppRoutes.recover);
                  },
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        const AppRule(),
        const SizedBox(height: AppSpace.s24),
        Text(AuthCopy.linkQuestion, style: AppType.corpoForte),
        const SizedBox(height: AppSpace.s4),
        Text(
          AuthCopy.linkHelp,
          style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
        if (linkFailed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            kind: NoticeKind.erro,
            message: link.failure == AuthFailureKind.network
                ? AuthCopy.networkError
                : AuthCopy.sendFailed,
          ),
        ],
        const SizedBox(height: AppSpace.s16),
        SecondaryButton(
          label: AuthCopy.linkButton,
          loadingLabel: AuthCopy.sending,
          loading: sendingLink,
          principal: true,
          expand: true,
          onPressed: online && !_signingIn && !linkBlocked
              ? _requestLink
              : null,
          disabledReason: !online
              ? AuthCopy.offlineReason
              : (linkBlocked && !sendingLink
                    ? AuthCopy.waitToResend(link.remaining)
                    : null),
        ),
      ],
    );
  }
}
