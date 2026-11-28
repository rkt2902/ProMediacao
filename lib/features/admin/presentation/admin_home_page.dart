import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import '../application/admin_controller.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';
import 'admin_copy.dart';
import 'admin_forms.dart';

/// Painel do admin (03-design.md, ecrã 6): 4 contagens, escritórios, criar
/// escritório e convidar mediador. Nunca lê nem mostra nomes ou emails de
/// pessoas. [repository] só serve aos testes; por defeito usa o Supabase.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, this.repository});

  final AdminRepository? repository;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  AdminController? _controller;
  String? _notice;
  String? _noticeOfficeId;
  String? _highlightId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    final c = AdminController(
      widget.repository ?? SupabaseAdminRepository(Supabase.instance.client),
      onNetworkFailure: services.connectivity.reportNetworkFailure,
      onReachable: services.connectivity.reportReachable,
    );
    _controller = c;
    c.load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final services = AppScope.of(context);
    final c = _controller!;
    final before = c.offices.length;
    final ok = await showAdminForm(
      context,
      builder: (_) => CreateOfficeForm(
        controller: c,
        connectivity: services.connectivity,
        onSignOut: services.session.signOut,
      ),
    );
    if (ok == true && mounted && c.offices.length > before) {
      setState(() {
        _notice = AdminCopy.officeCreated;
        _noticeOfficeId = c.offices.first.id;
        _highlightId = c.offices.first.id;
      });
    }
  }

  Future<void> _invite(OfficeSummary office) async {
    final services = AppScope.of(context);
    final ok = await showAdminForm(
      context,
      builder: (_) => InviteMediatorForm(
        controller: _controller!,
        connectivity: services.connectivity,
        office: office,
        onSignOut: services.session.signOut,
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _notice = AdminCopy.inviteSent;
        _noticeOfficeId = null;
        _highlightId = office.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final c = _controller!;
    final bp = AppBreakpoints.fromContext(context);
    return ListenableBuilder(
      listenable: Listenable.merge([c, services.connectivity]),
      builder: (context, _) {
        final online = services.connectivity.online;
        return PageFrame(
          tabLabel: AdminCopy.tab,
          onSignOut: services.session.signOut,
          banner: OfflineBar(visible: !online),
          colophon: const SessionColophon(),
          child: Padding(
            padding: const EdgeInsets.only(top: PageFrame.contentTop),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(AdminCopy.title, style: AppType.tituloPara(bp)),
                ),
                if (_notice != null) ...[
                  const SizedBox(height: AppSpace.s16),
                  _successNotice(c),
                ],
                const SizedBox(height: AppSpace.s24),
                if (c.state == AdminLoad.failed)
                  InlineNotice(
                    kind: NoticeKind.erro,
                    message: AdminCopy.loadError,
                    actionLabel: AdminCopy.retry,
                    onAction: c.load,
                  )
                else ...[
                  _CountsStrip(
                    counts: c.counts,
                    compact: bp == Breakpoint.compacto,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    AdminCopy.privacyNote,
                    style: AppType.corpoPequeno.copyWith(
                      color: AppColors.tintaTenue,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s48),
                  _officesSection(c, bp, online),
                  const SizedBox(height: AppSpace.s48),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _successNotice(AdminController c) {
    OfficeSummary? office;
    for (final o in c.offices) {
      if (o.id == _noticeOfficeId) office = o;
    }
    final target = office;
    return InlineNotice(
      message: _notice!,
      icon: Icons.check_circle_outline,
      actionLabel: target == null ? null : AdminCopy.inviteMediator,
      onAction: target == null ? null : () => _invite(target),
    );
  }

  Widget _officesSection(AdminController c, Breakpoint bp, bool online) {
    final compact = bp == Breakpoint.compacto;
    final loading = c.state == AdminLoad.loading;
    final empty = !loading && c.offices.isEmpty;

    final createButton = PrimaryButton(
      label: AdminCopy.createOffice,
      principal: compact,
      expand: compact,
      onPressed: online && !loading ? _create : null,
    );
    final heading = Semantics(
      header: true,
      child: Text(AdminCopy.offices, style: AppType.subtitulo),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (empty)
          heading
        else if (compact) ...[
          heading,
          const SizedBox(height: AppSpace.s16),
          createButton,
        ] else
          Row(
            children: [
              Expanded(child: heading),
              createButton,
            ],
          ),
        if (!online) ...[
          const SizedBox(height: AppSpace.s12),
          Text(
            AdminCopy.offlineReason,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
        ],
        const SizedBox(height: AppSpace.s24),
        if (loading)
          const SkeletonRows(count: 3)
        else if (empty)
          _emptyBlock(compact, online)
        else
          _list(c, online),
      ],
    );
  }

  Widget _emptyBlock(bool compact, bool online) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppRule(),
        const SizedBox(height: AppSpace.s24),
        Text(AdminCopy.emptyTitle, style: AppType.corpoForte),
        const SizedBox(height: AppSpace.s8),
        Text(
          AdminCopy.emptyBody,
          style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrimaryButton(
            label: AdminCopy.createOffice,
            principal: compact,
            expand: compact,
            onPressed: online ? _create : null,
          ),
        ),
      ],
    );
  }

  Widget _list(AdminController c, bool online) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    return RuledList(
      children: [
        for (final o in c.offices)
          RuledRow(
            key: ValueKey(o.id),
            highlight: o.id == _highlightId,
            padding: EdgeInsets.symmetric(
              vertical: compact ? AppSpace.s16 : AppSpace.s12,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? 0 : AppSize.linhaTabela - 2 * AppSpace.s12,
              ),
              child: _OfficeRow(
                office: o,
                onInvite: online ? () => _invite(o) : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Linha de escritório: nome, nº de mediadores e "Convidar mediador".
/// Empilha quando a largura não chega.
class _OfficeRow extends StatelessWidget {
  const _OfficeRow({required this.office, required this.onInvite});

  final OfficeSummary office;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final name = Text(office.name, style: AppType.corpoForte);
    final count = Text(
      AdminCopy.mediatorCount(office.mediatorCount),
      style: AppType.registo.copyWith(color: AppColors.tintaTenue),
    );
    final action = TextAction(
      label: AdminCopy.inviteMediator,
      semanticsLabel: '${AdminCopy.inviteMediator} para ${office.name}',
      onPressed: onInvite,
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name,
              const SizedBox(height: AppSpace.s4),
              count,
              const SizedBox(height: AppSpace.s8),
              action,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: name),
            const SizedBox(width: AppSpace.s24),
            SizedBox(width: AppSize.colunaEstado + AppSpace.s24, child: count),
            action,
          ],
        );
      },
    );
  }
}

/// Faixa de 4 contagens (não 3 cartões): colunas iguais com réguas
/// verticais; em compacto, empilhadas com o número à esquerda e o rótulo à
/// direita. Sem dados (`counts == null`): blocos `esqueleto`, nunca "0".
class _CountsStrip extends StatelessWidget {
  const _CountsStrip({required this.counts, required this.compact});

  final AdminCounts? counts;
  final bool compact;

  static const _rule = BorderSide(
    color: AppColors.regua,
    width: AppStroke.fino,
  );

  @override
  Widget build(BuildContext context) {
    final c = counts;
    final items = [
      (AdminCopy.offices, c?.offices),
      (AdminCopy.mediators, c?.mediators),
      (AdminCopy.clients, c?.clients),
      (AdminCopy.requests, c?.requests),
    ];

    final Widget strip;
    if (compact) {
      strip = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const AppRule(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
              child: _count(context, items[i].$1, items[i].$2, row: true),
            ),
          ],
        ],
      );
    } else {
      strip = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0 ? null : const Border(left: _rule),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: i == 0 ? 0 : AppSpace.s24,
                      top: AppSpace.s24,
                      bottom: AppSpace.s24,
                    ),
                    child: _count(context, items[i].$1, items[i].$2),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: _rule, bottom: _rule),
      ),
      child: strip,
    );
  }

  Widget _count(
    BuildContext context,
    String label,
    int? value, {
    bool row = false,
  }) {
    final labelText = Text(
      label,
      style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
    );
    final number = AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.base),
      switchInCurve: AppMotion.entrar,
      switchOutCurve: AppMotion.sair,
      child: value == null
          ? const _NumberSkeleton(key: ValueKey('skeleton'))
          : Text('$value', key: const ValueKey('value'), style: AppType.numero),
    );
    return MergeSemantics(
      child: row
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSpace.s72 + AppSpace.s16,
                  ),
                  child: number,
                ),
                labelText,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [number, labelText],
            ),
    );
  }
}

/// Bloco `esqueleto` de 56 de altura no lugar do número, a pulsar.
class _NumberSkeleton extends StatefulWidget {
  const _NumberSkeleton({super.key});

  @override
  State<_NumberSkeleton> createState() => _NumberSkeletonState();
}

class _NumberSkeletonState extends State<_NumberSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.pulsar ~/ 2,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AppMotion.reduced(context);
    if (reduced && _started) {
      _c.stop();
      _c.value = 0;
      _started = false;
    } else if (!reduced && !_started) {
      _c.repeat(reverse: true);
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = Tween<double>(
      begin: 1,
      end: AppMotion.pulsarMinimo,
    ).chain(CurveTween(curve: AppMotion.mudar)).animate(_c);
    return SizedBox(
      height: AppSize.alvoPrincipal + AppSpace.s4,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: 'A carregar',
          child: ExcludeSemantics(
            child: FadeTransition(
              opacity: opacity,
              child: Container(
                width: AppSpace.s72 + AppSpace.s24,
                height: AppSize.alvoPrincipal,
                decoration: const BoxDecoration(
                  color: AppColors.esqueleto,
                  borderRadius: AppRadius.carimboBorda,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
