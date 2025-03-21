import 'package:flutter/material.dart';
import 'package:proyecto_jj/core/constants/colors.dart';


class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0});

  ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.backgroundColor,
        error: AppColors.errorColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textColor),
        bodyMedium: TextStyle(color: AppColors.textColor),
      ),
    );
  }
}