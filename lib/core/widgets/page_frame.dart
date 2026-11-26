import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import 'folder_tab.dart';

/// Moldura de ecrã: fundo `papel`, topo com a marca e a conta, separador de
/// pasta, margens por breakpoint (16 / 32 / 48) e largura máxima.
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

  /// Faixa no topo que empurra o conteúdo (ex.: `OfflineBar`).
  final Widget? banner;

  /// Barra fixa em baixo, fora do scroll.
  final Widget? bottom;

  /// Largura máxima da coluna de conteúdo (`larguraLista` ou `larguraLeitura`).
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final margin = AppBreakpoints.margin(bp);

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (tabs != null)
          tabs!
        else if (tabLabel != null)
          FolderTab(label: tabLabel!),
        child,
      ],
    );

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: column,
        ),
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
              child: scrollable ? SingleChildScrollView(child: body) : body,
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
