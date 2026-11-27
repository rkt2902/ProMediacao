import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../../requests/application/batch_email_controller.dart';
import '../../requests/application/client_file_controller.dart';
import '../../requests/application/requests_load.dart';
import '../../requests/domain/request_models.dart';
import 'mediator_copy.dart';
import 'request_copy.dart';
import 'request_parts.dart';

/// Ficha do cliente (03-design.md, ecrã 3): cabeçalho, pedidos deste
/// escritório, e, vindo do Novo pedido, o resultado da criação com o email
/// ("Reenviar email"). O cliente pode ter acesso retirado ou não existir:
/// "Sem acesso", sem revelar nada.
class ClientFilePage extends StatefulWidget {
  const ClientFilePage({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientFilePage> createState() => _ClientFilePageState();
}

enum _FileLayout { three, two, stacked }

_FileLayout _chooseLayout({
  required double width,
  required Breakpoint breakpoint,
  required double textScale,
}) {
  final s = math.max(1.0, textScale);
  const gap = AppSpace.s16;
  final three =
      width - (AppSize.colunaEtapa + AppSize.colunaData) * s - 2 * gap;
  final two = width - AppSize.colunaData * s - gap;
  var level = switch (breakpoint) {
    Breakpoint.largo => 3,
    Breakpoint.medio => 2,
    Breakpoint.compacto => 1,
  };
  if (level == 3 && three < AppSize.textoMinimo) level = 2;
  if (level == 2 && two < AppSize.textoMinimo) level = 1;
  return switch (level) {
    3 => _FileLayout.three,
    2 => _FileLayout.two,
    _ => _FileLayout.stacked,
  };
}

class _ClientFilePageState extends State<ClientFilePage> {
  ClientFileController? _controller;
  Timer? _highlightTimer;

  ClientFileController get c => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    _controller = ClientFileController(
      services.requests,
      services.requestEmail,
      services.connectivity,
      services.requestsHandoff,
      clientId: widget.clientId,
    )..start();
    if (c.highlightIds.isNotEmpty) {
      // Esquece o realce depois de desvanecer.
      _highlightTimer = Timer(
        AppMotion.realce + AppMotion.lento + const Duration(milliseconds: 200),
        () => _controller?.clearHighlight(),
      );
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _toClients() => goTo(context, AppRoutes.mediator);

  void _newRequest() =>
      goTo(context, AppRoutes.mediatorClientNewRequest(widget.clientId));

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
        return PageFrame(
          tabLabel: session.session?.officeName ?? MediatorCopy.fallbackOffice,
          accountName: accountNameFor(session.session),
          onSignOut: session.signOut,
          backLabel: RequestCopy.backClients,
          onBack: _toClients,
          banner: OfflineBar(visible: !online, message: RequestCopy.offline),
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
    if (c.noAccess) return NoAccessBlock(onBack: _toClients);
    if (c.headerLoad == RequestsLoad.error) {
      return InlineNotice(
        kind: NoticeKind.erro,
        message: RequestCopy.fileError,
        actionLabel: RequestCopy.retry,
        onAction: online ? c.retry : null,
      );
    }
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final empty = c.listLoad == RequestsLoad.ready && c.requests.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, online, compact, showButton: !empty),
        ..._createdNotice(),
        const SizedBox(height: AppSpace.s48),
        _requestsSection(context, online, compact),
        const SizedBox(height: AppSpace.s48),
      ],
    );
  }

  // ---- Cabeçalho ------------------------------------------------------------

  Widget _header(
    BuildContext context,
    bool online,
    bool compact, {
    required bool showButton,
  }) {
    final h = c.header;
    final bp = AppBreakpoints.fromContext(context);
    final loading = c.headerLoad == RequestsLoad.loading || h == null;
    final identity = loading
        ? const SkeletonRows(count: 1)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                autofocus: !compact,
                child: Semantics(
                  header: true,
                  child: Text(h.fullName ?? '', style: AppType.tituloPara(bp)),
                ),
              ),
              if (h.email != null) ...[
                const SizedBox(height: AppSpace.s4),
                Text(
                  h.email!,
                  style: AppType.corpoPequeno.copyWith(
                    color: AppColors.tintaMedia,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s12),
              Wrap(
                spacing: AppSpace.s12,
                runSpacing: AppSpace.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusStamp(
                    status: StampStatus.ativo,
                    semanticsDetail: h.since == null
                        ? null
                        : 'desde ${MediatorCopy.spokenDate(h.since!)}',
                  ),
                  if (h.since != null)
                    Text(
                      'Desde ${AppDates.dateTime(h.since!)}',
                      style: AppType.registo,
                    ),
                ],
              ),
            ],
          );
    final button = showButton
        ? PrimaryButton(
            label: RequestCopy.newRequest,
            principal: compact,
            expand: compact,
            onPressed: c.canCreate ? _newRequest : null,
            disabledReason: online ? null : RequestCopy.needsConnectionToCreate,
          )
        : null;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          identity,
          if (button != null) ...[const SizedBox(height: AppSpace.s24), button],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: identity),
        if (button != null) ...[const SizedBox(width: AppSpace.s16), button],
      ],
    );
  }

  // ---- Resultado da criação -------------------------------------------------

  List<Widget> _createdNotice() {
    final b = c.created;
    final email = c.email;
    if (b == null || email == null) return const [];
    final Widget notice;
    switch (email.status) {
      case BatchEmailStatus.sent:
        notice = InlineNotice(
          key: const ValueKey('criado-enviado'),
          icon: Icons.check_circle_outline,
          message: RequestCopy.createdTitle(b.count),
          detail: RequestCopy.createdSent(b.typeNames, email.recipientEmail),
        );
      case BatchEmailStatus.clientNotAvailable:
        notice = const InlineNotice(
          key: ValueKey('criado-sem-acesso'),
          kind: NoticeKind.erro,
          message: RequestCopy.clientLost,
        );
      case BatchEmailStatus.notSent:
      case BatchEmailStatus.resent:
        notice = _emailNotice(b.count, email);
    }
    return [const SizedBox(height: AppSpace.s24), notice];
  }

  Widget _emailNotice(int count, BatchEmailController email) {
    final resent = email.status == BatchEmailStatus.resent;
    final until = email.lockUntil;
    final err = email.lastError;
    return Column(
      key: ValueKey(resent ? 'criado-reenviado' : 'criado-por-enviar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resent)
          InlineNotice(
            icon: Icons.check_circle_outline,
            message: RequestCopy.resentEmail(email.recipientEmail),
          )
        else
          InlineNotice(
            kind: NoticeKind.aviso,
            message: RequestCopy.createdNotSentTitle(count),
            detail: RequestCopy.createdNotSentDetail,
          ),
        if (err != null) ...[
          const SizedBox(height: AppSpace.s12),
          InlineNotice(
            kind: NoticeKind.erro,
            message: err == RequestFailureKind.network
                ? RequestCopy.resendNetwork
                : RequestCopy.resendGeneric,
          ),
        ],
        const SizedBox(height: AppSpace.s12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SecondaryButton(
            label: RequestCopy.resendEmail,
            loadingLabel: RequestCopy.resendingEmail,
            loading: email.sending,
            onPressed: email.canResend ? email.resend : null,
            disabledReason: !email.canResend && !email.sending
                ? (until != null
                      ? RequestCopy.canResendAt(MediatorCopy.hhmm(until))
                      : MediatorCopy.needsConnection)
                : null,
          ),
        ),
      ],
    );
  }

  // ---- Pedidos --------------------------------------------------------------

  Widget _requestsSection(BuildContext context, bool online, bool compact) {
    final heading = SectionTitle(
      RequestCopy.requestsOfOffice,
      trailing: c.listLoad == RequestsLoad.ready
          ? RequestCopy.inProgress(c.openCount)
          : null,
    );
    final Widget body = switch (c.listLoad) {
      RequestsLoad.loading => const SkeletonRows(count: 3),
      RequestsLoad.error => InlineNotice(
        kind: NoticeKind.erro,
        message: RequestCopy.fileError,
        actionLabel: RequestCopy.retry,
        onAction: online ? c.retry : null,
      ),
      RequestsLoad.ready =>
        c.requests.isEmpty ? _empty(compact, online) : _list(context, online),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        const SizedBox(height: AppSpace.s16),
        body,
      ],
    );
  }

  Widget _empty(bool compact, bool online) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppRule(),
        const SizedBox(height: AppSpace.s24),
        Text(RequestCopy.noRequestsTitle, style: AppType.corpoForte),
        const SizedBox(height: AppSpace.s8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.larguraLeitura),
          child: Text(
            RequestCopy.noRequestsBody,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrimaryButton(
            label: RequestCopy.newRequest,
            principal: compact,
            expand: compact,
            onPressed: c.canCreate ? _newRequest : null,
            disabledReason: online ? null : RequestCopy.needsConnectionToCreate,
          ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context, bool online) {
    final bp = AppBreakpoints.fromContext(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final layout = _chooseLayout(
              width: box.maxWidth,
              breakpoint: bp,
              textScale: scale,
            );
            final s = math.max(1.0, scale);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (layout != _FileLayout.stacked) _TableHeader(layout, s),
                SelectionArea(
                  child: RuledList(
                    children: [
                      for (final r in c.requests)
                        _row(r, layout, s, key: ValueKey(r.id)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (c.loadMoreFailed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            kind: NoticeKind.erro,
            message: RequestCopy.loadMoreError,
            actionLabel: RequestCopy.retry,
            onAction: online ? c.loadMore : null,
          ),
        ],
        if (c.hasMore) ...[
          const SizedBox(height: AppSpace.s24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SecondaryButton(
              label: RequestCopy.showMore,
              loadingLabel: RequestCopy.loadingMore,
              loading: c.loadingMore,
              onPressed: online ? c.loadMore : null,
              disabledReason: online ? null : MediatorCopy.needsConnection,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(
    OfficeRequest r,
    _FileLayout layout,
    double scale, {
    required Key key,
  }) {
    final highlighted = c.highlightIds.contains(r.id);
    final type = Wrap(
      spacing: AppSpace.s12,
      runSpacing: AppSpace.s4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        NameLink(
          label: r.typeName,
          semanticsLabel: 'Abrir o pedido de ${r.typeName}',
          onPressed: () =>
              goTo(context, AppRoutes.mediatorRequest(widget.clientId, r.id)),
        ),
        if (r.allowPolicyConditions)
          const TagLabel(RequestCopy.policyConditions),
      ],
    );
    final track = StageTrack(
      stage: r.stage.number,
      label: RequestCopy.stageShort(r.stage),
    );
    final created = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppDates.dateTime(r.createdAt), style: AppType.registo),
        Text(
          RequestCopy.author(r.origin, r.authorName),
          style: AppType.corpoPequeno,
        ),
      ],
    );
    const gap = SizedBox(width: AppSpace.s16);
    final Widget body = switch (layout) {
      _FileLayout.three => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: type),
          gap,
          SizedBox(width: AppSize.colunaEtapa * scale, child: track),
          gap,
          SizedBox(width: AppSize.colunaData * scale, child: created),
        ],
      ),
      _FileLayout.two => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [type, track],
            ),
          ),
          gap,
          SizedBox(width: AppSize.colunaData * scale, child: created),
        ],
      ),
      _FileLayout.stacked => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          type,
          const SizedBox(height: AppSpace.s4),
          track,
          const SizedBox(height: AppSpace.s8),
          created,
        ],
      ),
    };
    return Entering(
      key: key,
      enabled: highlighted,
      child: RuledRow(
        highlight: highlighted,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        child: body,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.layout, this.scale);

  final _FileLayout layout;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final style = AppType.rotulo.copyWith(color: AppColors.tintaMedia);
    const gap = SizedBox(width: AppSpace.s16);
    Widget col(String t, double w) => SizedBox(
      width: w,
      child: Text(t, style: style),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Row(
        children: [
          Expanded(child: Text(RequestCopy.colType, style: style)),
          gap,
          if (layout == _FileLayout.three) ...[
            col(RequestCopy.colStage, AppSize.colunaEtapa * scale),
            gap,
          ],
          col(RequestCopy.colCreated, AppSize.colunaData * scale),
        ],
      ),
    );
  }
}
