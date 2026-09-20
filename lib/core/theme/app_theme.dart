import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// ThemeData du projet — light ET dark, tous deux construits depuis
/// `AppColors.paletteFor(...)`, jamais depuis l'état mutable courant
/// de `AppColors` (voir la note dans `app_colors.dart`).
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final palette = AppColors.paletteFor(brightness);
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.primary,
              surface: palette.surface,
              error: AppColors.danger,
              onPrimary: Colors.white,
              onSurface: palette.textPrimary,
            )
          : ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.primary,
              surface: palette.surface,
              error: AppColors.danger,
              onPrimary: Colors.white,
              onSurface: palette.textPrimary,
            ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: palette.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: palette.textPrimary),
        headlineSmall: AppTypography.headline.copyWith(color: palette.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: palette.textTertiary),
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label.copyWith(color: palette.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: palette.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.surfaceElevated,
          disabledForegroundColor: palette.textTertiary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          textStyle: AppTypography.button,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
        labelStyle: AppTypography.label.copyWith(color: palette.textSecondary),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  const AppTheme._();
}
