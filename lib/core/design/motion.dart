import 'package:flutter/widgets.dart';

/// Motion spec (docs/design/DESIGN.md). Com "reduzir movimento"
/// (`MediaQuery.disableAnimations`) todas as durações passam a 0: usar
/// sempre [AppMotion.resolve] ao aplicar uma duração num widget.
abstract final class AppMotion {
  /// Hover, pressão, foco, troca de texto num botão.
  static const Duration rapido = Duration(milliseconds: 120);

  /// Mudança de carimbo, aparecer/desaparecer de faixas e mensagens.
  static const Duration base = Duration(milliseconds: 200);

  /// Folha lateral/inferior a entrar, linha a mudar de grupo.
  static const Duration lento = Duration(milliseconds: 320);

  /// Desvanecer do fundo `realce` de uma linha acabada de alterar.
  static const Duration realce = Duration(milliseconds: 1600);

  /// Opacidade do skeleton, ida e volta (nunca shimmer).
  static const Duration pulsar = Duration(milliseconds: 1200);

  /// Opacidade mínima do skeleton (a máxima é 1.0).
  static const double pulsarMinimo = 0.55;

  /// Escala inicial do diálogo de confirmação (0.98 a 1.0).
  static const double escalaDialogo = 0.98;

  /// Tudo o que aparece.
  static const Curve entrar = Curves.easeOutCubic;

  /// Tudo o que sai.
  static const Curve sair = Curves.easeInCubic;

  /// Mudanças de estado e de posição.
  static const Curve mudar = Curves.easeInOutCubic;

  /// Devolve [d], ou [Duration.zero] se o sistema pede menos movimento.
  static Duration resolve(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
