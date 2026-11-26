import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import 'account_actions.dart';
import 'folder_tab.dart';

/// Moldura de ecrã: fundo `papel`, topo com a marca e a conta, separador de
/// pasta, margens por breakpoint (16 / 32 / 48) e largura máxima.
///
/// A moldura (marca, conta, separador, conteúdo) tem no máximo
/// [AppSize.larguraLista] e fica centrada na janela; dentro dela tudo alinha
/// à esquerda. [maxWidth] limita só a coluna do ecrã (separador, conteúdo e
/// [bottom]), que não é centrada.
///
/// Sem AppBar. Tudo o que não é o contexto vai em [child]; uma barra fixa
/// (ex.: Recusar/Aceitar) vai em [bottom] e fica sempre visível.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.tabLabel,
    this.tabs,
    this.brand = 'ProDossier',
    this.trailing,
    this.accountName,
    this.onSignOut,
    this.banner,
    this.bottom,
    this.maxWidth = AppSize.larguraLista,
    this.scrollable = true,
  });

  final Widget child;

  /// Texto do [FolderTab] (ex.: "Os meus dados"). Ignorado se houver [tabs].
  final String? tabLabel;

  /// Alternativa ao [tabLabel]: separadores escolhíveis (ex.: `FolderTabs`).
  final Widget? tabs;

  final String brand;

  /// Menu da conta, à direita da marca.
  final Widget? trailing;

  /// Atalho para a conta por tamanho (ver [AccountActions]); se [onSignOut]
  /// existir, substitui [trailing].
  final String? accountName;
  final VoidCallback? onSignOut;

  /// Faixa no topo que empurra o conteúdo (ex.: `OfflineBar`).
  final Widget? banner;

  /// Barra fixa em baixo, fora do scroll. O fundo ocupa a largura da janela;
  /// o conteúdo alinha com a coluna do ecrã.
  final Widget? bottom;

  /// Largura máxima da coluna de conteúdo (`larguraLista` ou `larguraLeitura`).
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final margin = AppBreakpoints.margin(bp);
    final lowHeight = AppBreakpoints.lowHeight(context);

    /// Moldura centrada com margens; [inner] alinha à esquerda dentro dela.
    Widget framed(Widget inner, {double? columnWidth}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.larguraLista),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: columnWidth == null
                ? inner
                : ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: columnWidth),
                    child: inner,
                  ),
          ),
        ),
      ),
    );

    final account = onSignOut != null
        ? AccountActions(name: accountName, onSignOut: onSignOut)
        : trailing;

    final header = Padding(
      padding: EdgeInsets.only(
        top: bp == Breakpoint.compacto ? AppSpace.s16 : AppSpace.s24,
        bottom: AppSpace.s16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              brand,
              style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
            ),
          ),
          ?account,
        ],
      ),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        framed(header, columnWidth: AppSize.larguraLista),
        framed(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tabs != null)
                tabs!
              else if (tabLabel != null)
                FolderTab(label: tabLabel!),
              child,
            ],
          ),
          columnWidth: maxWidth,
        ),
      ],
    );

    final bar = bottom == null
        ? null
        : DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.folha,
              border: Border(
                top: BorderSide(color: AppColors.regua, width: AppStroke.fino),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: lowHeight ? AppSpace.s8 : AppSpace.s16,
              ),
              child: framed(bottom!, columnWidth: maxWidth),
            ),
          );

    return Material(
      color: AppColors.papel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?banner,
            Expanded(
              child: scrollable ? SingleChildScrollView(child: column) : column,
            ),
            ?bar,
          ],
        ),
      ),
    );
  }
}
