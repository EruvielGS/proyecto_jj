import 'package:flutter/material.dart';
import 'package:proyecto_jj/core/constants/colors.dart';
import 'package:proyecto_jj/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  int _selectedColorIndex = 0;
  
  int get selectedColorIndex => _selectedColorIndex;
  
  ThemeData get theme => AppTheme(selectedColor: _selectedColorIndex).theme();
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedColorIndex = prefs.getInt('theme_color_index') ?? 0;
    notifyListeners();
  }
  
  Future<void> setTheme(int colorIndex) async {
    _selectedColorIndex = colorIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color_index', colorIndex);
    notifyListeners();
  }
  
  List<Color> get availableColors => AppColors.plantPalettes;
  
  List<String> get themeNames => [
    'Verde Naturaleza',
    'Verde Agua',
    'Lima',
    'Marrón',
    'Índigo',
  ];
}

