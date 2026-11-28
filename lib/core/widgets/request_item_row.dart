import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_buttons.dart';

/// Natureza de um item de pedido.
enum RequestItemKind {
  /// Documento a enviar ("Documento", `description_outlined`).
  documento('Documento', Icons.description_outlined),

  /// Dado a preencher ("Dado", `edit_note`).
  dado('Dado', Icons.edit_note);

  const RequestItemKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Ação opcional de uma linha (só no modo editável do Novo pedido).
enum RequestItemAction {
  /// "Tirar" (ícone `close`).
  tirar('Tirar', Icons.close),

  /// "Repor" (ícone `undo`).
  repor('Repor', Icons.undo);

  const RequestItemAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Linha de um item de pedido (002): natureza (`colunaNatureza` 120, ícone +
/// palavra) + texto + ação opcional. Sem réguas próprias: vai dentro de uma
/// `RuledList`. Passa a empilhado (natureza por cima do texto, ação à
/// direita centrada) em compacto ou quando o texto ficaria abaixo de
/// `textoMinimo`.
///
/// - [free]: item acrescentado pelo mediador neste pedido ("item livre");
///   mostra "Acrescentado neste pedido" por baixo do texto.
/// - [action] + [onAction]: ação "Tirar"/"Repor"; sem [onAction] não há ação.
/// - [contextLabel]: complemento para leitura de ecrã da ação, ex.:
///   "do pedido de Automóvel" -> "Tirar Morada do pedido de Automóvel".
/// - [highlight]: fundo `realce` que desvanece (item acabado de acrescentar
///   ou lista reposta).
/// - Semântica: a linha lê-se uma só vez ("Documento: Morada"); a ação é um
///   botão separado.
class RequestItemRow extends StatelessWidget {
  const RequestItemRow({
    super.key,
    required this.kind,
    required this.text,
    this.free = false,
    this.action = RequestItemAction.tirar,
    this.onAction,
    this.contextLabel,
    this.highlight = false,
  });

  final RequestItemKind kind;
  final String text;
  final bool free;
  final RequestItemAction action;
  final VoidCallback? onAction;
  final String? contextLabel;
  final bool highlight;

  static const String freeNote = 'Acrescentado neste pedido';

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final hasAction = onAction != null;

    final nature = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            kind.icon,
            size: AppSize.iconePequeno,
            color: AppColors.tintaMedia,
          ),
          const SizedBox(width: AppSpace.s4),
          Text(
            kind.label,
            style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
          ),
        ],
      ),
    );
    // O corpo carrega o rótulo único da linha (natureza + texto + nota); a
    // natureza visual fica excluída e o botão é um nó à parte.
    final body = Semantics(
      container: true,
      label: '${kind.label}: $text${free ? '. $freeNote' : ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppType.corpo),
          if (free)
            Text(
              freeNote,
              style: AppType.registo.copyWith(color: AppColors.tintaMedia),
            ),
        ],
      ),
    );
    final button = hasAction
        ? TextAction(
            label: action.label,
            icon: action.icon,
            onPressed: onAction,
            semanticsLabel: contextLabel == null
                ? '${action.label} $text'
                : '${action.label} $text $contextLabel',
          )
        : null;

    return LayoutBuilder(
      builder: (context, c) {
        final actionWidth = hasAction ? AppSize.colunaAcao : 0.0;
        final stacked =
            compact ||
            c.maxWidth <
                AppSize.colunaNatureza +
                    AppSpace.s16 +
                    AppSize.textoMinimo +
                    actionWidth;
        final Widget content;
        // Com texto muito ampliado a ação desce para baixo do texto (à
        // direita) em vez de apertar a natureza.
        final large = MediaQuery.textScalerOf(context).scale(10) > 11.5;
        if (stacked && large && button != null) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nature,
              const SizedBox(height: AppSpace.s4),
              body,
              Align(alignment: AlignmentDirectional.centerEnd, child: button),
            ],
          );
        } else if (stacked) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nature,
                    const SizedBox(height: AppSpace.s4),
                    body,
                  ],
                ),
              ),
              if (button != null) ...[
                const SizedBox(width: AppSpace.s8),
                button,
              ],
            ],
          );
        } else {
          // Com ação, a natureza e o texto alinham pelo topo (1.ª linha) e a
          // linha tem `s4` de padding: o alvo de 48 já dá o ar. O texto desce
          // `s8` para ficar a meio do alvo quando é de uma linha só.
          final textInset = hasAction ? AppSpace.s8 : 0.0;
          content = Row(
            crossAxisAlignment: hasAction
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSize.colunaNatureza,
                ),
                child: Padding(
                  // +3: o centro da natureza (20) com o da 1.ª linha (26).
                  padding: EdgeInsets.only(
                    top: textInset + (hasAction ? 3 : 0),
                    bottom: textInset,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: nature,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: textInset),
                  child: body,
                ),
              ),
              if (button != null) ...[
                const SizedBox(width: AppSpace.s16),
                // Centrado na 1.ª linha do texto (26), não no alvo de 48.
                Transform.translate(
                  offset: const Offset(0, -(AppSize.alvoMinimo - 26) / 2 + 8),
                  child: button,
                ),
              ],
            ],
          );
        }

        Widget row = Padding(
          // Com ação o alvo de 48 dá o ar (`s4`); sem ação, `s12`.
          padding: EdgeInsets.symmetric(
            vertical: hasAction ? AppSpace.s4 : AppSpace.s12,
          ),
          child: content,
        );
        if (highlight) {
          row = TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: AppColors.realce, end: AppColors.nenhuma),
            duration: AppMotion.resolve(context, AppMotion.realce),
            curve: AppMotion.mudar,
            builder: (context, color, child) =>
                ColoredBox(color: color ?? AppColors.nenhuma, child: child),
            child: row,
          );
        }
        return row;
      },
    );
  }
}
