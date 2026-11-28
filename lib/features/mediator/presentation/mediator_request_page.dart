import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../../requests/application/request_detail_controller.dart';
import '../../requests/domain/request_models.dart';
import 'mediator_copy.dart';
import 'request_copy.dart';
import 'request_parts.dart';

/// Pedido aberto, só leitura (03-design.md, ecrã 3b). Página (não diálogo)
/// porque na 004 é aqui que o mediador revê o que o cliente enviou.
/// [clientId] é o do regresso à ficha (o nome do cliente vem do pedido).
class MediatorRequestPage extends StatefulWidget {
  const MediatorRequestPage({
    super.key,
    required this.clientId,
    required this.requestId,
  });

  final String clientId;
  final String requestId;

  @override
  State<MediatorRequestPage> createState() => _MediatorRequestPageState();
}

class _MediatorRequestPageState extends State<MediatorRequestPage> {
  RequestDetailController? _controller;

  RequestDetailController get c => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    _controller = RequestDetailController(
      services.requests,
      services.connectivity,
      requestId: widget.requestId,
    )..start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toFile() => goTo(context, AppRoutes.mediatorClient(widget.clientId));
  void _toClients() => goTo(context, AppRoutes.mediator);

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
        final detail = c.detail;
        return PageFrame(
          tabLabel: session.session?.officeName ?? MediatorCopy.fallbackOffice,
          accountName: accountNameFor(session.session),
          onSignOut: session.signOut,
          maxWidth: AppSize.larguraLeitura,
          backLabel: detail?.clientName.isNotEmpty == true
              ? detail!.clientName
              : RequestCopy.backFallback,
          onBack: _toFile,
          banner: OfflineBar(visible: !online),
          colophon: const SessionColophon(),
          child: Padding(
            padding: const EdgeInsets.only(top: PageFrame.contentTop),
            child: switch (c.load) {
              RequestDetailLoad.loading => const _Skeleton(),
              RequestDetailLoad.error => InlineNotice(
                kind: NoticeKind.erro,
                message: RequestCopy.requestError,
                actionLabel: RequestCopy.retry,
                onAction: online ? c.start : null,
              ),
              RequestDetailLoad.notFound => NoAccessBlock(onBack: _toClients),
              RequestDetailLoad.ready => _Reading(detail: detail!),
            },
          ),
        );
      },
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final muted = AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia);
    final d = detail;
    final notes = [
      if (d.allowPolicyConditions) RequestCopy.policyNoteReading,
      ?d.typeNote,
    ];
    final dates = d.stageDates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          autofocus: bp != Breakpoint.compacto,
          child: Semantics(
            header: true,
            child: Text(d.typeName, style: AppType.tituloPara(bp)),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(RequestCopy.forClient(d.clientName), style: AppType.corpoForte),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(RequestCopy.createdBy(d.authorName), style: muted),
            Text(AppDates.dateTime(d.createdAt), style: AppType.registo),
            TagLabel(
              d.origin == RequestOrigin.mediador
                  ? RequestCopy.originMediator
                  : RequestCopy.originClient,
            ),
            if (d.allowPolicyConditions)
              const TagLabel(RequestCopy.policyConditions),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StageTrack(
            stage: d.stage.number,
            label:
                'Etapa ${d.stage.number} de 4: ${RequestCopy.stageLong(d.stage)}',
            semanticsLabel:
                'Etapa ${d.stage.number} de 4: ${RequestCopy.stageLong(d.stage)}',
          ),
        ),
        if (d.message != null) ...[
          const SizedBox(height: AppSpace.s32),
          Text(
            RequestCopy.messageFrom(d.authorName),
            style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
          ),
          const SizedBox(height: AppSpace.s8),
          SelectableText(d.message!, style: AppType.corpo),
        ],
        const SizedBox(height: AppSpace.s48),
        SectionTitle(
          RequestCopy.requestedList,
          trailing: RequestCopy.counts(d.documentCount, d.dataCount),
        ),
        const SizedBox(height: AppSpace.s16),
        RequestSheet(
          notes: notes,
          items: [
            for (final i in d.items)
              RequestItemRow(
                key: ValueKey(i.id),
                kind: i.kind == ItemKind.document
                    ? RequestItemKind.documento
                    : RequestItemKind.dado,
                text: i.label,
                free: i.source == ItemSource.free,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s48),
        SectionTitle(RequestCopy.stages),
        const SizedBox(height: AppSpace.s16),
        StageStrip(
          current: d.stage.number,
          steps: [
            for (var i = 0; i < kStageCount; i++)
              StageStripStep(
                name: RequestCopy.stageNames[i],
                date: dates[i] == null ? null : AppDates.date(dates[i]!),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        Text(RequestCopy.readOnly, style: muted),
        const SizedBox(height: AppSpace.s48),
      ],
    );
  }
}

/// Skeleton com a forma do pedido: título, faixa e itens.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SkeletonRows(count: 7)],
    );
  }
}
