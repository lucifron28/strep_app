import 'package:flutter/material.dart';

class DraculaTheme {
  static const Color background = Color(0xFF282a36);
  static const Color currentLine = Color(0xFF44475a);
  static const Color selection = Color(0xFF44475a);
  static const Color foreground = Color(0xFFf8f8f2);
  static const Color comment = Color(0xFF6272a4);
  static const Color cyan = Color(0xFF8be9fd);
  static const Color green = Color(0xFF50fa7b);
  static const Color orange = Color(0xFFffb86c);
  static const Color pink = Color(0xFFff79c6);
  static const Color purple = Color(0xFFbd93f9);
  static const Color red = Color(0xFFff5555);
  static const Color yellow = Color(0xFFf1fa8c);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: purple,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        iconTheme: IconThemeData(color: foreground),
      ),
      colorScheme: const ColorScheme.dark(
        primary: purple,
        secondary: pink,
        surface: currentLine,
        onPrimary: background,
        onSecondary: background,
        onSurface: foreground,
        error: red,
        onError: foreground,
      ),
      cardTheme: CardThemeData(
        color: currentLine,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: foreground,
        iconColor: purple,
        selectedTileColor: selection,
      ),
      iconTheme: const IconThemeData(
        color: purple,
        size: 24,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: foreground, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: foreground, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: foreground),
        bodyMedium: TextStyle(color: foreground),
        bodySmall: TextStyle(color: comment),
        labelLarge: TextStyle(color: foreground),
        labelMedium: TextStyle(color: foreground),
        labelSmall: TextStyle(color: comment),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: purple,
        inactiveTrackColor: currentLine,
        thumbColor: pink,
        overlayColor: purple.withValues(alpha: 0.2),
        valueIndicatorColor: purple,
        valueIndicatorTextStyle: const TextStyle(color: background),
      ),
    );
  }
}
