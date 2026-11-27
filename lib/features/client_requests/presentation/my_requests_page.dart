import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../consent/application/consent_scope.dart';
import '../../consent/domain/consent_models.dart';
import '../../consent/presentation/client_home_page.dart';
import '../../consent/presentation/consent_copy.dart';
import '../../notifications/presentation/client_frame.dart';
import '../../requests/application/my_requests_controller.dart';
import '../../requests/application/requests_load.dart';
import '../../requests/domain/request_models.dart';
import 'client_requests_copy.dart';

/// Ecrã 4 (03-design.md): "Os meus pedidos", o ecrã inicial do cliente.
///
/// De cima para baixo: o bloco "À espera da sua resposta" da 001 (se houver
/// pedidos de acesso por responder), o título e o resumo, o aviso interino,
/// os pedidos "Em curso" (4 etapas) e "Com o acesso retirado", e a passagem
/// para "Com quem partilho". Só leitura.
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  MyRequestsController? _controller;
  List<ConsentGrant>? _grants;
  String? _notice;
  int _noticeKey = 0;
  bool _current = false;

  /// As rotas filhas (pedido de acesso) deixam este ecrã por baixo: cada vez
  /// que volta a ser o visível, lê tudo de novo.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (current && !_current) {
      _current = true;
      _activate();
    } else if (!current) {
      _current = false;
    }
  }

  void _activate() {
    final services = AppScope.of(context);
    final notice = services.session.takeNotice();
    if (notice != null) {
      _notice = notice;
      _noticeKey++;
    }
    _controller ??= MyRequestsController(
      services.requests,
      services.connectivity,
    );
    _controller!.start();
    _loadGrants();
  }

  /// Pedidos de acesso pendentes e nº de escritórios com acesso. Se falhar,
  /// o ecrã passa sem o bloco e sem a frase (nunca inventa).
  Future<void> _loadGrants() async {
    final repo = ConsentScope.of(context);
    final connectivity = AppScope.of(context).connectivity;
    try {
      final grants = await repo.myConsents();
      connectivity.reportReachable();
      if (mounted) setState(() => _grants = grants);
    } on ConsentFailure catch (f) {
      if (f.kind == ConsentFailureKind.network) {
        connectivity.reportNetworkFailure();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _retry() {
    _controller?.start();
    _loadGrants();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final connectivity = AppScope.of(context).connectivity;
    final bp = AppBreakpoints.fromContext(context);
    final grants = _grants;
    final pending = [
      for (final g in grants ?? const <ConsentGrant>[])
        if (g.status == GrantStatus.pendente) g,
    ];
    final activeGrants = grants?.where((g) => g.status == GrantStatus.ativa);

    return ClientFrame(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: ListenableBuilder(
          listenable: Listenable.merge([?controller, connectivity]),
          builder: (context, _) {
            final online = connectivity.online;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_notice != null) ...[
                  InlineNotice(
                    key: ValueKey(_noticeKey),
                    message: _notice!,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: AppSpace.s24),
                ],
                if (pending.isNotEmpty) ...[
                  PendingConsentBlock(
                    grants: pending,
                    online: online,
                    onRespond: (g) => context.go(AppRoutes.consentFor(g.id)),
                  ),
                  const SizedBox(height: AppSpace.s48),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    ClientRequestsCopy.title,
                    style: AppType.tituloPara(bp),
                  ),
                ),
                if (controller != null) _body(context, controller),
                const SizedBox(height: AppSpace.s48),
                const AppRule(),
                const SizedBox(height: AppSpace.s32),
                _SharingSection(activeCount: activeGrants?.length),
                const SizedBox(height: AppSpace.s48),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MyRequestsController c) {
    switch (c.load) {
      case RequestsLoad.loading:
        return const Padding(
          padding: EdgeInsets.only(top: AppSpace.s24),
          child: SkeletonRows(count: 3),
        );
      case RequestsLoad.error:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpace.s24),
          child: InlineNotice(
            kind: NoticeKind.erro,
            message: ClientRequestsCopy.loadFailed,
            actionLabel: ClientRequestsCopy.retry,
            onAction: _retry,
          ),
        );
      case RequestsLoad.ready:
        break;
    }
    if (c.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ClientRequestsCopy.emptyTitle, style: AppType.corpoForte),
            const SizedBox(height: AppSpace.s8),
            Text(
              ClientRequestsCopy.emptyHelp,
              style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
            ),
          ],
        ),
      );
    }

    final active = c.active;
    final withdrawn = c.withdrawn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpace.s8),
        Text(
          ClientRequestsCopy.openSummary(c.openCount),
          style: AppType.corpoForte,
        ),
        const SizedBox(height: AppSpace.s24),
        const InlineNotice(message: ClientRequestsCopy.interimNotice),
        if (active.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s32),
          _Group(title: ClientRequestsCopy.groupOpen, requests: active),
        ],
        if (withdrawn.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s32),
          _Group(
            title: ClientRequestsCopy.groupWithdrawn,
            help: ClientRequestsCopy.withdrawnHelp,
            requests: withdrawn,
          ),
        ],
        if (c.loadMoreFailed) ...[
          const SizedBox(height: AppSpace.s16),
          InlineNotice(
            kind: NoticeKind.erro,
            message: ClientRequestsCopy.moreFailed,
            actionLabel: ClientRequestsCopy.retry,
            onAction: c.loadMore,
          ),
        ] else if (c.hasMore) ...[
          const SizedBox(height: AppSpace.s16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SecondaryButton(
              label: ClientRequestsCopy.showMore,
              loading: c.loadingMore,
              loadingLabel: ClientRequestsCopy.loadingMore,
              onPressed: c.loadMore,
            ),
          ),
        ],
      ],
    );
  }
}

/// Grupo de pedidos: cabeçalho `rotulo`, apoio opcional e linhas com régua.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.requests, this.help});

  final String title;
  final String? help;
  final List<MyRequest> requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
          ),
        ),
        if (help != null) ...[
          const SizedBox(height: AppSpace.s8),
          Text(help!, style: AppType.corpo),
        ],
        const SizedBox(height: AppSpace.s8),
        RuledList(
          children: [
            for (final r in requests)
              _RequestRow(key: ValueKey(r.id), request: r),
          ],
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({super.key, required this.request});

  final MyRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(r.typeName, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s4),
        Tooltip(
          message: r.officeName,
          excludeFromSemantics: true,
          child: Text(
            ClientRequestsCopy.fromOffice(r.officeName),
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            semanticsLabel: ClientRequestsCopy.fromOffice(r.officeName),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        if (r.accessWithdrawn)
          Wrap(
            spacing: AppSpace.s12,
            runSpacing: AppSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusStamp(
                status: StampStatus.acessoRetirado,
                semanticsDetail: r.accessWithdrawnAt == null
                    ? null
                    : 'a ${AppDates.dateTime(r.accessWithdrawnAt!)}',
              ),
              Text(
                ClientRequestsCopy.createdOn(r.createdAt),
                style: AppType.registo.copyWith(color: AppColors.tintaMedia),
              ),
            ],
          )
        else
          Wrap(
            spacing: AppSpace.s12,
            runSpacing: AppSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StageTrack(
                stage: r.stage.number,
                label: ClientRequestsCopy.stageLine(r.stage),
                semanticsLabel: ClientRequestsCopy.stageLine(r.stage),
              ),
              Text(
                AppDates.dateTime(r.createdAt),
                style: AppType.registo.copyWith(color: AppColors.tintaMedia),
              ),
            ],
          ),
        const SizedBox(height: AppSpace.s8),
        Text(
          ClientRequestsCopy.requested(r.documentCount, r.dataCount),
          style: AppType.corpoPequeno,
        ),
      ],
    );

    Widget button(bool expand) => SecondaryButton(
      label: ClientRequestsCopy.viewRequest,
      expand: expand,
      onPressed: () => context.go(AppRoutes.clientRequest(r.id)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
      child: LayoutBuilder(
        builder: (context, c) {
          final sideBySide =
              !compact &&
              c.maxWidth - AppSize.colunaAcao - AppSpace.s24 >=
                  AppSize.textoMinimo;
          if (!sideBySide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                text,
                const SizedBox(height: AppSpace.s16),
                button(true),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: text),
              const SizedBox(width: AppSpace.s24),
              button(false),
            ],
          );
        },
      ),
    );
  }
}

/// "Com quem partilho": passagem para o ecrã da 001, com a frase-resumo
/// (só quando o servidor já a deu).
class _SharingSection extends StatelessWidget {
  const _SharingSection({required this.activeCount});

  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            ClientRequestsCopy.sharingTitle,
            style: AppType.subtitulo,
          ),
        ),
        if (activeCount != null) ...[
          const SizedBox(height: AppSpace.s8),
          Text(ConsentCopy.summary(activeCount!), style: AppType.corpo),
        ],
        const SizedBox(height: AppSpace.s16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SecondaryButton(
            label: ClientRequestsCopy.viewSharing,
            onPressed: () => context.go(AppRoutes.clientSharing),
          ),
        ),
      ],
    );
  }
}
