import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../app/connectivity.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../application/clients_controller.dart';
import '../data/supabase_mediator_repository.dart';
import '../domain/mediator_models.dart';
import '../domain/mediator_repository.dart';
import 'clients_list.dart';
import 'create_client_form.dart';
import 'mediator_copy.dart';

/// Ecrã inicial do mediador: "Clientes" (03-design.md, ecrã 5). Sem
/// [repository] usa o Supabase da app; os testes passam um fake.
class MediatorHomePage extends StatefulWidget {
  const MediatorHomePage({super.key, this.repository, this.now});

  final MediatorRepository? repository;

  /// Relógio (para testar o bloqueio de 60 s). Por defeito, a hora real.
  final DateTime Function()? now;

  @override
  State<MediatorHomePage> createState() => _MediatorHomePageState();
}

class _MediatorHomePageState extends State<MediatorHomePage> {
  ClientsController? _controller;
  AppConnectivity? _connectivity;
  bool _wasOnline = true;

  ClientsController get controller => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final connectivity = AppScope.of(context).connectivity;
    _controller = ClientsController(
      widget.repository ?? SupabaseMediatorRepository(Supabase.instance.client),
      connectivity,
      now: widget.now,
    )..start();
    _connectivity = connectivity..addListener(_onConnectivity);
  }

  /// Quando a ligação volta e a lista não chegou, tenta de novo sozinha.
  void _onConnectivity() {
    final online = _connectivity!.online;
    if (online && !_wasOnline && controller.load == ClientsLoad.error) {
      controller.start();
    }
    _wasOnline = online;
  }

  @override
  void dispose() {
    _connectivity?.removeListener(_onConnectivity);
    _controller?.dispose();
    super.dispose();
  }

  String _officeName() =>
      AppScope.of(context).session.session?.officeName ??
      MediatorCopy.fallbackOffice;

  Future<void> _create() {
    final services = AppScope.of(context);
    return showCreateClient(
      context,
      controller: controller,
      officeName: _officeName(),
      accountName: accountNameFor(services.session.session),
      onSignOut: services.session.signOut,
    );
  }

  void _resend(OfficeClient c) => controller.resend(
    c,
    sentMessage: MediatorCopy.resent,
    inAppMessage: MediatorCopy.resentInApp,
    notPendingMessage: MediatorCopy.resendNotPending,
    sendFailedMessage: MediatorCopy.resendSendFailed,
    networkMessage: MediatorCopy.resendNetwork,
    genericMessage: MediatorCopy.resendGeneric,
  );

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final connectivity = services.connectivity;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        connectivity,
        services.session,
      ]),
      builder: (context, _) {
        final online = connectivity.online;
        final session = services.session;
        return PageFrame(
          tabLabel: session.session?.officeName ?? _officeName(),
          accountName: accountNameFor(session.session),
          onSignOut: session.signOut,
          banner: OfflineBar(visible: !online, message: MediatorCopy.offline),
          colophon: const SessionColophon(),
          child: Padding(
            padding: const EdgeInsets.only(top: PageFrame.contentTop),
            child: _content(context, online),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, bool online) {
    final c = controller;
    final empty = c.load == ClientsLoad.ready && c.items.isEmpty;
    if (empty) return _emptyState(online);

    final ready = c.load == ClientsLoad.ready;
    final notice = c.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(online, showSummary: ready),
        if (notice != null) ...[
          const SizedBox(height: AppSpace.s24),
          InlineNotice(
            key: ValueKey(notice.id),
            message: notice.message,
            kind: switch (notice.kind) {
              ClientsNoticeKind.info => NoticeKind.info,
              ClientsNoticeKind.aviso => NoticeKind.aviso,
              ClientsNoticeKind.erro => NoticeKind.erro,
            },
          ),
        ],
        const SizedBox(height: AppSpace.s32),
        switch (c.load) {
          ClientsLoad.loading => const SkeletonRows(count: 6),
          ClientsLoad.error => InlineNotice(
            message: MediatorCopy.loadError,
            kind: NoticeKind.erro,
            actionLabel: MediatorCopy.retry,
            onAction: online ? c.start : null,
          ),
          ClientsLoad.ready => _list(online),
        },
      ],
    );
  }

  Widget _list(bool online) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nome e email selecionáveis para copiar (rato e toque longo).
        SelectionArea(
          child: ClientsList(controller: c, online: online, onResend: _resend),
        ),
        if (c.loadMoreFailed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            message: MediatorCopy.loadMoreError,
            kind: NoticeKind.erro,
            actionLabel: MediatorCopy.retry,
            onAction: online ? c.loadMore : null,
          ),
        ],
        if (c.hasMore) ...[
          const SizedBox(height: AppSpace.s24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SecondaryButton(
              label: MediatorCopy.showMore,
              loadingLabel: MediatorCopy.loadingMore,
              loading: c.loadingMore,
              onPressed: online ? c.loadMore : null,
              disabledReason: online ? null : MediatorCopy.needsConnection,
            ),
          ),
        ],
      ],
    );
  }

  Widget _title() {
    final bp = AppBreakpoints.fromContext(context);
    return Focus(
      autofocus: bp != Breakpoint.compacto,
      child: Semantics(
        header: true,
        child: Text(MediatorCopy.title, style: AppType.tituloPara(bp)),
      ),
    );
  }

  /// Título, contagem e "Criar cliente": à direita do título em médio/largo,
  /// por baixo da contagem e a toda a largura em compacto.
  Widget _header(bool online, {required bool showSummary}) {
    final c = controller;
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final summary = showSummary
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Text(
              MediatorCopy.summary(
                total: c.items.length,
                pending: c.items
                    .where((e) => e.status == ClientStatus.pendente)
                    .length,
                declined: c.items
                    .where((e) => e.status == ClientStatus.recusado)
                    .length,
                partial: c.hasMore,
                officeTotal: c.total,
              ),
              style: AppType.registo,
            ),
          )
        : const SizedBox.shrink();
    final button = PrimaryButton(
      label: MediatorCopy.createClient,
      principal: compact,
      expand: compact,
      onPressed: online ? _create : null,
      disabledReason: online ? null : MediatorCopy.needsConnection,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _title(),
          summary,
          const SizedBox(height: AppSpace.s24),
          button,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_title(), summary],
          ),
        ),
        const SizedBox(width: AppSpace.s16),
        button,
      ],
    );
  }

  /// Sem clientes: o botão do cabeçalho desaparece e fica só o do estado
  /// vazio (uma ação principal por ecrã).
  Widget _emptyState(bool online) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final notice = controller.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(),
        if (notice != null) ...[
          const SizedBox(height: AppSpace.s24),
          InlineNotice(key: ValueKey(notice.id), message: notice.message),
        ],
        const SizedBox(height: AppSpace.s32),
        Semantics(
          header: true,
          child: Text(MediatorCopy.emptyTitle, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          MediatorCopy.emptyBody.replaceAll('{office}', _officeName()),
          style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrimaryButton(
            label: MediatorCopy.createClient,
            principal: compact,
            expand: compact,
            onPressed: online ? _create : null,
            disabledReason: online ? null : MediatorCopy.needsConnection,
          ),
        ),
      ],
    );
  }
}
