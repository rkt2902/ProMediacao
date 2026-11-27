import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../application/consent_scope.dart';
import '../domain/consent_models.dart';
import 'consent_copy.dart';
import 'consent_widgets.dart';

enum _Answer { accept, decline }

/// Ecrã 3 (03-design.md): o cliente aceita ou recusa o pedido [grantId].
///
/// Quem pede, resumo em 3 linhas, texto completo da versão corrente e barra
/// fixa com "Recusar" e "Aceitar" com o mesmo peso. O resultado só aparece
/// depois de o servidor confirmar a mudança de estado; se a resposta falhar
/// ou o pedido já tiver mudado, volta a ler o estado real.
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key, required this.grantId});

  final String grantId;

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _loading = true;
  bool _loadFailed = false;
  ConsentGrant? _grant;
  ConsentText? _text;

  /// Concessão já respondida, tal como o servidor a devolveu.
  ConsentGrant? _result;
  _Answer? _sending;
  String? _error;
  final _resultFocus = FocusNode(debugLabel: 'resultado');
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _resultFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ConsentScope.of(context);
    final connectivity = AppScope.of(context).connectivity;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final grants = await repo.myConsents();
      final grant = _find(grants);
      if (!mounted) return;
      if (grant == null) {
        _leave(ConsentCopy.requestUnavailable);
        return;
      }
      if (grant.status != GrantStatus.pendente) {
        _leave(ConsentCopy.alreadyAnswered(_answeredAt(grant)));
        return;
      }
      // O cliente responde ao texto da versão corrente; é essa versão que
      // fica registada ao aceitar.
      final version = await repo.currentVersion();
      final text = await repo.text(version);
      connectivity.reportReachable();
      if (!mounted) return;
      setState(() {
        _grant = grant;
        _text = text;
        _loading = false;
      });
    } on ConsentFailure catch (f) {
      if (f.kind == ConsentFailureKind.network) {
        connectivity.reportNetworkFailure();
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  ConsentGrant? _find(List<ConsentGrant> grants) {
    for (final g in grants) {
      if (g.id == widget.grantId) return g;
    }
    return null;
  }

  static DateTime _answeredAt(ConsentGrant g) =>
      g.acceptedAt ?? g.declinedAt ?? g.statusAt;

  /// Volta a "Com quem partilho" com um aviso (pedido inexistente ou já
  /// respondido). Não regista nada.
  void _leave(String notice) {
    AppScope.of(context).session.setNotice(notice);
    context.go(AppRoutes.client);
  }

  void _goHome() {
    final result = _result;
    if (result != null) {
      ConsentHandoff.answered(result.id);
      AppScope.of(context).session.setNotice(
        result.status == GrantStatus.ativa
            ? ConsentCopy.acceptedResult(result.officeName)
            : ConsentCopy.declinedResult(result.officeName),
      );
    }
    context.go(AppRoutes.client);
  }

  Future<void> _respond(_Answer answer) async {
    final grant = _grant;
    final text = _text;
    if (_sending != null || grant == null || text == null) return;
    final repo = ConsentScope.of(context);
    final connectivity = AppScope.of(context).connectivity;
    setState(() {
      _sending = answer;
      _error = null;
    });
    try {
      final updated = answer == _Answer.accept
          ? await repo.accept(grant, version: text.version)
          : await repo.decline(grant);
      connectivity.reportReachable();
      if (mounted) _confirmed(updated);
    } on ConsentFailure catch (f) {
      switch (f.kind) {
        case ConsentFailureKind.network:
          connectivity.reportNetworkFailure();
          _fail(ConsentCopy.respondUnconfirmed);
        case ConsentFailureKind.stateChanged || ConsentFailureKind.notFound:
          await _resync();
        case ConsentFailureKind.unknown:
          _fail(ConsentCopy.respondFailed);
      }
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _sending = null;
      _error = message;
    });
  }

  /// O servidor recusou ou o pedido já mudou: mostra só o que o servidor
  /// diz agora (nunca o que se pediu).
  Future<void> _resync() async {
    final repo = ConsentScope.of(context);
    try {
      final current = _find(await repo.myConsents());
      if (!mounted) return;
      if (current == null) {
        _leave(ConsentCopy.requestUnavailable);
      } else if (current.status == GrantStatus.pendente) {
        _fail(ConsentCopy.respondFailed);
      } else if (current.status == GrantStatus.retirada) {
        _leave(ConsentCopy.alreadyAnswered(_answeredAt(current)));
      } else {
        _confirmed(current);
      }
    } on ConsentFailure catch (f) {
      _fail(
        f.kind == ConsentFailureKind.network
            ? ConsentCopy.respondUnconfirmed
            : ConsentCopy.respondFailed,
      );
    }
  }

  void _confirmed(ConsentGrant updated) {
    setState(() {
      _result = updated;
      _sending = null;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resultFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final connectivity = services.connectivity;
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        final online = connectivity.online;
        final showBar = _result == null && !_loadFailed;
        return PageFrame(
          tabLabel: ConsentCopy.tabRequest,
          maxWidth: AppSize.larguraLeitura,
          onSignOut: services.session.signOut,
          topAction: TextAction(
            label: ConsentCopy.backToHome,
            icon: Icons.arrow_back,
            onPressed: _goHome,
          ),
          banner: OfflineBar(visible: !online),
          colophon: const SessionColophon(),
          bottom: showBar ? _actionBar(context, online) : null,
          child: Padding(
            padding: const EdgeInsets.only(top: PageFrame.contentTop),
            child: AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.base),
              switchInCurve: AppMotion.entrar,
              layoutBuilder: (current, previous) => Stack(
                alignment: AlignmentDirectional.topStart,
                children: [...previous, ?current],
              ),
              child: _loading
                  ? const _ConsentSkeleton(key: ValueKey('skeleton'))
                  : (_loadFailed
                        ? KeyedSubtree(
                            key: const ValueKey('error'),
                            child: InlineNotice(
                              kind: NoticeKind.erro,
                              message: ConsentCopy.textFailed,
                              actionLabel: ConsentCopy.retry,
                              onAction: _load,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('content'),
                            child: _content(context),
                          )),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final grant = _grant!;
    final text = _text!;
    final result = _result;
    final lowHeight = AppBreakpoints.lowHeight(context);
    final mutedSmall = AppType.corpoPequeno.copyWith(
      color: AppColors.tintaMedia,
    );

    final title = Semantics(
      header: true,
      label: '${grant.officeName} ${ConsentCopy.requestsAccess}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(grant.officeName, style: AppType.tituloPara(bp)),
          Text(ConsentCopy.requestsAccess, style: AppType.corpoForte),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Foco inicial no título em médio/largo (anuncia quem pede).
        Focus(autofocus: bp != Breakpoint.compacto, child: title),
        if (grant.mediatorName != null) ...[
          const SizedBox(height: AppSpace.s8),
          Text(ConsentCopy.sentBy(grant.mediatorName!), style: mutedSmall),
        ],
        const SizedBox(height: AppSpace.s32),
        const RuledList(
          children: [
            _SummaryRow(icon: Icons.visibility, text: ConsentCopy.summarySees),
            _SummaryRow(
              icon: Icons.visibility_off,
              text: ConsentCopy.summaryOthers,
            ),
            _SummaryRow(icon: Icons.undo, text: ConsentCopy.summaryWithdraw),
          ],
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpace.s32),
          Focus(
            focusNode: _resultFocus,
            child: _ResultBlock(grant: result, onSeeHome: _goHome),
          ),
        ],
        const SizedBox(height: AppSpace.s48),
        Semantics(
          header: true,
          child: Text(ConsentCopy.fullText, style: AppType.rotulo),
        ),
        const SizedBox(height: AppSpace.s16),
        ConsentTextView(
          text: text,
          officeName: grant.officeName,
          // Altura baixa: a linha de apoio sai da barra e vem para aqui.
          beforeVersion: lowHeight && result == null
              ? Text(ConsentCopy.recorded, style: mutedSmall)
              : null,
        ),
      ],
    );
  }

  Widget _actionBar(BuildContext context, bool online) {
    final ready = !_loading && _grant != null && online;
    final lowHeight = AppBreakpoints.lowHeight(context);
    final helper = online ? ConsentCopy.recorded : ConsentCopy.offlineRespond;
    final helperStyle = AppType.corpoPequeno.copyWith(
      color: AppColors.tintaMedia,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) ...[
          InlineNotice(kind: NoticeKind.erro, message: _error!),
          const SizedBox(height: AppSpace.s16),
        ],
        // Em altura baixa a linha de apoio passa para o fim do texto; a
        // razão de estar desativado continua sempre escrita.
        if (!lowHeight || !online) ...[
          Text(helper, style: helperStyle),
          const SizedBox(height: AppSpace.s12),
        ],
        // Lado a lado, mesma largura, nunca empilhados; nenhum é o "por
        // defeito" (Enter só ativa o botão com foco).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SecondaryButton(
                label: ConsentCopy.decline,
                loadingLabel: ConsentCopy.registering,
                loading: _sending == _Answer.decline,
                principal: true,
                expand: true,
                onPressed: ready && _sending == null
                    ? () => _respond(_Answer.decline)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: PrimaryButton(
                label: ConsentCopy.accept,
                loadingLabel: ConsentCopy.registering,
                loading: _sending == _Answer.accept,
                principal: true,
                expand: true,
                onPressed: ready && _sending == null
                    ? () => _respond(_Answer.accept)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RuledRow(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: AppSize.icone, color: AppColors.tinta),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(child: Text(text, style: AppType.corpo)),
        ],
      ),
    );
  }
}

/// Bloco de resultado, só com dados confirmados pelo servidor.
class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.grant, required this.onSeeHome});

  final ConsentGrant grant;
  final VoidCallback onSeeHome;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final accepted = grant.status == GrantStatus.ativa;
    final at = grant.statusAt;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusStamp(
              status: accepted ? StampStatus.ativo : StampStatus.recusado,
              semanticsDetail: accepted
                  ? 'desde ${AppDates.dateTime(at)}'
                  : 'a ${AppDates.dateTime(at)}',
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            accepted ? ConsentCopy.activeSince(at) : ConsentCopy.declinedOn(at),
            style: AppType.registo.copyWith(color: AppColors.tintaTenue),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            accepted
                ? ConsentCopy.acceptedResult(grant.officeName)
                : ConsentCopy.declinedResult(grant.officeName),
            style: AppType.corpo,
          ),
          const SizedBox(height: AppSpace.s24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PrimaryButton(
              label: ConsentCopy.seeHome,
              principal: true,
              expand: compact,
              onPressed: onSeeHome,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton com a forma do consentimento: título em 2 linhas, remetente, 3
/// linhas de resumo e 6 de texto. A barra de ações já está no sítio,
/// desativada.
class _ConsentSkeleton extends StatelessWidget {
  const _ConsentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpace.s12);
    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBlock(widthFactor: 0.6, height: AppSpace.s32),
          gap,
          const SkeletonBlock(widthFactor: 0.5, height: AppSpace.s24),
          const SizedBox(height: AppSpace.s16),
          const SkeletonBlock(widthFactor: 0.4, height: AppSpace.s16),
          const SizedBox(height: AppSpace.s32),
          RuledList(
            children: [
              for (final f in const [0.9, 0.8, 0.7])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
                  child: SkeletonBlock(widthFactor: f, height: AppSpace.s24),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s48),
          const SkeletonBlock(widthFactor: 0.3, height: AppSpace.s16),
          const SizedBox(height: AppSpace.s24),
          for (final f in const [1.0, 0.9, 1.0, 0.8, 1.0, 0.6]) ...[
            SkeletonBlock(widthFactor: f, height: AppSpace.s24),
            gap,
          ],
        ],
      ),
    );
  }
}
