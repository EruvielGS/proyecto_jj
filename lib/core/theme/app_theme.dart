import 'package:flutter/material.dart';
import 'package:proyecto_jj/core/constants/colors.dart';

class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0});

  ThemeData theme() {
    // Asegurarse de que el índice esté dentro del rango
    final colorIndex =
        selectedColor.clamp(0, AppColors.plantPalettes.length - 1);
    final primaryColor = AppColors.plantPalettes[colorIndex];

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryColor.withAlpha(51),
        secondary: AppColors.secondaryColor,
        secondaryContainer: AppColors.secondaryLightColor,
        surface: AppColors.backgroundColor,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
      cardTheme: CardTheme(
        color: AppColors.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withAlpha(128)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
        displaySmall:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
        headlineLarge:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600),
        headlineSmall:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600),
        titleLarge:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w500),
        titleSmall:
            TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textColor),
        bodyMedium: TextStyle(color: AppColors.textColor),
        bodySmall: TextStyle(color: AppColors.textLightColor),
      ),
    );
  }
}
