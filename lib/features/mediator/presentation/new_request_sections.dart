import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../requests/application/new_request_controller.dart';
import '../../requests/domain/request_models.dart';
import 'request_copy.dart';
import 'request_parts.dart';

// ---------------------------------------------------------------------------
// 1. Cliente
// ---------------------------------------------------------------------------

/// Cliente escolhido: caixa `folha` com nome, email e "Mudar".
class ChosenClient extends StatelessWidget {
  const ChosenClient({super.key, required this.client, required this.onChange});

  final ActiveClient client;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return PaperBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.fullName, style: AppType.corpoForte),
                Text(
                  client.email,
                  softWrap: true,
                  style: AppType.corpoPequeno.copyWith(
                    color: AppColors.tintaMedia,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          TextAction(
            label: RequestCopy.change,
            semanticsLabel: 'Mudar de cliente (${client.fullName})',
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

/// Escolha do cliente: pesquisa por nome ou email e lista no fluxo (não
/// sobreposta) com os clientes de concessão ativa. Setas mudam a opção,
/// Enter escolhe, Esc fecha.
class ClientPicker extends StatefulWidget {
  const ClientPicker({super.key, required this.controller});

  final NewRequestController controller;

  @override
  State<ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends State<ClientPicker> {
  final TextEditingController _text = TextEditingController();
  int _active = 0;
  bool _open = true;

  NewRequestController get c => widget.controller;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final matches = c.matches;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (!_open) return KeyEventResult.ignored;
      setState(() => _open = false);
      return KeyEventResult.handled;
    }
    if (matches.isEmpty) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _open = true;
        _active = (_active + 1).clamp(0, matches.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _active = (_active - 1).clamp(0, matches.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && _open) {
      c.chooseClient(matches[_active.clamp(0, matches.length - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final load = c.clientsLoad;
    final matches = c.matches;
    final active = matches.isEmpty ? 0 : _active.clamp(0, matches.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          canRequestFocus: false,
          onKeyEvent: _onKey,
          child: LabeledField(
            label: RequestCopy.searchClient,
            controller: _text,
            trailing: const ExcludeSemantics(
              child: Icon(Icons.search, color: AppColors.tintaMedia),
            ),
            onChanged: (v) {
              c.setQuery(v);
              setState(() {
                _open = true;
                _active = 0;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        if (load == RequestsLoad.error)
          InlineNotice(
            kind: NoticeKind.erro,
            message: RequestCopy.clientsError,
            actionLabel: RequestCopy.retry,
            onAction: c.retry,
          )
        else if (load != RequestsLoad.ready)
          const SkeletonRows(count: 3)
        else if (_open)
          _OptionList(
            matches: matches,
            active: active,
            query: c.query,
            onChoose: c.chooseClient,
          )
        else
          Text(
            RequestCopy.onlyActiveNote,
            style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
          ),
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.matches,
    required this.active,
    required this.query,
    required this.onChoose,
  });

  final List<ActiveClient> matches;
  final int active;
  final String query;
  final ValueChanged<ActiveClient> onChoose;

  @override
  Widget build(BuildContext context) {
    final muted = AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.folha,
        borderRadius: AppRadius.controloBorda,
        border: Border.all(
          color: AppColors.reguaForte,
          width: AppStroke.controlo,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 336),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.s16),
                      child: Text(RequestCopy.noMatches, style: muted),
                    ),
                  for (final (i, m) in matches.indexed) ...[
                    if (i > 0) const AppRule(),
                    _Option(
                      client: m,
                      query: query,
                      active: i == active,
                      onPressed: () => onChoose(m),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const AppRule(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Text(RequestCopy.onlyActiveNote, style: muted),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.client,
    required this.query,
    required this.active,
    required this.onPressed,
  });

  final ActiveClient client;
  final String query;
  final bool active;
  final VoidCallback onPressed;

  /// Sublinha a parte que coincide com a pesquisa.
  Widget _marked(String text, TextStyle style) {
    final q = query.trim().toLowerCase();
    final i = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (i < 0) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + q.length),
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: text.substring(i + q.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.zero,
      semanticsLabel: '${client.fullName}, ${client.email}',
      builder: (context, s) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppSize.alvoPrincipal),
        color: active || s.hovered ? AppColors.realce : AppColors.nenhuma,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _marked(client.fullName, AppType.corpoForte),
            _marked(
              client.email,
              AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Tipos de seguro
// ---------------------------------------------------------------------------

/// Lista de verificação dos tipos, pela ordem do catálogo. Em médio, duas
/// colunas lidas de cima para baixo.
class TypeChoices extends StatelessWidget {
  const TypeChoices({super.key, required this.controller});

  final NewRequestController controller;

  NewRequestController get c => controller;

  Widget _row(InsuranceType t) {
    final open = c.openTypeFor(t.code);
    final isOpen = c.isOpen(t.code);
    final selected = c.isSelected(t.code);
    final String? meta = !isOpen
        ? null
        : (open == null
              ? RequestCopy.openSinceUnknown
              : RequestCopy.openSince(open.firstCreatedAt));
    Widget? below;
    if (selected && c.needsConfirmation(t.code)) {
      below = _RepeatNotice(
        key: ValueKey('repetido-${t.code}'),
        type: t,
        open: open,
        controller: c,
      );
    } else if (selected && c.repeatConfirmed(t.code)) {
      below = Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s12),
        child: Text(RequestCopy.secondRequest(t.name), style: AppType.registo),
      );
    }
    return CheckRow(
      key: ValueKey('tipo-${t.code}'),
      label: t.name,
      checked: selected,
      meta: meta,
      onChanged: c.submitting ? null : (_) => c.toggleType(t.code),
      below: below == null ? null : _Appearing(child: below),
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = c.catalog;
    final medium = AppBreakpoints.fromContext(context) == Breakpoint.medio;
    if (!medium || types.length < 2) {
      return RuledList(children: [for (final t in types) _row(t)]);
    }
    final half = (types.length + 1) ~/ 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RuledList(
            children: [for (final t in types.take(half)) _row(t)],
          ),
        ),
        const SizedBox(width: AppSpace.s24),
        Expanded(
          child: RuledList(
            children: [for (final t in types.skip(half)) _row(t)],
          ),
        ),
      ],
    );
  }
}

/// Opacidade e altura ao aparecer (`base` / `entrar`).
class _Appearing extends StatelessWidget {
  const _Appearing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.base),
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

/// Aviso de pedido repetido (US 1.8): por baixo da linha do tipo.
class _RepeatNotice extends StatelessWidget {
  const _RepeatNotice({
    super.key,
    required this.type,
    required this.open,
    required this.controller,
  });

  final InsuranceType type;
  final OpenType? open;
  final NewRequestController controller;

  @override
  Widget build(BuildContext context) {
    final busy = controller.submitting;
    // Recuado até ao texto do tipo (caixa de seleção `icone` + `s12`).
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSize.icone + AppSpace.s12,
        bottom: AppSpace.s12,
      ),
      child: InlineNotice(
        kind: NoticeKind.aviso,
        message: RequestCopy.repeatTitle(type.name),
        detail: RequestCopy.repeatDetail(open),
        actions: Wrap(
          spacing: AppSpace.s16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SecondaryButton(
              label: RequestCopy.createAnyway,
              onPressed: busy
                  ? null
                  : () => controller.confirmRepeat(type.code),
            ),
            TextAction(
              label: RequestCopy.removeType,
              semanticsLabel: '${RequestCopy.removeType} ${type.name}',
              onPressed: busy ? null : () => controller.removeType(type.code),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Mensagem
// ---------------------------------------------------------------------------

/// Campo multilinha "Para o cliente (opcional)" com contador "n / 500".
class MessageField extends StatefulWidget {
  const MessageField({super.key, required this.controller});

  final NewRequestController controller;

  @override
  State<MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<MessageField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.message,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tooLong = c.messageTooLong;
    final help = AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel(RequestCopy.messageLabelBase, optional: true),
        const SizedBox(height: AppSpace.s8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.campoMensagem),
          child: Semantics(
            label: RequestCopy.messageLabel,
            child: TextField(
              controller: _text,
              enabled: !c.submitting,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: AppType.corpo,
              cursorColor: AppColors.tinta,
              onChanged: (v) => c.message = v,
              decoration: InputDecoration(
                error: tooLong ? const SizedBox.shrink() : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(RequestCopy.messageHelp, style: help)),
            const SizedBox(width: AppSpace.s12),
            Semantics(
              liveRegion: tooLong,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tooLong) ...[
                    const Icon(
                      Icons.error_outline,
                      size: AppSize.iconePequeno,
                      color: AppColors.erro,
                    ),
                    const SizedBox(width: AppSpace.s4),
                  ],
                  Text(
                    RequestCopy.messageCounter(c.messageLength),
                    style: AppType.registo.copyWith(
                      color: tooLong ? AppColors.erro : AppColors.tintaTenue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "O cliente vai receber"
// ---------------------------------------------------------------------------

/// As folhas (uma por tipo escolhido) com a lista editável.
class SheetsZone extends StatefulWidget {
  const SheetsZone({super.key, required this.controller});

  final NewRequestController controller;

  @override
  State<SheetsZone> createState() => _SheetsZoneState();
}

class _SheetsZoneState extends State<SheetsZone> {
  /// Tipo em que está aberta a caixa "Acrescentar item".
  String? _adding;

  /// Linhas acabadas de acrescentar ou repostas (realce).
  final Set<String> _highlight = {};

  NewRequestController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final selected = c.selectedTypes;
    final toCreate = c.typesToCreate.map((t) => t.code).toList();
    final busy = c.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(RequestCopy.willReceive, style: AppType.subtitulo),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          RequestCopy.willReceiveHint,
          style: AppType.corpoPequeno.copyWith(color: AppColors.tintaMedia),
        ),
        const SizedBox(height: AppSpace.s16),
        // Chave no widget de topo de cada folha: escolher um tipo anterior no
        // catálogo desliza as seguintes em vez de as recriar; as retiradas
        // saem com animação (`base` / `sair`).
        ExitingList(
          gap: AppSpace.s24,
          children: [
            for (final t in selected)
              Entering(
                key: ValueKey('folha-${t.code}'),
                child: _sheet(t, toCreate, busy),
              ),
          ],
        ),
        if (selected.isEmpty)
          DashedBox(
            child: Text(
              c.client == null
                  ? RequestCopy.noClientNoTypesBox
                  : RequestCopy.noTypesBox,
              style: AppType.corpo.copyWith(color: AppColors.tintaMedia),
            ),
          ),
      ],
    );
  }

  Widget _sheet(InsuranceType t, List<String> toCreate, bool busy) {
    final lines = c.lines(t.code);
    final waiting = c.needsConfirmation(t.code);
    final index = toCreate.indexOf(t.code) + 1;
    return RequestSheet(
      editable: true,
      title: t.name,
      // À espera de confirmação ocupa o lugar de "Pedido 1 de 2", em `registo`.
      indexLabel: waiting
          ? RequestCopy.awaitingYou
          : RequestCopy.requestIndex(index, toCreate.length),
      notes: [
        if (c.allowPolicyConditions) RequestCopy.policyNoteSheet,
        ?t.note,
      ],
      items: [
        for (final l in lines)
          // Itens acrescentados ou repostos entram com `lento` / `entrar`,
          // além do `realce`.
          Entering(
            key: ValueKey('${t.code}/${l.key}'),
            enabled: _highlight.contains('${t.code}/${l.key}'),
            child: RequestItemRow(
              kind: l.kind == ItemKind.document
                  ? RequestItemKind.documento
                  : RequestItemKind.dado,
              text: l.label,
              free: l.isFree,
              highlight: _highlight.contains('${t.code}/${l.key}'),
              contextLabel: 'do pedido de ${t.name}',
              onAction: busy ? null : () => c.removeLine(t.code, l.key),
            ),
          ),
      ],
      emptyNotice: InlineNotice(
        kind: NoticeKind.erro,
        message: RequestCopy.emptyListNotice(t.name),
      ),
      removedCount: c.removedCount(t.code),
      onAddItem: busy ? null : () => setState(() => _adding = t.code),
      onRestore: busy
          ? null
          : () {
              final before = {for (final l in lines) l.key};
              c.restoreList(t.code);
              setState(() {
                for (final l in c.lines(t.code)) {
                  if (!before.contains(l.key)) {
                    _highlight.add('${t.code}/${l.key}');
                  }
                }
              });
            },
      belowItems: _adding == t.code
          ? AddItemBox(
              key: ValueKey('novo-item-${t.code}'),
              controller: c,
              type: t,
              onDone: (key) => setState(() {
                _adding = null;
                if (key != null) _highlight.add('${t.code}/$key');
              }),
            )
          : null,
    );
  }
}

/// Caixa "Acrescentar item": texto, "É um" Documento / Dado a preencher.
/// Enter acrescenta; Esc cancela.
class AddItemBox extends StatefulWidget {
  const AddItemBox({
    super.key,
    required this.controller,
    required this.type,
    required this.onDone,
  });

  final NewRequestController controller;
  final InsuranceType type;

  /// Chamado ao fechar; [String] = chave da linha acrescentada (ou nulo se
  /// cancelou).
  final ValueChanged<String?> onDone;

  @override
  State<AddItemBox> createState() => _AddItemBoxState();
}

class _AddItemBoxState extends State<AddItemBox> {
  final TextEditingController _text = TextEditingController();
  ItemKind _kind = ItemKind.document;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _add() {
    final err = widget.controller.addFreeItem(
      widget.type.code,
      _kind,
      _text.text,
    );
    if (err != null) {
      setState(() => _error = RequestCopy.freeItemError(err));
      return;
    }
    widget.onDone(widget.controller.lines(widget.type.code).last.key);
  }

  @override
  Widget build(BuildContext context) {
    return _Appearing(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              widget.onDone(null),
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.controloBorda,
            border: Border.all(
              color: AppColors.reguaForte,
              width: AppStroke.controlo,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: RequestCopy.newItem,
                controller: _text,
                autofocus: true,
                errorText: _error,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(height: AppSpace.s16),
              Semantics(
                container: true,
                label: RequestCopy.kindLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(RequestCopy.kindLabel, style: AppType.rotulo),
                    const SizedBox(height: AppSpace.s4),
                    Wrap(
                      spacing: AppSpace.s24,
                      children: [
                        _Radio(
                          label: RequestCopy.kindDocument,
                          selected: _kind == ItemKind.document,
                          onPressed: () =>
                              setState(() => _kind = ItemKind.document),
                        ),
                        _Radio(
                          label: RequestCopy.kindData,
                          selected: _kind == ItemKind.data,
                          onPressed: () =>
                              setState(() => _kind = ItemKind.data),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              Wrap(
                spacing: AppSpace.s16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SecondaryButton(
                    label: RequestCopy.addItemConfirm,
                    onPressed: _add,
                  ),
                  TextAction(
                    label: RequestCopy.cancel,
                    onPressed: () => widget.onDone(null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      selected: selected,
      semanticsLabel: label,
      builder: (context, s) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.alvoMinimo),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: AppSize.icone,
              color: selected ? AppColors.tinta : AppColors.reguaForte,
            ),
            const SizedBox(width: AppSpace.s8),
            Text(label, style: AppType.corpo),
          ],
        ),
      ),
    );
  }
}
