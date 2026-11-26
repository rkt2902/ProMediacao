import 'package:material_ui/material_ui.dart';

import 'tokens.dart';
import 'typography.dart';

/// Tema da app, construído só a partir dos tokens. Material 3 é o motor
/// (semântica, foco, acessibilidade), nunca o aspeto.
abstract final class AppTheme {
  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.tinta,
    onPrimary: AppColors.sobreTinta,
    secondary: AppColors.tintaMedia,
    onSecondary: AppColors.sobreTinta,
    error: AppColors.erro,
    onError: AppColors.sobreTinta,
    surface: AppColors.papel,
    onSurface: AppColors.tinta,
    onSurfaceVariant: AppColors.tintaMedia,
    outline: AppColors.reguaForte,
    outlineVariant: AppColors.regua,
    shadow: AppColors.sombra,
    scrim: AppColors.veu,
    surfaceTint: AppColors.nenhuma,
    surfaceContainerLowest: AppColors.folha,
    surfaceContainerLow: AppColors.papel,
    surfaceContainer: AppColors.papel,
    surfaceContainerHigh: AppColors.folha,
    surfaceContainerHighest: AppColors.folha,
  );

  static final TextTheme _textTheme = TextTheme(
    displayLarge: AppType.numero,
    displayMedium: AppType.titulo,
    displaySmall: AppType.tituloCompacto,
    headlineLarge: AppType.titulo,
    headlineMedium: AppType.tituloCompacto,
    headlineSmall: AppType.subtitulo,
    titleLarge: AppType.subtitulo,
    titleMedium: AppType.corpoForte,
    titleSmall: AppType.rotulo,
    bodyLarge: AppType.corpo,
    bodyMedium: AppType.corpo,
    bodySmall: AppType.corpoPequeno,
    labelLarge: AppType.botao,
    labelMedium: AppType.rotulo,
    labelSmall: AppType.registo,
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.papel,
      canvasColor: AppColors.papel,
      fontFamily: AppType.sans,
      fontFamilyFallback: const ['Roboto', 'Arial'],
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.nenhuma,
      hoverColor: AppColors.nenhuma,
      focusColor: AppColors.nenhuma,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: AppColors.regua,
      dividerTheme: const DividerThemeData(
        color: AppColors.regua,
        thickness: AppStroke.fino,
        space: AppStroke.fino,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.tinta,
        size: AppSize.icone,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.tinta,
        strokeWidth: AppStroke.controlo,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.tinta,
        selectionColor: AppColors.cartolina,
        selectionHandleColor: AppColors.tinta,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.folha,
        isDense: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.controloBorda,
          borderSide: BorderSide(
            color: AppColors.reguaForte,
            width: AppStroke.controlo,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.controloBorda,
          borderSide: BorderSide(
            color: AppColors.regua,
            width: AppStroke.controlo,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.controloBorda,
          borderSide: BorderSide(color: AppColors.foco, width: AppStroke.foco),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.controloBorda,
          borderSide: BorderSide(
            color: AppColors.erro,
            width: AppStroke.controlo,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.controloBorda,
          borderSide: BorderSide(color: AppColors.erro, width: AppStroke.foco),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.folha,
        surfaceTintColor: AppColors.nenhuma,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.superficieBorda),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.folha,
        surfaceTintColor: AppColors.nenhuma,
        modalBackgroundColor: AppColors.folha,
        modalBarrierColor: AppColors.veu,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.folhaInferiorBorda,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.tinta,
          borderRadius: AppRadius.controloBorda,
        ),
        textStyle: AppType.corpoPequeno.copyWith(color: AppColors.sobreTinta),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s8,
        ),
      ),
    );
  }
}
