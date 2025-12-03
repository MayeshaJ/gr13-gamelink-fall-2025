import 'package:flutter/material.dart';

/// App color constants for theming
class AppColors {
  // Accent colors
  static const Color neonGreen = Color(0xFF39FF14);  // Bright neon green for dark mode
  static const Color darkGreen = Color(0xFF00C853);   // Darker green for light mode
  
  // Dark Mode Colors
  static const Color darkNavy = Color(0xFF1A2332);
  static const Color darkCard = Color(0xFF243447);
  static const Color darkCardAlt = Color(0xFF1a2a3a);
  
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFE8E8EC);
  static const Color lightBorder = Color(0xFFD1D1D6);
  
  /// Get accent color based on theme (neon green for dark, darker green for light)
  static Color accent(bool isDark) => isDark ? neonGreen : darkGreen;
  
  /// Get background color based on theme
  static Color background(bool isDark) => isDark ? darkNavy : lightBackground;
  
  /// Get card color based on theme
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  
  /// Get alternate card color based on theme  
  static Color cardAlt(bool isDark) => isDark ? darkCardAlt : lightCardAlt;
  
  /// Get text color based on theme
  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black87;
  
  /// Get secondary text color based on theme
  static Color textSecondary(bool isDark) => isDark ? Colors.grey[400]! : Colors.grey[600]!;
  
  /// Get tertiary text color based on theme
  static Color textTertiary(bool isDark) => isDark ? Colors.grey[500]! : Colors.grey[500]!;
  
  /// Get border color based on theme
  static Color border(bool isDark) => isDark 
      ? Colors.white.withOpacity(0.1) 
      : lightBorder;
  
  /// Get divider color based on theme
  static Color divider(bool isDark) => isDark 
      ? Colors.white.withOpacity(0.1) 
      : Colors.grey[300]!;
  
  /// Get icon color based on theme
  static Color icon(bool isDark) => isDark ? Colors.grey[400]! : Colors.grey[600]!;
  
  /// Get app bar background based on theme
  static Color appBar(bool isDark) => isDark ? darkNavy : lightBackground;
  
  /// Get dialog background based on theme
  static Color dialog(bool isDark) => isDark ? darkCard : lightCard;
  
  /// Get disabled color based on theme
  static Color disabled(bool isDark) => isDark ? Colors.grey[700]! : Colors.grey[400]!;
  
  /// Get shadow color for cards
  static Color shadow(bool isDark) => isDark 
      ? neonGreen.withOpacity(0.3) 
      : Colors.black.withOpacity(0.08);
      
  /// Get switch inactive track color
  static Color switchInactiveTrack(bool isDark) => isDark ? Colors.grey[700]! : Colors.grey[300]!;
  
  /// Get button foreground on accent
  static Color onAccent(bool isDark) => Colors.black;
}

/// Theme data builder
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.darkGreen,
      colorScheme: const ColorScheme.light(
        primary: AppColors.darkGreen,
        secondary: AppColors.darkGreen,
        surface: AppColors.lightCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
    );
  }
  
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkNavy,
      primaryColor: AppColors.neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonGreen,
        surface: AppColors.darkCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: Colors.white10,
    );
  }
}
