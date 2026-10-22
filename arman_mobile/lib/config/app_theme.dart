import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1120);
  static const Color surface = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color statusGreen = Color(0xFF10B981);
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusRed = Color(0xFFEF4444);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textDim = Color(0xFF94A3B8);

  static const TextStyle tabularNumbers = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: electricBlue,
        surface: surface,
        error: statusRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textMain,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textMain,
        elevation: 0,
        centerTitle: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryCyan,
        inactiveTrackColor: border,
        thumbColor: electricBlue,
        overlayColor: primaryCyan.withValues(alpha: 0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
