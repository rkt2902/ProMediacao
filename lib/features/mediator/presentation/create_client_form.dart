import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/clients_controller.dart';
import '../domain/mediator_models.dart';
import 'mediator_copy.dart';

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Abre "Criar cliente": folha lateral de `folhaLateral` 440 em médio/largo,
/// ecrã inteiro (rota própria, cross-fade) em compacto. Devolve `true` se o
/// cliente foi criado.
Future<bool?> showCreateClient(
  BuildContext context, {
  required ClientsController controller,
  required String officeName,
  String? accountName,
  VoidCallback? onSignOut,
}) async {
  final origin = FocusManager.instance.primaryFocus;
  final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
  final Future<bool?> result;
  if (compact) {
    result = Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: AppMotion.resolve(context, AppMotion.base),
        reverseTransitionDuration: AppMotion.resolve(context, AppMotion.base),
        pageBuilder: (context, _, _) => CreateClientView(
          controller: controller,
          officeName: officeName,
          fullScreen: true,
          accountName: accountName,
          onSignOut: onSignOut,
        ),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
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
    result = Navigator.of(context).push<bool>(
      _SideSheetRoute<bool>(
        enter: AppMotion.resolve(context, AppMotion.lento),
        exit: AppMotion.resolve(context, AppMotion.base),
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (context) => CreateClientView(
          controller: controller,
          officeName: officeName,
          fullScreen: false,
        ),
      ),
    );
  }
  final created = await result;
  // Sem cliente criado, o foco volta a "Criar cliente".
  if (created != true &&
      origin != null &&
      origin.context != null &&
      origin.canRequestFocus) {
    origin.requestFocus();
  }
  return created;
}

/// Folha que desliza da direita (o lado do botão que a abre), com véu.
class _SideSheetRoute<T> extends PopupRoute<T> {
  _SideSheetRoute({
    required this.builder,
    required this.enter,
    required this.exit,
    required this.label,
  });

  final WidgetBuilder builder;
  final Duration enter;
  final Duration exit;
  final String label;

  @override
  Duration get transitionDuration => enter;

  @override
  Duration get reverseTransitionDuration => exit;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => AppColors.veu;

  @override
  String get barrierLabel => label;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: AppSize.folhaLateral,
        height: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.folha,
            boxShadow: AppShadow.superficie,
          ),
          child: Material(
            color: AppColors.folha,
            child: SafeArea(child: Builder(builder: builder)),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
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
  }
}

/// Formulário "Criar cliente". Em [fullScreen] (compacto) é uma página com
/// os botões no fluxo, a seguir aos campos; senão é o conteúdo da folha
/// lateral, com a barra de botões fixa no fundo.
class CreateClientView extends StatefulWidget {
  const CreateClientView({
    super.key,
    required this.controller,
    required this.officeName,
    required this.fullScreen,
    this.accountName,
    this.onSignOut,
  });

  final ClientsController controller;
  final String officeName;
  final bool fullScreen;
  final String? accountName;
  final VoidCallback? onSignOut;

  @override
  State<CreateClientView> createState() => _CreateClientViewState();
}

class _CreateClientViewState extends State<CreateClientView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  String? _nameError;
  String? _emailError;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _close([bool created = false]) =>
      Navigator.of(context).pop<bool>(created);

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final nameError = name.isEmpty ? MediatorCopy.nameEmpty : null;
    final emailError = email.isEmpty
        ? MediatorCopy.emailEmpty
        : (_emailPattern.hasMatch(email) ? null : MediatorCopy.emailInvalid);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _formError = null;
    });
    if (nameError != null) {
      _nameFocus.requestFocus();
      return;
    }
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.controller.createClient(
        fullName: name,
        email: email,
        successMessage: MediatorCopy.created(email),
        notSentMessage: MediatorCopy.createdNotSent,
      );
    } on MediatorFailure catch (f) {
      if (!mounted) return;
      final office = widget.officeName;
      setState(() {
        _submitting = false;
        switch (f.kind) {
          case MediatorFailureKind.alreadyClient:
            _emailError = MediatorCopy.alreadyClient(office);
          case MediatorFailureKind.declined:
            _emailError = MediatorCopy.declined(office);
          case MediatorFailureKind.invalidInput:
            _formError = MediatorCopy.formInvalid;
          case MediatorFailureKind.network:
            _formError = MediatorCopy.formNetwork;
          case MediatorFailureKind.forbidden:
            _formError = MediatorCopy.formForbidden;
          default:
            _formError = MediatorCopy.formGeneric;
        }
      });
      if (_emailError != null) _emailFocus.requestFocus();
      return;
    }
    // Só fecha com o servidor a confirmar (a lista e o aviso já estão feitos).
    if (mounted) _close(true);
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = AppScope.of(context).connectivity;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, connectivity]),
      builder: (context, _) {
        final online = connectivity.online;
        final fields = _fields();
        if (widget.fullScreen) return _page(fields, online);
        return _sheet(fields, online);
      },
    );
  }

  Widget _fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(MediatorCopy.sheetTitle, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          MediatorCopy.sheetIntro.replaceAll('{office}', widget.officeName),
          style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s24),
        LabeledField(
          label: MediatorCopy.fieldName,
          controller: _name,
          focusNode: _nameFocus,
          autofocus: !widget.fullScreen,
          enabled: !_submitting,
          errorText: _nameError,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpace.s16),
        LabeledField(
          label: MediatorCopy.fieldEmail,
          controller: _email,
          focusNode: _emailFocus,
          enabled: !_submitting,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpace.s24),
        const InlineNotice(message: MediatorCopy.sheetNote),
        if (_formError != null) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(message: _formError!, kind: NoticeKind.erro),
        ],
      ],
    );
  }

  Widget _submitButton(bool online, {required bool expand}) => PrimaryButton(
    label: MediatorCopy.submit,
    loadingLabel: MediatorCopy.submitting,
    loading: _submitting,
    principal: expand,
    expand: expand,
    onPressed: online ? _submit : null,
    disabledReason: online ? null : MediatorCopy.needsConnectionToCreate,
  );

  Widget _cancelButton({required bool expand}) => SecondaryButton(
    label: MediatorCopy.cancel,
    principal: expand,
    expand: expand,
    onPressed: _submitting ? null : _close,
  );

  /// Folha lateral: campos com scroll e barra de botões fixa no fundo (sobe
  /// com o teclado virtual).
  Widget _sheet(Widget fields, bool online) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: fields,
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.regua, width: AppStroke.fino),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.s24,
              AppSpace.s16,
              AppSpace.s24,
              AppSpace.s16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _cancelButton(expand: true)),
                const SizedBox(width: AppSpace.s12),
                Expanded(flex: 3, child: _submitButton(online, expand: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Compacto: ecrã inteiro, botões no fluxo a seguir aos campos, sem
  /// colofão (é uma passagem, não uma página).
  Widget _page(Widget fields, bool online) {
    return PageFrame(
      tabLabel: widget.officeName,
      accountName: widget.accountName,
      onSignOut: widget.onSignOut,
      maxWidth: AppSize.larguraFormulario,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32, bottom: AppSpace.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            fields,
            const SizedBox(height: AppSpace.s24),
            _submitButton(online, expand: true),
            const SizedBox(height: AppSpace.s12),
            _cancelButton(expand: true),
          ],
        ),
      ),
    );
  }
}
