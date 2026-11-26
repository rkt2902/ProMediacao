import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../application/clients_controller.dart';
import '../domain/mediator_models.dart';
import 'mediator_copy.dart';

/// Composição da lista (03-design.md, ecrã 5).
enum ClientsLayout { table4, table3, stacked }

/// Escolhe o layout pelo tamanho da janela e desce um nível se a coluna
/// Cliente ficar abaixo de `textoMinimo` (escala de texto, janela estreita,
/// zoom do navegador). As colunas fixas crescem com a escala do texto.
ClientsLayout chooseClientsLayout({
  required double width,
  required Breakpoint breakpoint,
  required double textScale,
}) {
  final s = math.max(1.0, textScale);
  const gap = AppSpace.s16;
  final four =
      width -
      (AppSize.colunaEstado + AppSize.colunaData + AppSize.colunaAcao) * s -
      3 * gap;
  final three = width - (AppSize.colunaData + AppSize.colunaAcao) * s - 2 * gap;
  var level = switch (breakpoint) {
    Breakpoint.largo => 4,
    Breakpoint.medio => 3,
    Breakpoint.compacto => 1,
  };
  if (level == 4 && four < AppSize.textoMinimo) level = 3;
  if (level == 3 && three < AppSize.textoMinimo) level = 1;
  return switch (level) {
    4 => ClientsLayout.table4,
    3 => ClientsLayout.table3,
    _ => ClientsLayout.stacked,
  };
}

StampStatus _stamp(ClientStatus s) => switch (s) {
  ClientStatus.ativo => StampStatus.ativo,
  ClientStatus.pendente => StampStatus.pendente,
  ClientStatus.recusado => StampStatus.recusado,
};

String _dateText(OfficeClient c) => switch (c.status) {
  ClientStatus.ativo => 'Desde ${AppDates.date(c.updatedAt)}',
  ClientStatus.pendente => 'Enviado a ${AppDates.dateTime(c.updatedAt)}',
  ClientStatus.recusado => 'Recusado a ${AppDates.dateTime(c.updatedAt)}',
};

String _spokenDetail(OfficeClient c) {
  final d = MediatorCopy.spokenDate(c.updatedAt);
  return switch (c.status) {
    ClientStatus.ativo => 'desde $d',
    ClientStatus.pendente => 'enviado a $d',
    ClientStatus.recusado => 'recusado a $d',
  };
}

/// Lista de clientes: tabela de 4 colunas, de 3 ou lista empilhada. Linhas
/// sem hover nem clique; só "Reenviar pedido" reage. Nome e email são
/// selecionáveis (a quem envolve a lista num `SelectionArea`).
class ClientsList extends StatelessWidget {
  const ClientsList({
    super.key,
    required this.controller,
    required this.online,
    required this.onResend,
  });

  final ClientsController controller;
  final bool online;
  final void Function(OfficeClient) onResend;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, c) {
        final layout = chooseClientsLayout(
          width: c.maxWidth,
          breakpoint: bp,
          textScale: scale,
        );
        final rows = [
          for (final item in controller.items)
            _row(layout, item, key: ValueKey(item.grantId)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout != ClientsLayout.stacked) _Header(layout: layout),
            RuledList(topRule: layout == ClientsLayout.stacked, children: rows),
          ],
        );
      },
    );
  }

  Widget _row(ClientsLayout layout, OfficeClient item, {Key? key}) {
    final highlighted = controller.highlightId == item.grantId;
    final action = item.status == ClientStatus.pendente
        ? _ResendAction(
            controller: controller,
            item: item,
            online: online,
            onResend: onResend,
          )
        : null;
    final label =
        '${item.fullName}, ${item.email}. ${_stamp(item.status).spoken}. '
        '${_dateText(item)}.';

    final Widget body = switch (layout) {
      ClientsLayout.stacked => _StackedBody(item: item, action: action),
      ClientsLayout.table3 => _TableBody(
        item: item,
        action: action,
        withDateColumn: false,
      ),
      ClientsLayout.table4 => _TableBody(
        item: item,
        action: action,
        withDateColumn: true,
      ),
    };
    final isTable = layout != ClientsLayout.stacked;
    return KeyedSubtree(
      key: key,
      child: _Entering(
        enabled: highlighted,
        child: RuledRow(
          highlight: highlighted,
          padding: isTable
              ? const EdgeInsets.symmetric(vertical: AppSpace.s12)
              : const EdgeInsets.symmetric(vertical: AppSpace.s16),
          // Sem ação: a leitura de ecrã lê a linha toda e diz que não há ações.
          semanticsLabel: action == null
              ? (item.status == ClientStatus.recusado
                    ? '$label Sem ações disponíveis.'
                    : label)
              : null,
          child: isTable
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSize.linhaTabela - 2 * AppSpace.s12,
                  ),
                  child: body,
                )
              : body,
        ),
      ),
    );
  }
}

/// Linha nova ou alterada: entra com opacidade e altura (`lento` / `entrar`).
class _Entering extends StatelessWidget {
  const _Entering({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.lento),
      curve: AppMotion.entrar,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.layout});

  final ClientsLayout layout;

  @override
  Widget build(BuildContext context) {
    final style = AppType.rotulo.copyWith(color: AppColors.tintaMedia);
    const gap = SizedBox(width: AppSpace.s16);
    Widget col(String text, double width) => SizedBox(
      width: width,
      child: Text(text, style: style),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Row(
        children: [
          Expanded(child: Text(MediatorCopy.colClient, style: style)),
          gap,
          if (layout == ClientsLayout.table4) ...[
            col(MediatorCopy.colState, AppSize.colunaEstado),
            gap,
            col(MediatorCopy.colDate, AppSize.colunaData),
          ] else
            col(MediatorCopy.colState, AppSize.colunaData),
          gap,
          // "Ação": só para leitura de ecrã, visualmente vazio.
          SizedBox(
            width: AppSize.colunaAcao,
            child: Semantics(
              label: MediatorCopy.colAction,
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCell extends StatelessWidget {
  const _ClientCell({required this.item, required this.maxLines});

  final OfficeClient item;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final truncates = maxLines == 1;
    Widget text(String s, TextStyle style) {
      final t = Text(
        s,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
      // Tooltip com o texto completo (hover, foco e toque longo) onde há
      // reticências; no empilhado o texto quebra e vê-se inteiro.
      return truncates ? Tooltip(message: s, child: t) : t;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        text(item.fullName, AppType.corpoForte),
        text(
          item.email,
          AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
      ],
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.item,
    required this.action,
    required this.withDateColumn,
  });

  final OfficeClient item;
  final Widget? action;
  final bool withDateColumn;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: AppSpace.s16);
    final stamp = StatusStamp(
      status: _stamp(item.status),
      semanticsDetail: _spokenDetail(item),
    );
    final date = Text(_dateText(item), style: AppType.registo);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _ClientCell(item: item, maxLines: 1)),
        gap,
        if (withDateColumn) ...[
          SizedBox(
            width: AppSize.colunaEstado,
            // O carimbo mede ~150 com a fonte real e a coluna tem 140: encolhe
            // só se for preciso (ver o handoff: `colunaEstado` devia ser 152).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: stamp,
            ),
          ),
          gap,
          SizedBox(width: AppSize.colunaData, child: date),
        ] else
          SizedBox(
            width: AppSize.colunaData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                stamp,
                const SizedBox(height: AppSpace.s4),
                date,
              ],
            ),
          ),
        gap,
        SizedBox(
          width: AppSize.colunaAcao,
          child: action == null
              ? null
              : Align(alignment: Alignment.centerRight, child: action),
        ),
      ],
    );
  }
}

class _StackedBody extends StatelessWidget {
  const _StackedBody({required this.item, required this.action});

  final OfficeClient item;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ClientCell(item: item, maxLines: 2),
        const SizedBox(height: AppSpace.s12),
        // A data desce para a linha de baixo se não couber ao lado do carimbo.
        Wrap(
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusStamp(
              status: _stamp(item.status),
              semanticsDetail: _spokenDetail(item),
            ),
            Text(_dateText(item), style: AppType.registo),
          ],
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpace.s8),
          Align(alignment: Alignment.centerLeft, child: action),
        ],
      ],
    );
  }
}

class _ResendAction extends StatelessWidget {
  const _ResendAction({
    required this.controller,
    required this.item,
    required this.online,
    required this.onResend,
  });

  final ClientsController controller;
  final OfficeClient item;
  final bool online;
  final void Function(OfficeClient) onResend;

  @override
  Widget build(BuildContext context) {
    final until = controller.lockUntil(item);
    final blocked = !online || until != null;
    return TextAction(
      label: MediatorCopy.resend,
      loadingLabel: MediatorCopy.resending,
      loading: controller.isSending(item.grantId),
      semanticsLabel: '${MediatorCopy.resend} a ${item.fullName}',
      onPressed: blocked ? null : () => onResend(item),
      disabledReason: !online
          ? MediatorCopy.needsConnection
          : (until != null ? MediatorCopy.canResendAt(until) : null),
    );
  }
}
