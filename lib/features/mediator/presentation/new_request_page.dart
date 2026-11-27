import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../../requests/application/new_request_controller.dart';
import '../../requests/domain/request_models.dart';
import '../data/supabase_mediator_repository.dart';
import '../domain/mediator_models.dart';
import '../domain/mediator_repository.dart';
import 'mediator_copy.dart';
import 'new_request_sections.dart';
import 'request_copy.dart';
import 'request_parts.dart';

/// Novo pedido (03-design.md, ecrã 1): escolhas à esquerda (largo) ou em
/// cima, a folha "O cliente vai receber" ao lado ou por baixo, e a barra
/// fixa com "Criar N pedidos".
///
/// [clientId]: cliente já escolhido (vindo da ficha ou de uma linha de
/// Clientes); nulo = começa pela escolha. [fromClientFile]: veio da ficha
/// (o regresso é o nome do cliente e volta à ficha).
/// [mediatorRepository] só serve a "Reenviar pedido de partilha" (cliente
/// pendente) e aos testes.
class NewRequestPage extends StatefulWidget {
  const NewRequestPage({
    super.key,
    this.clientId,
    this.fromClientFile = false,
    this.mediatorRepository,
  });

  final String? clientId;
  final bool fromClientFile;
  final MediatorRepository? mediatorRepository;

  @override
  State<NewRequestPage> createState() => _NewRequestPageState();
}

class _NewRequestPageState extends State<NewRequestPage> {
  NewRequestController? _controller;
  bool _resending = false;
  String? _grantNotice;
  bool _grantNoticeIsError = false;

  NewRequestController get c => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    _controller = NewRequestController(
      services.requests,
      services.requestEmail,
      services.connectivity,
      services.requestsHandoff,
      preselectedClientId: widget.clientId,
    )..start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _back() => goTo(
    context,
    widget.fromClientFile && widget.clientId != null
        ? AppRoutes.mediatorClient(widget.clientId!)
        : AppRoutes.mediator,
  );

  void _toClients() => goTo(context, AppRoutes.mediator);

  Future<void> _submit() async {
    final batch = await c.submit();
    if (batch != null && mounted) {
      goTo(context, AppRoutes.mediatorClient(batch.clientId));
    }
  }

  Future<void> _resendGrant(ClientHeader h) async {
    final grantId = h.grantId;
    if (grantId == null || _resending) return;
    setState(() {
      _resending = true;
      _grantNotice = null;
    });
    final repo =
        widget.mediatorRepository ??
        SupabaseMediatorRepository(Supabase.instance.client);
    var ok = false;
    try {
      await repo.resendRequest(grantId);
      ok = true;
    } on MediatorFailure catch (f) {
      if (f.kind == MediatorFailureKind.network && mounted) {
        AppScope.of(context).connectivity.reportNetworkFailure();
      }
    }
    if (!mounted) return;
    setState(() {
      _resending = false;
      _grantNoticeIsError = !ok;
      _grantNotice = ok
          ? RequestCopy.resendGrantDone
          : RequestCopy.resendGrantFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        c,
        services.connectivity,
        services.session,
      ]),
      builder: (context, _) {
        final online = services.connectivity.online;
        final session = services.session;
        final showBar = _showForm;
        return PageFrame(
          tabLabel: session.session?.officeName ?? MediatorCopy.fallbackOffice,
          accountName: accountNameFor(session.session),
          onSignOut: session.signOut,
          backLabel: widget.fromClientFile
              ? (c.client?.fullName ?? RequestCopy.backFallback)
              : RequestCopy.backClients,
          onBack: _back,
          banner: OfflineBar(visible: !online),
          colophon: const SessionColophon(),
          bottom: showBar ? _bar(context, online) : null,
          child: Padding(
            padding: const EdgeInsets.only(top: PageFrame.contentTop),
            child: _content(context),
          ),
        );
      },
    );
  }

  /// O formulário (e a barra) só existem com cliente possível: não quando o
  /// cliente pré-escolhido não tem acesso ou não há clientes ativos.
  bool get _showForm {
    if (widget.clientId != null) {
      return c.preselectLoad != RequestsLoad.error &&
          c.unavailableClient == null;
    }
    return !_noActiveClients;
  }

  bool get _noActiveClients =>
      c.clientsLoad == RequestsLoad.ready &&
      c.clients.isEmpty &&
      c.client == null;

  Widget _title() {
    final bp = AppBreakpoints.fromContext(context);
    return Focus(
      autofocus: bp != Breakpoint.compacto,
      child: Semantics(
        header: true,
        child: Text(RequestCopy.newRequest, style: AppType.tituloPara(bp)),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final head = <Widget>[
      _title(),
      const SizedBox(height: AppSpace.s8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.larguraLeitura),
        child: Text(
          RequestCopy.newRequestIntro,
          style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
        ),
      ),
      const SizedBox(height: AppSpace.s48),
    ];

    Widget body;
    final unavailable = c.unavailableClient;
    if (widget.clientId != null && c.preselectLoad == RequestsLoad.error) {
      body = InlineNotice(
        kind: NoticeKind.erro,
        message: RequestCopy.preselectError,
        actionLabel: RequestCopy.retry,
        onAction: c.retry,
      );
    } else if (unavailable != null) {
      body = _Unavailable(
        header: unavailable,
        resending: _resending,
        notice: _grantNotice,
        noticeIsError: _grantNoticeIsError,
        onResend: () => _resendGrant(unavailable),
        onBack: _toClients,
      );
    } else if (_noActiveClients) {
      body = _NoActiveClients(
        onCreateClient: _toClients,
        onSeePending: _toClients,
      );
    } else {
      final wide = bp == Breakpoint.largo;
      final choices = _Choices(controller: c);
      final sheets = c.catalogLoad == RequestsLoad.ready
          ? SheetsZone(controller: c)
          : const SizedBox.shrink();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.clientLost) ...[
            InlineNotice(
              kind: NoticeKind.erro,
              message: RequestCopy.clientLost,
              detail: RequestCopy.clientLostDetail,
              actionLabel: RequestCopy.backToClients,
              onAction: _toClients,
            ),
            const SizedBox(height: AppSpace.s32),
          ],
          IgnorePointer(
            ignoring: c.submitting,
            child: ExcludeFocus(
              excluding: c.submitting,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: AppSize.larguraFormulario,
                          child: choices,
                        ),
                        const SizedBox(width: AppSpace.s48),
                        Expanded(child: sheets),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        choices,
                        const SizedBox(height: AppSpace.s48),
                        sheets,
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.s48),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [...head, body],
    );
  }

  // ---- Barra fixa -----------------------------------------------------------

  Widget _bar(BuildContext context, bool online) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final toCreate = c.typesToCreate;
    final n = toCreate.length;
    final client = c.client?.fullName;
    final title = RequestCopy.summaryTitle(n, client);
    final types = RequestCopy.summaryTypes(
      [for (final t in toCreate) t.name],
      c.allowPolicyConditions,
      [for (final t in c.typesAwaitingConfirmation) t.name],
    );
    final block = c.block;
    final reason = block == null
        ? null
        : RequestCopy.blockReason(block, c.blockedType?.name);
    final error = _errorText();

    final summary = Semantics(
      container: true,
      label: RequestCopy.summaryRegion,
      child: AnimatedSwitcher(
        duration: AppMotion.resolve(context, AppMotion.rapido),
        switchInCurve: AppMotion.mudar,
        switchOutCurve: AppMotion.mudar,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [...previous, ?current],
        ),
        child: Semantics(
          key: ValueKey('$title|$types'),
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.corpoForte,
              ),
              if (types.isNotEmpty)
                Text(
                  types,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.corpoPequeno.copyWith(
                    color: AppColors.tintaMedia,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final button = PrimaryButton(
      label: RequestCopy.create(n),
      loadingLabel: RequestCopy.creating,
      loading: c.submitting,
      principal: compact,
      expand: compact,
      onPressed: c.canSubmit ? _submit : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null) ...[
          InlineNotice(kind: NoticeKind.erro, message: error),
          const SizedBox(height: AppSpace.s12),
        ],
        if (compact) ...[
          summary,
          const SizedBox(height: AppSpace.s12),
          button,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: summary),
              const SizedBox(width: AppSpace.s24),
              button,
            ],
          ),
        if (reason != null && !c.submitting) ...[
          const SizedBox(height: AppSpace.s8),
          Text(
            reason,
            textAlign: compact ? TextAlign.start : TextAlign.end,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ],
    );
  }

  /// Falha do último "Criar" que a barra diz (as outras já se veem noutro
  /// sítio: concessão perdida no topo, repetido no tipo, mensagem no contador).
  String? _errorText() {
    final e = c.error;
    if (e == null) return null;
    return switch (e.kind) {
      RequestFailureKind.clientNotAvailable ||
      RequestFailureKind.repeatedRequest ||
      RequestFailureKind.messageTooLong => null,
      RequestFailureKind.network => RequestCopy.createNetwork,
      _ => RequestCopy.createFailed,
    };
  }
}

// ---------------------------------------------------------------------------
// Escolhas (secções 1 a 4)
// ---------------------------------------------------------------------------

class _Choices extends StatelessWidget {
  const _Choices({required this.controller});

  final NewRequestController controller;

  NewRequestController get c => controller;

  @override
  Widget build(BuildContext context) {
    final Widget clientBody;
    if (c.client != null) {
      clientBody = ChosenClient(
        client: c.client!,
        onChange: c.submitting ? null : c.changeClient,
      );
    } else if (c.preselectedClientId != null) {
      clientBody = const SkeletonRows(count: 1);
    } else {
      clientBody = ClientPicker(controller: c);
    }

    final Widget typesBody = switch (c.catalogLoad) {
      RequestsLoad.loading => const SkeletonRows(count: 13),
      RequestsLoad.error => InlineNotice(
        kind: NoticeKind.erro,
        message: RequestCopy.catalogError,
        actionLabel: RequestCopy.retry,
        onAction: c.retry,
      ),
      RequestsLoad.ready => TypeChoices(controller: c),
    };
    final catalogReady = c.catalogLoad == RequestsLoad.ready;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Section(
          number: 1,
          title: RequestCopy.sectionClient,
          child: clientBody,
        ),
        const SizedBox(height: AppSpace.s32),
        _Section(
          number: 2,
          title: RequestCopy.sectionTypes,
          hint: RequestCopy.sectionTypesHint,
          child: typesBody,
        ),
        if (catalogReady) ...[
          const SizedBox(height: AppSpace.s32),
          _Section(
            number: 3,
            title: RequestCopy.sectionPolicy,
            child: RuledList(
              children: [
                CheckRow(
                  label: RequestCopy.allowPolicy,
                  description: RequestCopy.allowPolicyHint,
                  checked: c.allowPolicyConditions,
                  onChanged: c.submitting
                      ? null
                      : (v) => c.allowPolicyConditions = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s32),
          _Section(
            number: 4,
            title: RequestCopy.sectionMessage,
            child: MessageField(controller: c),
          ),
        ],
      ],
    );
  }
}

/// Secção numerada: o corpo alinha pelo texto do título em médio/largo e
/// encosta à margem em compacto.
class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
    this.hint,
  });

  final int number;
  final String title;
  final String? hint;
  final Widget child;

  static const double _indent = AppSpace.s16 + AppSpace.s12;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label: '$number, $title',
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: _indent,
                child: Text(
                  '$number',
                  style: AppType.subtitulo.copyWith(
                    color: AppColors.tintaTenue,
                  ),
                ),
              ),
              Expanded(child: Text(title, style: AppType.subtitulo)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: compact ? 0 : _indent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint != null) ...[
                const SizedBox(height: AppSpace.s4),
                Text(
                  hint!,
                  style: AppType.corpoPequeno.copyWith(
                    color: AppColors.tintaMedia,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s16),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Estados sem formulário
// ---------------------------------------------------------------------------

class _NoActiveClients extends StatelessWidget {
  const _NoActiveClients({
    required this.onCreateClient,
    required this.onSeePending,
  });

  final VoidCallback onCreateClient;
  final VoidCallback onSeePending;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(RequestCopy.noActiveTitle, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.larguraLeitura),
          child: Text(
            RequestCopy.noActiveBody,
            style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        Wrap(
          spacing: AppSpace.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryButton(
              label: RequestCopy.createClient,
              principal: compact,
              expand: compact,
              onPressed: onCreateClient,
            ),
            TextAction(label: RequestCopy.seePending, onPressed: onSeePending),
          ],
        ),
      ],
    );
  }
}

/// Cliente pré-escolhido sem concessão ativa (US 2.1): motivo e o que fazer.
class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.header,
    required this.resending,
    required this.notice,
    required this.noticeIsError,
    required this.onResend,
    required this.onBack,
  });

  final ClientHeader header;
  final bool resending;
  final String? notice;
  final bool noticeIsError;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final access = header.access;
    if (access == ClientAccess.unavailable) {
      return NoAccessBlock(onBack: onBack);
    }
    final stamp = access == ClientAccess.pending
        ? StampStatus.pendente
        : StampStatus.recusado;
    final since = header.since;
    final reason = access == ClientAccess.pending
        ? RequestCopy.reasonPending
        : RequestCopy.reasonDeclined;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(header.fullName ?? '', style: AppType.subtitulo),
        if (header.email != null)
          Text(
            header.email!,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        const SizedBox(height: AppSpace.s12),
        Wrap(
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusStamp(status: stamp),
            if (since != null)
              Text(AppDates.dateTime(since), style: AppType.registo),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        InlineNotice(
          kind: NoticeKind.aviso,
          message: RequestCopy.noRequestsForClient,
          detail: reason,
        ),
        if (notice != null) ...[
          const SizedBox(height: AppSpace.s12),
          InlineNotice(
            kind: noticeIsError ? NoticeKind.erro : NoticeKind.info,
            message: notice!,
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        Wrap(
          spacing: AppSpace.s16,
          runSpacing: AppSpace.s12,
          children: [
            if (access == ClientAccess.pending && header.grantId != null)
              SecondaryButton(
                label: RequestCopy.resendGrant,
                loadingLabel: 'A enviar…',
                loading: resending,
                principal: compact,
                expand: compact,
                onPressed: onResend,
              ),
            SecondaryButton(
              label: RequestCopy.backToClients,
              principal: compact,
              expand: compact,
              onPressed: onBack,
            ),
          ],
        ),
      ],
    );
  }
}
