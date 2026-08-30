import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the app themes from [AppTokens]. Dark is the default (sunlight +
/// OLED discipline): border-based elevation, medium/semibold weight skew.
abstract final class AppTheme {
  static const _fontFallback = <String>['Inter', 'Noto Sans Bengali'];

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        canvas: AppTokens.darkCanvas,
        surface: AppTokens.darkSurface,
        border: AppTokens.darkBorder,
        textPrimary: AppTokens.darkTextPrimary,
        textSecondary: AppTokens.darkTextSecondary,
        primary: AppTokens.darkPrimary,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        canvas: AppTokens.lightCanvas,
        surface: AppTokens.lightSurface,
        border: AppTokens.lightBorder,
        textPrimary: AppTokens.lightTextPrimary,
        textSecondary: AppTokens.lightTextSecondary,
        primary: AppTokens.lightPrimary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppTokens.offerAccent,
      onSecondary: Colors.black,
      error: AppTokens.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surface,
      outline: border,
      outlineVariant: border,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamilyFallback: _fontFallback,
    );
    TextStyle txt(Color c, double size, [FontWeight w = FontWeight.w500]) =>
        base.textTheme.bodyMedium!.copyWith(
            color: c, fontSize: size, fontWeight: w, fontFamilyFallback: _fontFallback);

    return base.copyWith(
      textTheme: TextTheme(
        bodyLarge: txt(textPrimary, AppTokens.bodySize),
        bodyMedium: txt(textPrimary, AppTokens.bodySize),
        bodySmall: txt(textSecondary, AppTokens.bodySmallSize),
        titleLarge: txt(textPrimary, 22, FontWeight.w600),
        titleMedium: txt(textPrimary, AppTokens.bodySize, FontWeight.w600),
        labelLarge: txt(textPrimary, AppTokens.bodySize, FontWeight.w600),
        labelMedium: txt(textSecondary, AppTokens.bodySmallSize),
      ),
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: txt(textPrimary, 20, FontWeight.w600),
        shape: Border(
            bottom: BorderSide(color: border, width: AppTokens.borderStroke)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: AppTokens.borderStroke),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: canvas,
        indicatorColor: primary.withValues(alpha: 0.18),
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
            txt(textPrimary, 13, FontWeight.w600)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.ctaBackground,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppTokens.primaryActionHeight),
          textStyle: txt(Colors.white, 18, FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(AppTokens.secondaryActionHeight),
          side: BorderSide(color: border, width: AppTokens.borderStroke),
          textStyle: txt(textPrimary, 16, FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: txt(textSecondary, AppTokens.bodySize),
        labelStyle: txt(textSecondary, AppTokens.bodySize),
        contentPadding:
            EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.l),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: AppTokens.borderStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppTokens.danger, width: AppTokens.borderStroke),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: txt(textPrimary, AppTokens.bodySize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: AppTokens.borderStroke),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppTokens.ctaBackground),
    );
  }
}
