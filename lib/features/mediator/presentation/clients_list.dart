import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../application/clients_controller.dart';
import '../../requests/domain/request_models.dart';
import '../domain/mediator_models.dart';
import 'mediator_copy.dart';
import 'request_copy.dart';
import 'request_parts.dart';

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
      (AppSize.colunaData + AppSize.colunaEtapa + AppSize.colunaAcao) * s -
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
    required this.onNewRequest,
    required this.onOpenClient,
  });

  final ClientsController controller;
  final bool online;
  final void Function(OfficeClient) onResend;

  /// "Novo pedido" da linha (cliente ativo).
  final void Function(OfficeClient) onNewRequest;

  /// Nome do cliente ativo: abre a ficha.
  final void Function(OfficeClient) onOpenClient;

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
            _row(
              layout,
              item,
              math.max(1.0, scale),
              key: ValueKey(item.grantId),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout != ClientsLayout.stacked)
              _Header(layout: layout, scale: math.max(1.0, scale)),
            RuledList(topRule: true, children: rows),
          ],
        );
      },
    );
  }

  Widget _row(
    ClientsLayout layout,
    OfficeClient item,
    double scale, {
    Key? key,
  }) {
    final highlighted = controller.highlightId == item.grantId;
    final Widget? action = switch (item.status) {
      ClientStatus.pendente => _ResendAction(
        controller: controller,
        item: item,
        online: online,
        onResend: onResend,
      ),
      ClientStatus.ativo => TextAction(
        label: RequestCopy.newRequest,
        icon: Icons.add,
        semanticsLabel: '${RequestCopy.newRequest} para ${item.fullName}',
        onPressed: online ? () => onNewRequest(item) : null,
        disabledReason: online ? null : MediatorCopy.needsConnectionToCreate,
      ),
      ClientStatus.recusado => null,
    };
    final link = item.status == ClientStatus.ativo
        ? () => onOpenClient(item)
        : null;
    final requests = _RequestsCell(controller: controller, item: item);
    final label =
        '${item.fullName}, ${item.email}. ${_stamp(item.status).spoken}. '
        '${_dateText(item)}. ${requests.spoken}';

    final Widget body = switch (layout) {
      ClientsLayout.stacked => _StackedBody(
        item: item,
        action: action,
        requests: requests,
        onOpen: link,
      ),
      ClientsLayout.table3 => _TableBody(
        item: item,
        action: action,
        scale: scale,
        columns: 3,
        requests: requests,
        onOpen: link,
      ),
      ClientsLayout.table4 => _TableBody(
        item: item,
        action: action,
        scale: scale,
        columns: 4,
        requests: requests,
        onOpen: link,
      ),
    };
    final isTable = layout != ClientsLayout.stacked;
    return KeyedSubtree(
      key: key,
      child: Entering(
        enabled: highlighted,
        child: RuledRow(
          highlight: highlighted,
          padding: isTable
              ? EdgeInsets.symmetric(
                  vertical: link == null ? AppSpace.s12 : AppSpace.s4,
                )
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

class _Header extends StatelessWidget {
  const _Header({required this.layout, required this.scale});

  final ClientsLayout layout;
  final double scale;

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
            col(MediatorCopy.colState, AppSize.colunaData * scale),
            gap,
            col(MediatorCopy.colRequests, AppSize.colunaEtapa * scale),
          ] else
            col(MediatorCopy.colStateAndRequests, AppSize.colunaData * scale),
          gap,
          // "Ação": só para leitura de ecrã, visualmente vazio.
          SizedBox(
            width: AppSize.colunaAcao * scale,
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
  const _ClientCell({
    required this.item,
    required this.maxLines,
    required this.onOpen,
  });

  final OfficeClient item;
  final int maxLines;

  /// Só o cliente ativo tem ligação para a ficha.
  final VoidCallback? onOpen;

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

    if (onOpen == null) {
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
    // O alvo da ligação é o bloco nome + email; o sublinhado fica no nome.
    final link = NameLink(
      label: item.fullName,
      detail: item.email,
      maxLines: truncates ? 1 : null,
      onPressed: onOpen,
    );
    return truncates ? Tooltip(message: item.fullName, child: link) : link;
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({
    required this.item,
    required this.action,
    required this.scale,
    required this.columns,
    required this.requests,
    required this.onOpen,
  });

  final OfficeClient item;
  final Widget? action;
  final double scale;

  /// 4 (Estado, Pedidos separados) ou 3 (Estado e pedidos juntos).
  final int columns;
  final _RequestsCell requests;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: AppSpace.s16);
    final stamp = StatusStamp(
      status: _stamp(item.status),
      semanticsDetail: _spokenDetail(item),
    );
    final date = Text(_dateText(item), style: AppType.registo);
    final state = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        stamp,
        const SizedBox(height: AppSpace.s4),
        date,
        if (columns == 3 && requests.visible) ...[
          const SizedBox(height: AppSpace.s8),
          requests,
        ],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ClientCell(item: item, maxLines: 1, onOpen: onOpen),
        ),
        gap,
        SizedBox(width: AppSize.colunaData * scale, child: state),
        if (columns == 4) ...[
          gap,
          SizedBox(width: AppSize.colunaEtapa * scale, child: requests),
        ],
        gap,
        SizedBox(
          width: AppSize.colunaAcao * scale,
          child: action == null
              ? null
              : Align(alignment: Alignment.centerRight, child: action),
        ),
      ],
    );
  }
}

class _StackedBody extends StatelessWidget {
  const _StackedBody({
    required this.item,
    required this.action,
    required this.requests,
    required this.onOpen,
  });

  final OfficeClient item;
  final Widget? action;
  final _RequestsCell requests;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ClientCell(item: item, maxLines: 2, onOpen: onOpen),
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
        if (requests.visible) ...[
          const SizedBox(height: AppSpace.s12),
          Align(alignment: Alignment.centerLeft, child: requests),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpace.s8),
          Align(alignment: Alignment.centerLeft, child: action),
        ],
      ],
    );
  }
}

/// Coluna "Pedidos": "3 em curso" + trilho com a etapa mais avançada, ou
/// "Sem pedidos" (clientes ativos). Pendentes e recusados: vazio.
class _RequestsCell extends StatelessWidget {
  const _RequestsCell({required this.controller, required this.item});

  final ClientsController controller;
  final OfficeClient item;

  bool get _active => item.status == ClientStatus.ativo;

  /// Há algo para mostrar (pendentes e recusados não têm pedidos visíveis).
  bool get visible => _active;

  /// Frase para a leitura de ecrã da linha.
  String get spoken {
    if (!_active) return 'Sem pedidos visíveis até o cliente aceitar.';
    if (!controller.requestsKnown) return 'Pedidos indisponíveis.';
    final s = controller.summaryFor(item);
    if (s == null || s.openCount == 0) {
      return s != null && s.totalCount > 0
          ? 'Sem pedidos em curso.'
          : 'Sem pedidos.';
    }
    return '${RequestCopy.inProgress(s.openCount)}. Etapa mais avançada: '
        '${RequestCopy.stageShort(s.maxOpenStage ?? RequestStage.created)}.';
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    final muted = AppType.corpo.copyWith(color: AppColors.tintaMedia);
    if (!controller.requestsKnown) {
      return Text('—', style: muted);
    }
    final s = controller.summaryFor(item);
    if (s == null || s.openCount == 0) {
      return Text(
        s != null && s.totalCount > 0
            ? 'Sem pedidos em curso'
            : RequestCopy.noRequestsTitle,
        style: muted,
      );
    }
    final stage = s.maxOpenStage ?? RequestStage.created;
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${s.openCount}',
                  style: AppType.corpoPequeno.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' em curso', style: AppType.corpoPequeno),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          StageTrack(stage: stage.number, label: RequestCopy.stageShort(stage)),
        ],
      ),
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
