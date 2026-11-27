import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/client_account_section.dart';
import '../../auth/presentation/session_colophon.dart';
import '../application/consent_scope.dart';
import '../domain/consent_models.dart';
import '../domain/consent_repository.dart';
import 'consent_copy.dart';
import 'consent_widgets.dart';

/// Ecrã 4 (03-design.md): "Com quem partilho", o ecrã inicial do cliente.
///
/// Pedidos pendentes no topo (respondem-se dentro da app, sem email),
/// escritórios com acesso (retirar, ler o texto aceite), sem acesso, e no fim
/// "A sua conta". Só mostra estados que o servidor devolveu; retirar só
/// muda a linha depois de o servidor confirmar.
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  List<ConsentGrant>? _grants;
  bool _loading = true;
  bool _loadFailed = false;
  String? _notice;
  int _noticeKey = 0;
  String? _highlightId;
  final _noticeFocus = FocusNode(debugLabel: 'aviso');
  final _pendingFocus = FocusNode(debugLabel: 'pedidos');

  /// O pedido (`/cliente/pedido/:id`) é uma rota filha: este ecrã fica por
  /// baixo dele e é reutilizado ao voltar. Cada vez que volta a ser o ecrã
  /// visível, lê o aviso, a concessão respondida e a lista de novo (nunca
  /// mostra estado antigo); enquanto está tapado, não pede nada.
  bool _current = false;

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
    final notice = AppScope.of(context).session.takeNotice();
    if (notice != null) {
      _notice = notice;
      _noticeKey++;
    }
    _highlightId = ConsentHandoff.take() ?? _highlightId;
    _load();
  }

  @override
  void dispose() {
    _noticeFocus.dispose();
    _pendingFocus.dispose();
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
      connectivity.reportReachable();
      if (!mounted) return;
      setState(() {
        _grants = grants;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Foco: o aviso de topo, senão o bloco pendente (anunciado).
        if (_notice != null) {
          _noticeFocus.requestFocus();
        } else if (grants.any((g) => g.status == GrantStatus.pendente)) {
          _pendingFocus.requestFocus();
        }
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

  void _replace(ConsentGrant updated) {
    final grants = _grants;
    if (grants == null) return;
    setState(() {
      _grants = [for (final g in grants) g.id == updated.id ? updated : g];
    });
  }

  Future<void> _confirmWithdraw(ConsentGrant grant) async {
    await showConfirmSheet<void>(
      context,
      builder: (sheetContext) =>
          _WithdrawSheet(grant: grant, onConfirm: () => _withdraw(grant)),
    );
  }

  /// Chamado pela folha. Atualiza o ecrã só com a resposta do servidor, mesmo
  /// que a folha já tenha sido fechada. Devolve a mensagem de erro (ou nula
  /// se confirmou).
  Future<String?> _withdraw(ConsentGrant grant) async {
    final repo = ConsentScope.of(context);
    final connectivity = AppScope.of(context).connectivity;
    try {
      final updated = await repo.withdraw(grant);
      connectivity.reportReachable();
      if (mounted) _withdrawn(updated);
      return null;
    } on ConsentFailure catch (f) {
      switch (f.kind) {
        case ConsentFailureKind.network:
          connectivity.reportNetworkFailure();
          return ConsentCopy.withdrawUnconfirmed;
        case ConsentFailureKind.stateChanged || ConsentFailureKind.notFound:
          // Já não está ativa (ou o servidor recusou): ler o estado real.
          final current = await _reread(grant.id);
          if (current != null && current.status == GrantStatus.retirada) {
            if (mounted) _withdrawn(current);
            return null;
          }
          if (current == null && mounted) await _load();
          return ConsentCopy.withdrawFailed;
        case ConsentFailureKind.unknown:
          return ConsentCopy.withdrawFailed;
      }
    }
  }

  Future<ConsentGrant?> _reread(String id) async {
    try {
      final grants = await ConsentScope.of(context).myConsents();
      for (final g in grants) {
        if (g.id == id) {
          _replace(g);
          return g;
        }
      }
    } on ConsentFailure {
      // fica a mensagem de erro; nada muda no ecrã
    }
    return null;
  }

  void _withdrawn(ConsentGrant updated) {
    _replace(updated);
    setState(() {
      _highlightId = updated.id;
      _notice = ConsentCopy.withdrawn(updated.officeName);
      _noticeKey++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _noticeFocus.requestFocus();
    });
  }

  Future<void> _readAccepted(ConsentGrant grant) async {
    await showConfirmSheet<void>(
      context,
      readOnly: true,
      builder: (_) => _AcceptedTextSheet(
        grant: grant,
        repository: ConsentScope.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final connectivity = services.connectivity;
    final bp = AppBreakpoints.fromContext(context);
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        final online = connectivity.online;
        return PageFrame(
          tabLabel: ConsentCopy.tabMyData,
          maxWidth: AppSize.larguraLeitura,
          onSignOut: services.session.signOut,
          banner: OfflineBar(visible: !online),
          colophon: const SessionColophon(),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpace.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    ConsentCopy.homeTitle,
                    style: AppType.tituloPara(bp),
                  ),
                ),
                if (_notice != null) ...[
                  const SizedBox(height: AppSpace.s24),
                  Focus(
                    focusNode: _noticeFocus,
                    child: InlineNotice(
                      key: ValueKey(_noticeKey),
                      message: _notice!,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
                AnimatedSwitcher(
                  duration: AppMotion.resolve(context, AppMotion.base),
                  switchInCurve: AppMotion.entrar,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: AlignmentDirectional.topStart,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_loading ? 'a' : (_loadFailed ? 'e' : 'd')),
                    child: _body(context, online),
                  ),
                ),
                const SizedBox(height: AppSpace.s48),
                const ClientAccountSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, bool online) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpace.s24),
        child: SkeletonRows(count: 3),
      );
    }
    final grants = _grants;
    if (_loadFailed || grants == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.s24),
        child: InlineNotice(
          kind: NoticeKind.erro,
          message: ConsentCopy.loadFailed,
          actionLabel: ConsentCopy.retry,
          onAction: _load,
        ),
      );
    }
    if (grants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ConsentCopy.emptyTitle, style: AppType.corpoForte),
            const SizedBox(height: AppSpace.s8),
            Text(
              ConsentCopy.emptyHelp,
              style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
            ),
          ],
        ),
      );
    }

    final pending = [
      for (final g in grants)
        if (g.status == GrantStatus.pendente) g,
    ];
    final active = [
      for (final g in grants)
        if (g.status == GrantStatus.ativa) g,
    ];
    final inactive = [
      for (final g in grants)
        if (g.status == GrantStatus.recusada ||
            g.status == GrantStatus.retirada)
          g,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pending.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s24),
          Focus(
            focusNode: _pendingFocus,
            child: _PendingBlock(
              grants: pending,
              online: online,
              onRespond: (g) =>
                  context.go('${AppRoutes.client}/pedido/${g.id}'),
            ),
          ),
        ],
        SizedBox(height: pending.isNotEmpty ? AppSpace.s48 : AppSpace.s24),
        Text(ConsentCopy.summary(active.length), style: AppType.corpoForte),
        if (active.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s32),
          _Group(
            title: ConsentCopy.withAccess,
            children: [
              for (final g in active)
                _GrantRow(
                  key: ValueKey(g.id),
                  grant: g,
                  highlight: g.id == _highlightId,
                  online: online,
                  onWithdraw: () => _confirmWithdraw(g),
                  onReadText: () => _readAccepted(g),
                ),
            ],
          ),
        ],
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s32),
          _Group(
            title: ConsentCopy.withoutAccess,
            children: [
              for (final g in inactive)
                _GrantRow(
                  key: ValueKey(g.id),
                  grant: g,
                  highlight: g.id == _highlightId,
                  online: online,
                ),
            ],
          ),
        ],
        if (active.isNotEmpty || inactive.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s48),
          Text(
            ConsentCopy.footer,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ],
    );
  }
}

/// Bloco "À espera da sua resposta": a única superfície de cor do ecrã.
class _PendingBlock extends StatelessWidget {
  const _PendingBlock({
    required this.grants,
    required this.online,
    required this.onRespond,
  });

  final List<ConsentGrant> grants;
  final bool online;
  final void Function(ConsentGrant) onRespond;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return Semantics(
      container: true,
      liveRegion: true,
      label: ConsentCopy.pendingAnnounce(grants.length),
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpace.s16 : AppSpace.s24),
        decoration: const BoxDecoration(
          color: AppColors.realce,
          borderRadius: AppRadius.superficieBorda,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(ConsentCopy.pendingTitle, style: AppType.subtitulo),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(ConsentCopy.pendingHelp(grants.length), style: AppType.corpo),
            const SizedBox(height: AppSpace.s16),
            RuledList(
              bottomRule: false,
              children: [
                for (var i = 0; i < grants.length; i++)
                  RuledRow(
                    padding: EdgeInsets.only(
                      top: AppSpace.s24,
                      bottom: i < grants.length - 1 ? AppSpace.s24 : 0,
                    ),
                    child: _PendingRow(
                      grant: grants[i],
                      online: online,
                      onRespond: () => onRespond(grants[i]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.grant,
    required this.online,
    required this.onRespond,
  });

  final ConsentGrant grant;
  final bool online;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OfficeName(name: grant.officeName, style: AppType.corpoForte),
        if (grant.mediatorName != null) ...[
          const SizedBox(height: AppSpace.s4),
          Text(
            ConsentCopy.sentBy(grant.mediatorName!),
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
        const SizedBox(height: AppSpace.s8),
        StampWithDate(
          stamp: StatusStamp(
            status: StampStatus.pendente,
            semanticsDetail: 'desde ${AppDates.dateTime(grant.createdAt)}',
          ),
          date: ConsentCopy.requestedOn(grant.createdAt),
        ),
      ],
    );
    return _SplitRow(
      text: text,
      actions: (expand) => PrimaryButton(
        label: ConsentCopy.respond,
        principal: true,
        expand: expand,
        onPressed: online ? onRespond : null,
        disabledReason: online ? null : ConsentCopy.offlineShort,
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
        const SizedBox(height: AppSpace.s8),
        RuledList(children: children),
      ],
    );
  }
}

/// Linha de um escritório com acesso ou sem acesso.
class _GrantRow extends StatelessWidget {
  const _GrantRow({
    super.key,
    required this.grant,
    required this.highlight,
    required this.online,
    this.onWithdraw,
    this.onReadText,
  });

  final ConsentGrant grant;
  final bool highlight;
  final bool online;
  final VoidCallback? onWithdraw;
  final VoidCallback? onReadText;

  @override
  Widget build(BuildContext context) {
    final at = grant.statusAt;
    final (
      StampStatus stamp,
      String date,
      String spoken,
    ) = switch (grant.status) {
      GrantStatus.ativa => (
        StampStatus.ativo,
        ConsentCopy.since(at),
        'desde ${AppDates.dateTime(at)}',
      ),
      GrantStatus.recusada => (
        StampStatus.recusado,
        ConsentCopy.declinedOn(at),
        'a ${AppDates.dateTime(at)}',
      ),
      GrantStatus.retirada => (
        StampStatus.retirado,
        ConsentCopy.withdrawnOn(at),
        'a ${AppDates.dateTime(at)}',
      ),
      GrantStatus.pendente => (
        StampStatus.pendente,
        ConsentCopy.requestedOn(at),
        'desde ${AppDates.dateTime(at)}',
      ),
    };
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OfficeName(name: grant.officeName, style: AppType.subtitulo),
        const SizedBox(height: AppSpace.s8),
        StampWithDate(
          stamp: StatusStamp(status: stamp, semanticsDetail: spoken),
          date: date,
        ),
      ],
    );
    final active = grant.status == GrantStatus.ativa;
    return RuledRow(
      highlight: highlight,
      child: active
          ? _SplitRow(
              text: text,
              actions: (expand) => Column(
                crossAxisAlignment: expand
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SecondaryButton(
                    label: ConsentCopy.withdraw,
                    danger: true,
                    expand: expand,
                    onPressed: online ? onWithdraw : null,
                    disabledReason: online ? null : ConsentCopy.offlineShort,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Align(
                    alignment: expand
                        ? AlignmentDirectional.centerStart
                        : AlignmentDirectional.centerEnd,
                    child: TextAction(
                      label: ConsentCopy.readAccepted,
                      onPressed: onReadText,
                    ),
                  ),
                ],
              ),
            )
          : text,
    );
  }
}

/// Nome do escritório: até 2 linhas e reticências; o nome completo no
/// tooltip (hover, foco, toque longo) e na leitura de ecrã.
class _OfficeName extends StatelessWidget {
  const _OfficeName({required this.name, required this.style});

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      excludeFromSemantics: true,
      child: Text(
        name,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        semanticsLabel: name,
      ),
    );
  }
}

/// Texto à esquerda e ações à direita (médio/largo); empilhado em compacto
/// ou quando o texto ficaria abaixo de `textoMinimo` (escala, janela
/// estreita).
class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.text, required this.actions});

  final Widget text;
  final Widget Function(bool expand) actions;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return LayoutBuilder(
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
              actions(true),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: AppSpace.s24),
            actions(false),
          ],
        );
      },
    );
  }
}

/// Confirmação de retirada. A ação real é [onConfirm] (do ecrã), que
/// devolve a mensagem de erro ou nula quando o servidor confirmou.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.grant, required this.onConfirm});

  final ConsentGrant grant;
  final Future<String?> Function() onConfirm;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await widget.onConfirm();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = AppScope.of(context).connectivity;
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => ConfirmSheet(
        title: ConsentCopy.withdrawTitle(widget.grant.officeName),
        message: ConsentCopy.withdrawMessage,
        confirmLabel: ConsentCopy.withdraw,
        loadingLabel: ConsentCopy.withdrawing,
        cancelLabel: ConsentCopy.cancel,
        loading: _loading,
        errorMessage:
            _error ?? (connectivity.online ? null : ConsentCopy.offlineShort),
        onConfirm: connectivity.online ? _confirm : null,
      ),
    );
  }
}

/// Texto da versão aceite, só de leitura.
class _AcceptedTextSheet extends StatefulWidget {
  const _AcceptedTextSheet({required this.grant, required this.repository});

  final ConsentGrant grant;
  final ConsentRepository repository;

  @override
  State<_AcceptedTextSheet> createState() => _AcceptedTextSheetState();
}

class _AcceptedTextSheetState extends State<_AcceptedTextSheet> {
  ConsentText? _text;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final t = await widget.repository.text(widget.grant.consentVersion);
      if (mounted) setState(() => _text = t);
    } on ConsentFailure {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grant = widget.grant;
    final text = _text;
    final Widget body;
    if (text != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ConsentCopy.acceptedOn(grant.officeName, grant.statusAt),
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
          const SizedBox(height: AppSpace.s16),
          ConsentTextView(text: text, officeName: grant.officeName),
        ],
      );
    } else if (_failed) {
      body = InlineNotice(
        kind: NoticeKind.erro,
        message: ConsentCopy.acceptedTextFailed,
        actionLabel: ConsentCopy.retry,
        onAction: _load,
      );
    } else {
      body = const SkeletonRows(count: 2);
    }
    return ConfirmSheet(
      title: ConsentCopy.acceptedTextTitle,
      body: body,
      cancelLabel: ConsentCopy.close,
    );
  }
}
