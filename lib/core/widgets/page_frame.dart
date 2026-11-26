import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import 'account_actions.dart';
import 'folder_tab.dart';

/// Moldura de ecrã (03-design.md, "Estrutura comum"): fundo `papel`, sem
/// cabeçalho nem marca. A primeira linha é o [FolderTab] ([tabLabel]) a `s16`
/// (compacto) ou `s24` (médio/largo) do topo, com a conta na mesma linha,
/// encostada à direita e centrada com o separador. Por baixo, uma régua à
/// largura da moldura.
///
/// Em largo a moldura (separador, conta, conteúdo, colofão) tem no máximo
/// [AppSize.larguraLista] e fica centrada na janela; dentro dela tudo alinha
/// à esquerda. [maxWidth] limita só a coluna do conteúdo (e de [bottom]).
///
/// O [colophon] é o último elemento do scroll: encosta ao fundo da janela
/// quando o conteúdo é curto e só aparece no fim quando é longo.
class PageFrame extends StatelessWidget {
  /// Espaço da linha do separador por cima dele: (alvo 48 - separador 40) / 2.
  static const double _tabInset =
      (AppSize.alvoMinimo - AppSize.separadorAltura) / 2;

  const PageFrame({
    super.key,
    required this.child,
    this.tabLabel,
    this.trailing,
    this.accountName,
    this.onSignOut,
    this.topAction,
    this.banner,
    this.bottom,
    this.colophon,
    this.maxWidth = AppSize.larguraLista,
    this.scrollable = true,
  });

  final Widget child;

  /// Texto do separador: "Acesso" sem sessão, "Os meus dados", o nome do
  /// escritório, "Administração", "Pedido de acesso". Nulo só no ecrã de
  /// arranque (papel vazio com o colofão no fundo).
  final String? tabLabel;

  /// Bloco da conta na linha do separador. Se [onSignOut] existir, é
  /// substituído por [AccountActions] (nome onde couber + "Sair").
  final Widget? trailing;
  final String? accountName;
  final VoidCallback? onSignOut;

  /// Linha por cima do separador, a `s8` dele (ex.: "Com quem partilho" no
  /// consentimento).
  final Widget? topAction;

  /// Faixa no topo que empurra o conteúdo (ex.: `OfflineBar`).
  final Widget? banner;

  /// Barra fixa em baixo, fora do scroll. O fundo ocupa a largura da janela;
  /// o conteúdo alinha com a coluna do ecrã.
  final Widget? bottom;

  /// `Colophon` do perfil; nulo nas passagens (formulários de ecrã inteiro).
  final Widget? colophon;

  /// Largura máxima da coluna de conteúdo (`larguraFormulario`,
  /// `larguraLeitura` ou `larguraLista`).
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final compact = bp == Breakpoint.compacto;
    final margin = AppBreakpoints.margin(bp);
    final lowHeight = AppBreakpoints.lowHeight(context);

    /// Moldura centrada com margens (no máximo 1040), à largura toda dela.
    Widget framed(Widget inner) => Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.larguraLista),
          child: SizedBox(width: double.infinity, child: inner),
        ),
      ),
    );

    /// Coluna do ecrã: alinhada à esquerda da moldura, até [maxWidth].
    Widget column(Widget inner) => Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: inner,
      ),
    );

    final account = onSignOut != null
        ? AccountActions(name: accountName, onSignOut: onSignOut)
        : trailing;

    final tabRow = LayoutBuilder(
      builder: (context, c) {
        // Compacto: o separador deixa 2 × alvoMinimo para "Sair" (ou s48 sem
        // conta). Médio/largo: separador até 400; a conta usa o resto.
        final double tabMax;
        final double accountMax;
        if (compact) {
          accountMax = 2 * AppSize.alvoMinimo;
          tabMax = c.maxWidth - (account != null ? accountMax : AppSpace.s48);
        } else {
          tabMax = AppSize.larguraFormulario;
          accountMax = c.maxWidth - tabMax - AppSpace.s16;
        }
        // A linha tem a altura do alvo de "Sair" (48), porque um filho fora
        // da caixa do Stack não recebe toques. O separador fica encostado à
        // régua (que se desenha no Stack), com `_tabInset` livres por cima.
        return SizedBox(
          height: AppSize.alvoMinimo,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                top: _tabInset + AppSize.separadorAltura,
                child: const AppRule(),
              ),
              PositionedDirectional(
                start: 0,
                top: _tabInset,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tabMax),
                  child: FolderTab(label: tabLabel!, showRule: false),
                ),
              ),
              if (account != null)
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  height: AppSize.alvoMinimo,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: accountMax),
                    child: Center(widthFactor: 1, child: account),
                  ),
                ),
            ],
          ),
        );
      },
    );

    final head = tabLabel == null
        ? const SizedBox.shrink()
        : framed(
            Padding(
              // Menos `_tabInset`: o separador fica onde estava.
              padding: EdgeInsets.only(
                top:
                    (compact ? AppSpace.s16 : AppSpace.s24) -
                    (topAction == null ? _tabInset : 0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topAction != null) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: topAction,
                    ),
                    const SizedBox(height: AppSpace.s8 - _tabInset),
                  ],
                  tabRow,
                ],
              ),
            ),
          );

    final content = framed(column(child));

    final Widget body;
    if (scrollable) {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [head, content],
            ),
          ),
          if (colophon != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: framed(colophon!),
              ),
            ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          Expanded(child: content),
          if (colophon != null) framed(colophon!),
        ],
      );
    }

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
              child: framed(column(bottom!)),
            ),
          );

    return Material(
      color: AppColors.papel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?banner,
            Expanded(child: body),
            ?bar,
          ],
        ),
      ),
    );
  }
}
