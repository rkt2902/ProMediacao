import 'package:flutter/widgets.dart';

/// Cores da app (tema claro). Fonte: docs/design/DESIGN.md.
/// Regra: verde só para "Ativo", ocre só para "Pendente" e avisos,
/// vermelho-lacre só para erro e retirar.
abstract final class AppColors {
  static const Color papel = Color(0xFFF6F3EC);
  static const Color folha = Color(0xFFFDFCF9);
  static const Color cartolina = Color(0xFFEADBB2);
  static const Color realce = Color(0xFFF3E6C4);
  static const Color tinta = Color(0xFF1B1E24);
  static const Color tintaMedia = Color(0xFF454A55);
  static const Color tintaTenue = Color(0xFF62666F);
  static const Color regua = Color(0xFFD8D1C1);
  static const Color reguaForte = Color(0xFF8E8778);
  static const Color foco = Color(0xFF8F6200);
  static const Color estadoAtivo = Color(0xFF2E6A4E);
  static const Color estadoPendente = Color(0xFF7F5600);
  static const Color estadoInativo = tintaTenue;
  static const Color erro = Color(0xFFA3311C);
  static const Color sobreTinta = papel;
  static const Color esqueleto = Color(0xFFECE7DB);

  /// Tinta a 12%: cor das sombras de diálogos e folhas laterais.
  static const Color sombra = Color(0x1F1B1E24);

  /// Tinta a 40%: véu atrás de diálogos e folhas.
  static const Color veu = Color(0x661B1E24);

  /// Sem cor (para animar de/para um fundo).
  static const Color nenhuma = Color(0x00000000);
}

abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s72 = 72;
}

abstract final class AppRadius {
  static const double carimbo = 3;
  static const double controlo = 6;
  static const double superficie = 10;
  static const double separador = 10;

  static const BorderRadius carimboBorda = BorderRadius.all(
    Radius.circular(carimbo),
  );
  static const BorderRadius controloBorda = BorderRadius.all(
    Radius.circular(controlo),
  );
  static const BorderRadius superficieBorda = BorderRadius.all(
    Radius.circular(superficie),
  );

  /// Só os cantos superiores arredondados (separador de pasta).
  static const BorderRadius separadorBorda = BorderRadius.only(
    topLeft: Radius.circular(separador),
    topRight: Radius.circular(separador),
  );

  /// Folha inferior: só os cantos superiores, como a superfície.
  static const BorderRadius folhaInferiorBorda = BorderRadius.only(
    topLeft: Radius.circular(superficie),
    topRight: Radius.circular(superficie),
  );
}

abstract final class AppStroke {
  static const double fino = 1;
  static const double controlo = 1.5;
  static const double foco = 2;

  /// Afastamento do anel de foco (2, ver DESIGN.md).
  static const double focoAfastamento = 2;
}

abstract final class AppSize {
  static const double alvoMinimo = 48;
  static const double alvoPrincipal = 56;
  static const double campo = 52;
  static const double larguraLeitura = 640;
  static const double larguraLista = 1040;
  static const double folhaLateral = 440;
  static const double separadorAltura = 40;

  /// Ícones de interface (resumo do consentimento, spinner).
  static const double icone = 24;

  /// Ícones dentro de carimbos, campos e avisos.
  static const double iconePequeno = 18;

  /// Largura do diálogo de confirmação em médio/largo.
  static const double dialogo = 480;

  /// Coluna de formulários (Entrar, recuperar palavra-passe, link expirado).
  static const double larguraFormulario = 400;

  /// Largura mínima da zona de texto de uma linha antes de empilhar.
  static const double textoMinimo = 240;

  /// Altura mínima de uma linha de tabela.
  static const double linhaTabela = 72;

  /// Colunas fixas das tabelas (Estado, Data, Ação).
  static const double colunaEstado = 140;
  static const double colunaData = 200;
  static const double colunaAcao = 160;
}

enum Breakpoint { compacto, medio, largo }

abstract final class AppBreakpoints {
  /// `compacto` < 640.
  static const double medio = 640;

  /// `largo` > 1100.
  static const double largo = 1100;

  /// Altura da janela abaixo da qual as barras fixas encolhem (telemóvel
  /// deitado).
  static const double alturaBaixa = 480;

  static bool lowHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < alturaBaixa;

  static Breakpoint of(double width) {
    if (width < medio) return Breakpoint.compacto;
    if (width <= largo) return Breakpoint.medio;
    return Breakpoint.largo;
  }

  static Breakpoint fromContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);

  /// Margens laterais: 16 / 32 / 48.
  static double margin(Breakpoint b) => switch (b) {
    Breakpoint.compacto => AppSpace.s16,
    Breakpoint.medio => AppSpace.s32,
    Breakpoint.largo => AppSpace.s48,
  };
}

/// Sombras: nenhuma, exceto diálogos e folhas laterais.
abstract final class AppShadow {
  static const List<BoxShadow> superficie = [
    BoxShadow(color: AppColors.sombra, offset: Offset(0, 8), blurRadius: 24),
  ];
}
