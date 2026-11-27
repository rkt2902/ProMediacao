import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../notifications/presentation/client_frame.dart';
import '../../requests/application/request_detail_controller.dart';
import '../../requests/domain/request_models.dart';
import 'client_requests_copy.dart';

/// Ecrã 5 (03-design.md): o pedido, só leitura. Tipo e escritório, o que lhe
/// pedem (com a mensagem antes, como contexto) e as 4 etapas. Com o acesso
/// retirado mostra o carimbo e a explicação, sem aviso interino nem ações.
class ClientRequestPage extends StatefulWidget {
  const ClientRequestPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<ClientRequestPage> createState() => _ClientRequestPageState();
}

class _ClientRequestPageState extends State<ClientRequestPage> {
  RequestDetailController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    _controller = RequestDetailController(
      services.requests,
      services.connectivity,
      requestId: widget.requestId,
    );
    final controller = _controller!;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.start());
  }

  @override
  void didUpdateWidget(ClientRequestPage old) {
    super.didUpdateWidget(old);
    if (old.requestId != widget.requestId) {
      final services = AppScope.of(context);
      _controller?.dispose();
      _controller = RequestDetailController(
        services.requests,
        services.connectivity,
        requestId: widget.requestId,
      )..start();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ClientFrame(
      backLabel: ClientRequestsCopy.backToRequests,
      backTo: AppRoutes.client,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => switch (controller.load) {
            RequestDetailLoad.loading => const SkeletonRows(count: 4),
            RequestDetailLoad.error => InlineNotice(
              kind: NoticeKind.erro,
              message: ClientRequestsCopy.detailFailed,
              actionLabel: ClientRequestsCopy.retry,
              onAction: controller.start,
            ),
            RequestDetailLoad.notFound => const _NotFound(),
            RequestDetailLoad.ready => _Detail(detail: controller.detail!),
          },
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            ClientRequestsCopy.notFoundTitle,
            style: AppType.tituloPara(bp),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(ClientRequestsCopy.notFoundHelp, style: AppType.corpo),
        const SizedBox(height: AppSpace.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SecondaryButton(
            label: ClientRequestsCopy.seeMyRequests,
            principal: true,
            onPressed: () => context.go(AppRoutes.client),
          ),
        ),
        const SizedBox(height: AppSpace.s48),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final bp = AppBreakpoints.fromContext(context);
    final muted = AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia);
    final dates = d.stageDates;
    final author = d.authorName;

    final notes = [
      if (d.allowPolicyConditions) ClientRequestsCopy.policyNote,
      ?d.typeNote,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(d.typeName, style: AppType.tituloPara(bp)),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          ClientRequestsCopy.fromOfficeTitle(d.officeName),
          style: AppType.corpoForte,
        ),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (author != null)
              Text(ClientRequestsCopy.sentBy(author), style: muted),
            Text(
              AppDates.dateTime(d.createdAt),
              style: AppType.registo.copyWith(color: AppColors.tintaMedia),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        if (d.accessWithdrawn) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: AppSpace.s12,
              runSpacing: AppSpace.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const StatusStamp(status: StampStatus.acessoRetirado),
                if (d.accessWithdrawnAt != null)
                  Text(
                    ClientRequestsCopy.withdrawnOn(d.accessWithdrawnAt!),
                    style: AppType.registo.copyWith(
                      color: AppColors.tintaMedia,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            ClientRequestsCopy.withdrawnExplain(d.officeName),
            style: AppType.corpo,
          ),
        ] else ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StageTrack(
              stage: d.stage.number,
              label: ClientRequestsCopy.stageLine(d.stage),
              semanticsLabel: ClientRequestsCopy.stageLine(d.stage),
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          const InlineNotice(message: ClientRequestsCopy.interimNotice),
        ],
        if (d.message != null) ...[
          const SizedBox(height: AppSpace.s32),
          Semantics(
            header: true,
            child: Text(
              ClientRequestsCopy.messageFrom(author),
              style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(d.message!, style: AppType.corpo),
        ],
        const SizedBox(height: AppSpace.s48),
        Wrap(
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Semantics(
              header: true,
              child: Text(
                ClientRequestsCopy.whatIsAsked,
                style: AppType.subtitulo,
              ),
            ),
            Text(
              ClientRequestsCopy.counts(d.documentCount, d.dataCount),
              style: AppType.registo.copyWith(color: AppColors.tintaMedia),
            ),
          ],
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
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s48),
        Semantics(
          header: true,
          child: Text(ClientRequestsCopy.stages, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s16),
        StageStrip(
          current: d.stage.number,
          steps: [
            for (var i = 0; i < kStageCount; i++)
              StageStripStep(
                name: ClientRequestsCopy.stageNames[i],
                date: dates[i] == null ? null : AppDates.date(dates[i]!),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        Text(ClientRequestsCopy.footer, style: muted),
        const SizedBox(height: AppSpace.s48),
      ],
    );
  }
}
