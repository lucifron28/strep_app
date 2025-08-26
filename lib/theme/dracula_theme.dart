import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF1e1f2e)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [currentLine, Color(0xFF3a3d4d)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: purple,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter', // Modern font
      
      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(
          color: purple,
          size: 24,
        ),
        titleTextStyle: const TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: const TextStyle(color: foreground),
      ),
      
      // Enhanced color scheme
      colorScheme: ColorScheme.dark(
        primary: purple,
        secondary: pink,
        tertiary: cyan,
        surface: currentLine,
        surfaceContainer: currentLine,
        surfaceContainerHighest: selection,
        onPrimary: background,
        onSecondary: background,
        onSurface: foreground,
        onSurfaceVariant: comment,
        error: red,
        onError: foreground,
        outline: comment,
        shadow: Colors.black.withValues(alpha: 0.5),
      ),
      
      // Enhanced card theme
      cardTheme: CardThemeData(
        color: currentLine,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: purple.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Enhanced list tile theme
      listTileTheme: ListTileThemeData(
        textColor: foreground,
        iconColor: purple,
        selectedTileColor: selection,
        selectedColor: pink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      // Enhanced icon theme
      iconTheme: const IconThemeData(
        color: purple,
        size: 24,
      ),
      
      // Enhanced text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: foreground, 
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: foreground,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: foreground,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: comment,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
        labelMedium: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
        labelSmall: TextStyle(
          color: comment,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
      ),
      
      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: background,
          shadowColor: purple.withValues(alpha: 0.5),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: BorderSide(color: purple.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Enhanced slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: purple,
        inactiveTrackColor: currentLine,
        thumbColor: pink,
        overlayColor: purple.withValues(alpha: 0.2),
        valueIndicatorColor: purple,
        valueIndicatorTextStyle: const TextStyle(
          color: background,
          fontWeight: FontWeight.w600,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      
      // Enhanced bottom navigation theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: purple,
        unselectedItemColor: comment,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Enhanced floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: pink,
        foregroundColor: background,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: currentLine,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: purple.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: foreground,
          fontSize: 16,
        ),
      ),
      
      // Enhanced snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: currentLine,
        contentTextStyle: const TextStyle(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: currentLine,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: comment.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: comment.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red, width: 2),
        ),
        labelStyle: const TextStyle(color: comment),
        hintStyle: const TextStyle(color: comment),
        prefixIconColor: purple,
        suffixIconColor: purple,
      ),
      
      // Enhanced switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return pink;
          }
          return comment;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purple.withValues(alpha: 0.5);
          }
          return currentLine;
        }),
      ),
      
      // Enhanced checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purple;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(background),
        side: const BorderSide(color: comment, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Enhanced radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purple;
          }
          return comment;
        }),
      ),
      
      // Enhanced divider theme
      dividerTheme: DividerThemeData(
        color: comment.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
