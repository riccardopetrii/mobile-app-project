import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

/// Il tema dell'applicazione.
abstract final class VivoTheme {
  static const String fontFamily = 'Poppins';

  /// Il tema usato da tutta l'applicazione.
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: VivoColors.accent,
      onPrimary: VivoColors.onAccent,
      secondary: VivoColors.header,
      onSecondary: VivoColors.onHeader,
      error: VivoColors.danger,
      onError: VivoColors.onHeader,
      surface: VivoColors.card,
      onSurface: VivoColors.ink,
      surfaceContainerHighest: VivoColors.field,
      onSurfaceVariant: VivoColors.muted,
      outline: VivoColors.muted,
    );

    final testi = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: VivoColors.background,
      textTheme: testi,
      splashFactory: InkRipple.splashFactory,

      cardTheme: CardThemeData(
        color: VivoColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VivoColors.accent,
          foregroundColor: VivoColors.onAccent,
          minimumSize: const Size(0, VivoDimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: VivoDimens.xl),
          textStyle: testi.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VivoColors.ink,
          minimumSize: const Size(0, VivoDimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: VivoDimens.xl),
          textStyle: testi.labelLarge,
          side: const BorderSide(color: VivoColors.line),
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VivoColors.header,
          textStyle: testi.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VivoColors.field,
        hintStyle: testi.bodyMedium?.copyWith(color: VivoColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VivoDimens.md,
          vertical: VivoDimens.sm + VivoDimens.xs,
        ),
        border: _campo(VivoColors.line),
        enabledBorder: _campo(VivoColors.line),
        focusedBorder: _campo(VivoColors.header),
        errorBorder: _campo(VivoColors.danger),
        focusedErrorBorder: _campo(VivoColors.danger),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(VivoColors.card),
        trackColor: WidgetStateProperty.resolveWith(
          (stati) => stati.contains(WidgetState.selected)
              ? VivoColors.accent
              : VivoColors.field,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          VivoColors.line,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: VivoColors.line,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: VivoColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
        ),
      ),

      // Il messaggio che compare in fondo alle schermate.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VivoColors.card,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.35,
          color: VivoColors.onCard,
        ),
        // L'ombra di Material è più dura di quella delle card: meglio
        // nessuna, con il bordo a segnare il contorno.
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          VivoDimens.md,
          0,
          VivoDimens.md,
          VivoDimens.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
          side: BorderSide(color: VivoColors.header.withValues(alpha: 0.14)),
        ),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: VivoColors.accent,
        inactiveTrackColor: VivoColors.field,
        thumbColor: VivoColors.ink,
        trackHeight: 16,
      ),
    );
  }

  static OutlineInputBorder _campo(Color colore) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(VivoDimens.radiusField),
    borderSide: BorderSide(color: colore),
  );

  /// La scala tipografica, in punti crescenti senza salti.
  static TextTheme _textTheme() => const TextTheme(
    // Il titolo grande dei numeri, come il "3" della card dei progressi.
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 44,
      height: 1,
      fontWeight: FontWeight.w700,
      color: VivoColors.ink,
    ),
    // Titolo di una schermata dentro l'intestazione.
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: VivoColors.ink,
    ),
    // Titolo di sezione sul fondo crema.
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 19,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: VivoColors.ink,
    ),
    // Titolo di una card.
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: VivoColors.ink,
    ),
    // Testo corrente.
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: VivoColors.ink,
    ),
    // Sottotitoli e note.
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
      color: VivoColors.muted,
    ),
    // Testo dei bottoni.
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    // Etichette della barra di navigazione e delle tabelle.
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: VivoColors.muted,
    ),
    // Sopratitoli maiuscoli, come "MOOD TRACKER".
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.6,
      color: VivoColors.muted,
    ),
  );
}
