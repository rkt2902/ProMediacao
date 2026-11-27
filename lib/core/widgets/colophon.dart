import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'folder_tab.dart';
import 'wordmark.dart';

/// Colofão: o fim de cada página (DESIGN.md e 03-design.md, "Colofão").
///
/// Régua `regua` à largura da moldura, e por baixo o [Wordmark], a linha de
/// identidade ([identity], `corpoPequeno` `tintaMedia`) e o registo
/// ([record], `registo` `tintaTenue`, opcional). Numa linha alinhada pela
/// base em médio/largo; empilhado com `s4` em compacto ou quando a linha não
/// cabe (escala de texto, nome longo). Nada focável; sem ícones nem ligações.
///
/// Enquanto o perfil não chega ([identity] nulo), mostra só o wordmark; a
/// linha entra depois em `base` / `entrar` (opacidade). O `PageFrame`
/// desenha-o como último elemento do scroll.
class Colophon extends StatefulWidget {
  const Colophon({super.key, this.identity, this.record});

  /// Frase dos ecrãs sem sessão.
  static const String signedOutLine =
      'O dossiê dos seus seguros, partilhado só com quem autorizar.';

  /// Frase do admin (sem nome nem registo).
  static const String adminLine = 'Administração da plataforma';

  /// Colofão sem sessão (Entrar, Recuperar, Definir, Link expirado).
  const Colophon.signedOut({super.key})
    : identity = signedOutLine,
      record = null;

  final String? identity;
  final String? record;

  @override
  State<Colophon> createState() => _ColophonState();
}

class _ColophonState extends State<Colophon> {
  /// A linha só se anima se chegou depois (perfil a carregar).
  late final bool _identityAtStart;

  @override
  void initState() {
    super.initState();
    _identityAtStart = widget.identity != null;
  }

  double _width(String text, TextStyle style, TextScaler scaler) {
    final p = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  Widget _fade(Widget child) {
    if (_identityAtStart) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.resolve(context, AppMotion.base),
      curve: AppMotion.entrar,
      builder: (context, t, c) => Opacity(opacity: t, child: c),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.fromContext(context);
    final compact = bp == Breakpoint.compacto;
    final identityStyle = AppType.corpoPequeno.copyWith(
      color: AppColors.tintaMedia,
    );
    final recordStyle = AppType.registo.copyWith(color: AppColors.tintaTenue);
    final identity = widget.identity;
    final record = widget.record;

    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: compact ? AppSpace.s48 : AppSpace.s72,
          bottom: compact ? AppSpace.s24 : AppSpace.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppRule(),
            const SizedBox(height: AppSpace.s16),
            Builder(
              builder: (context) {
                // Sem LayoutBuilder: o `PageFrame` mede o colofão por
                // intrínsecos (SliverFillRemaining). A largura é a da moldura.
                final window = MediaQuery.sizeOf(context).width;
                final available = (window - 2 * AppBreakpoints.margin(bp))
                    .clamp(0.0, AppSize.larguraLista);
                final scaler = MediaQuery.textScalerOf(context);
                var oneLine = !compact;
                if (oneLine) {
                  var total =
                      _width('Pro', AppType.marcaPro, scaler) +
                      _width('Dossier', AppType.marca, scaler);
                  if (identity != null) {
                    total +=
                        AppSpace.s16 + _width(identity, identityStyle, scaler);
                  }
                  if (record != null) {
                    total += AppSpace.s16 + _width(record, recordStyle, scaler);
                  }
                  oneLine = total <= available;
                }

                final identityText = identity == null
                    ? null
                    : _fade(Text(identity, style: identityStyle));
                final recordText = record == null
                    ? null
                    : _fade(Text(record, style: recordStyle));

                if (oneLine) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Wordmark(),
                      if (identityText != null) ...[
                        const SizedBox(width: AppSpace.s16),
                        identityText,
                      ],
                      if (recordText != null) ...[
                        const SizedBox(width: AppSpace.s16),
                        recordText,
                      ],
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Wordmark(),
                    if (identityText != null) ...[
                      const SizedBox(height: AppSpace.s4),
                      identityText,
                    ],
                    if (recordText != null) ...[
                      const SizedBox(height: AppSpace.s4),
                      recordText,
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
