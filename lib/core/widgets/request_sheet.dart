import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_buttons.dart';
import 'exiting_list.dart';
import 'ruled_list.dart';

/// Folha de um pedido (002): cabeçalho, notas, itens ([RequestItemRow]) e
/// rodapé.
///
/// - Modo [editable] (Novo pedido): superfície `folha` (régua `fino`, raio
///   `superficie`, sem sombra, padding `s24`, `s16` em compacto) e rodapé
///   com "Acrescentar item" ([onAddItem]) e, se [removedCount] > 0, "{n}
///   item(ns) tirado(s) · Repor lista" ([onRestore]).
/// - Modo leitura (pedido aberto): sem superfície, sobre o `papel`; sem
///   rodapé.
///
/// Slots: [notes] (texto de cada nota, com `info_outline`), [items] (as
/// linhas, vão numa `RuledList`), [belowItems] (ex.: a caixa "Novo item" no
/// sítio do rodapé; quando existe, substitui o rodapé de "Acrescentar
/// item"), [emptyNotice] (ex.: `InlineNotice` de lista vazia, aparece no
/// lugar dos itens se [items] estiver vazio).
/// [indexLabel] é o "Pedido 1 de 2" à direita do título; [subtitle] uma
/// linha de apoio por baixo do título (ex.: "À espera da sua confirmação").
class RequestSheet extends StatelessWidget {
  const RequestSheet({
    super.key,
    this.title,
    this.indexLabel,
    this.subtitle,
    this.notes = const [],
    required this.items,
    this.editable = false,
    this.onAddItem,
    this.removedCount = 0,
    this.onRestore,
    this.belowItems,
    this.emptyNotice,
  });

  final String? title;
  final String? indexLabel;
  final String? subtitle;
  final List<String> notes;
  final List<Widget> items;
  final bool editable;
  final VoidCallback? onAddItem;
  final int removedCount;
  final VoidCallback? onRestore;
  final Widget? belowItems;
  final Widget? emptyNotice;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final about = title == null ? '' : ' do pedido de $title';

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.s16,
            children: [
              Semantics(
                header: true,
                child: Text(title!, style: AppType.subtitulo),
              ),
              if (indexLabel != null)
                Text(
                  indexLabel!,
                  style: AppType.registo.copyWith(color: AppColors.tintaMedia),
                ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s4),
              child: Text(
                subtitle!,
                style: AppType.corpoPequeno.copyWith(
                  color: AppColors.tintaMedia,
                ),
              ),
            ),
          const SizedBox(height: AppSpace.s16),
        ],
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: AppSpace.s4 / 2),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.info_outline,
                      size: AppSize.iconePequeno,
                      color: AppColors.tintaMedia,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: Text(
                    n,
                    style: AppType.corpoPequeno.copyWith(
                      color: AppColors.tintaMedia,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (editable)
          // Os itens tirados saem com animação (`base` / `sair`).
          ExitingList(ruled: true, children: items)
        else if (items.isEmpty && emptyNotice != null)
          emptyNotice!
        else
          RuledList(children: items),
        if (editable && items.isEmpty && emptyNotice != null) emptyNotice!,
        if (belowItems != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s12),
            child: belowItems,
          )
        else if (editable)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.s24,
              children: [
                TextAction(
                  label: 'Acrescentar item',
                  icon: Icons.add,
                  onPressed: onAddItem,
                  semanticsLabel: 'Acrescentar item$about',
                ),
                if (removedCount > 0)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        removedCount == 1
                            ? '1 item tirado · '
                            : '$removedCount itens tirados · ',
                        style: AppType.corpoPequeno,
                      ),
                      TextAction(
                        label: 'Repor lista',
                        onPressed: onRestore,
                        semanticsLabel: 'Repor lista$about',
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );

    if (!editable) return column;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpace.s16 : AppSpace.s24),
      decoration: BoxDecoration(
        color: AppColors.folha,
        borderRadius: AppRadius.superficieBorda,
        border: Border.all(color: AppColors.regua, width: AppStroke.fino),
      ),
      child: column,
    );
  }
}
