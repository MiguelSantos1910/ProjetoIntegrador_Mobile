import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

abstract class AppTheme {
  static ThemeData appTheme = ThemeData.light().copyWith(
    // ============================================================
    // MATERIAL 3
    // ============================================================

    useMaterial3: true,

    // ============================================================
    // FUNDO
    // ============================================================
    scaffoldBackgroundColor: AppColors.backgroundColor,

    // ============================================================
    // COLOR SCHEME
    // ============================================================
    colorScheme: const ColorScheme.light(
      primary: AppColors.mainColor,

      onPrimary: Colors.white,

      secondary: AppColors.mainColorDark,

      onSecondary: Colors.white,

      surface: AppColors.backgroundCards,

      onSurface: AppColors.textPrimary,

      error: AppColors.error,

      onError: Colors.white,
    ),

    // ============================================================
    // APP BAR
    // ============================================================
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundCards,

      foregroundColor: AppColors.textPrimary,

      elevation: 0,

      surfaceTintColor: Colors.transparent,

      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,

        fontSize: 18,

        fontWeight: FontWeight.w700,
      ),
    ),

    // ============================================================
    // ELEVATED BUTTON
    // ============================================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.lightBackgroundColor;
          }

          if (states.contains(WidgetState.pressed)) {
            return AppColors.mainColorDark;
          }

          if (states.contains(WidgetState.hovered)) {
            return AppColors.mainColorDark;
          }

          return AppColors.mainColor;
        }),

        foregroundColor: const WidgetStatePropertyAll(Colors.white),

        elevation: const WidgetStatePropertyAll(0),

        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),

        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    ),

    // ============================================================
    // CARD
    // ============================================================
    cardTheme: CardThemeData(
      color: AppColors.backgroundCards,

      elevation: 0,

      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),

        side: const BorderSide(color: AppColors.borderColor),
      ),

      margin: EdgeInsets.zero,
    ),

    // ============================================================
    // INPUT
    // ============================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: AppColors.backgroundCards,

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),

        borderSide: const BorderSide(color: AppColors.borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),

        borderSide: const BorderSide(color: AppColors.borderColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),

        borderSide: const BorderSide(color: AppColors.mainColor),
      ),

      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),

    // ============================================================
    // DIVIDER
    // ============================================================
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,

      thickness: 1,

      space: 1,
    ),
  );
}
