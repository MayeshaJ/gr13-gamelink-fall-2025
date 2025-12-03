import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Controller using ChangeNotifier pattern for app-wide theme management
class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  
  static final ThemeController instance = ThemeController._internal();
  
  static const String _themeKey = 'app_theme_mode';
  
  bool _isDarkMode = true; // Default to dark mode
  bool _isInitialized = false;
  
  bool get isDarkMode => _isDarkMode;
  bool get isLightMode => !_isDarkMode;
  
  /// Initialize theme from stored preference
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default to dark
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If preferences fail, use default (dark mode)
      _isDarkMode = true;
      _isInitialized = true;
    }
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Ignore storage errors, theme still works in memory
    }
  }
  
  /// Set theme mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    _isDarkMode = isDark;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Ignore storage errors
    }
  }
}

