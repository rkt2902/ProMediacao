import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/connectivity.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/validators.dart';
import '../application/admin_controller.dart';
import '../domain/admin_models.dart';
import 'admin_copy.dart';

/// Abre um formulário do admin: folha lateral (`folhaLateral` 440, à direita)
/// em médio e largo; rota de ecrã inteiro em compacto (03-design.md,
/// "Folhas e diálogos por tamanho"). Devolve `true` se o servidor confirmou.
Future<bool?> showAdminForm(
  BuildContext context, {
  required WidgetBuilder builder,
}) async {
  final origin = FocusManager.instance.primaryFocus;
  final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
  final Future<bool?> result;
  if (compact) {
    result = Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: AppMotion.resolve(context, AppMotion.base),
        reverseTransitionDuration: AppMotion.resolve(context, AppMotion.base),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppMotion.entrar,
            reverseCurve: AppMotion.sair,
          ),
          child: child,
        ),
      ),
    );
  } else {
    result = showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.veu,
      transitionDuration: AppMotion.resolve(context, AppMotion.lento),
      pageBuilder: (context, _, _) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: AppSize.folhaLateral,
          height: double.infinity,
          child: builder(context),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.entrar,
          reverseCurve: AppMotion.sair,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
  final value = await result;
  if (origin != null && origin.context != null && origin.canRequestFocus) {
    origin.requestFocus();
  }
  return value;
}

/// Estrutura comum dos dois formulários: folha lateral (botões numa barra
/// fixa no fundo) ou ecrã inteiro (botões no fluxo, a seguir aos campos).
class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.fields,
    required this.primaryLabel,
    required this.loadingLabel,
    required this.loading,
    required this.onSubmit,
    required this.onCancel,
    required this.onSignOut,
    this.intro,
    this.error,
    this.reason,
  });

  final String title;
  final String? intro;
  final List<Widget> fields;
  final String? error;

  /// Razão escrita quando o botão está desativado.
  final String? reason;
  final String primaryLabel;
  final String loadingLabel;
  final bool loading;
  final VoidCallback? onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final compact = bp == Breakpoint.compacto;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppType.tituloPara(bp)),
        ),
        if (intro != null) ...[
          const SizedBox(height: AppSpace.s12),
          Text(
            intro!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.s16),
          fields[i],
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(kind: NoticeKind.erro, message: error!),
        ],
        if (reason != null && onSubmit == null && !loading) ...[
          const SizedBox(height: AppSpace.s16),
          Text(
            reason!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ],
    );

    final primary = PrimaryButton(
      label: primaryLabel,
      loadingLabel: loadingLabel,
      loading: loading,
      principal: compact,
      expand: compact,
      onPressed: onSubmit,
    );
    final cancel = SecondaryButton(
      label: AdminCopy.cancel,
      principal: compact,
      expand: compact,
      onPressed: loading ? null : onCancel,
    );

    if (compact) {
      // Passagem, não página: sem colofão; botões no fluxo (o teclado virtual
      // ocupa metade do ecrã).
      return PageFrame(
        tabLabel: AdminCopy.tab,
        onSignOut: onSignOut,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpace.s32,
            bottom: AppSpace.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              body,
              const SizedBox(height: AppSpace.s24),
              primary,
              const SizedBox(height: AppSpace.s12),
              cancel,
            ],
          ),
        ),
      );
    }

    return Material(
      color: AppColors.folha,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.s24),
                child: body,
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.regua,
                    width: AppStroke.fino,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s24),
                // Wrap: com texto grande os botões passam para duas linhas
                // em vez de cortar.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.s12,
                  runSpacing: AppSpace.s12,
                  children: [cancel, primary],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageFor(AdminFailure f, {String? cannot}) => switch (f.kind) {
  AdminFailureKind.network => AdminCopy.networkError,
  AdminFailureKind.duplicateName => AdminCopy.duplicateOffice,
  AdminFailureKind.cannotInvite => cannot ?? AdminCopy.genericError,
  AdminFailureKind.sendFailed => AdminCopy.inviteSendFailed,
  _ => AdminCopy.genericError,
};

/// Criar escritório: um campo.
class CreateOfficeForm extends StatefulWidget {
  const CreateOfficeForm({
    super.key,
    required this.controller,
    required this.connectivity,
    required this.onSignOut,
  });

  final AdminController controller;
  final AppConnectivity connectivity;
  final VoidCallback onSignOut;

  @override
  State<CreateOfficeForm> createState() => _CreateOfficeFormState();
}

class _CreateOfficeFormState extends State<CreateOfficeForm> {
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid {
    final n = _name.text.trim();
    return n.isNotEmpty && n.length <= 200;
  }

  Future<void> _submit() async {
    if (_loading || !_valid || !widget.connectivity.online) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.createOffice(_name.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AdminFailure catch (f) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _messageFor(f);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.connectivity,
      builder: (context, _) {
        final online = widget.connectivity.online;
        final canSubmit = online && _valid;
        return _FormShell(
          title: AdminCopy.createOffice,
          fields: [
            LabeledField(
              label: AdminCopy.officeName,
              controller: _name,
              readOnly: _loading,
              autofocus: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(200)],
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
          ],
          error: _error,
          reason: online ? AdminCopy.officeNameReason : AdminCopy.offlineReason,
          primaryLabel: AdminCopy.createOffice,
          loadingLabel: AdminCopy.creating,
          loading: _loading,
          onSubmit: canSubmit || _loading ? _submit : null,
          onCancel: () => Navigator.of(context).pop(false),
          onSignOut: widget.onSignOut,
        );
      },
    );
  }
}

/// Convidar mediador: nome, email e escritório (só leitura). O email
/// escrito não é mostrado depois de enviado.
class InviteMediatorForm extends StatefulWidget {
  const InviteMediatorForm({
    super.key,
    required this.controller,
    required this.connectivity,
    required this.office,
    required this.onSignOut,
  });

  final AdminController controller;
  final AppConnectivity connectivity;
  final OfficeSummary office;
  final VoidCallback onSignOut;

  @override
  State<InviteMediatorForm> createState() => _InviteMediatorFormState();
}

class _InviteMediatorFormState extends State<InviteMediatorForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  late final TextEditingController _office = TextEditingController(
    text: widget.office.name,
  );
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _office.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _name.text.trim().length <= 120 &&
      validateEmail(_email.text) == null;

  Future<void> _submit() async {
    if (_loading || !_valid || !widget.connectivity.online) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.inviteMediator(
        officeId: widget.office.id,
        email: _email.text,
        fullName: _name.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AdminFailure catch (f) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _messageFor(f, cannot: AdminCopy.cannotInvite);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.connectivity,
      builder: (context, _) {
        final online = widget.connectivity.online;
        final canSubmit = online && _valid;
        void changed(String _) => setState(() => _error = null);
        return _FormShell(
          title: AdminCopy.inviteMediator,
          intro: AdminCopy.inviteHelp,
          fields: [
            LabeledField(
              label: AdminCopy.mediatorName,
              controller: _name,
              readOnly: _loading,
              autofocus: true,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              onChanged: changed,
            ),
            LabeledField(
              label: AdminCopy.email,
              controller: _email,
              readOnly: _loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: changed,
              onSubmitted: (_) => _submit(),
            ),
            LabeledField(
              label: AdminCopy.officeField,
              controller: _office,
              readOnly: true,
            ),
          ],
          error: _error,
          reason: online ? AdminCopy.inviteReason : AdminCopy.offlineReason,
          primaryLabel: AdminCopy.sendInvite,
          loadingLabel: AdminCopy.sending,
          loading: _loading,
          onSubmit: canSubmit || _loading ? _submit : null,
          onCancel: () => Navigator.of(context).pop(false),
          onSignOut: widget.onSignOut,
        );
      },
    );
  }
}
