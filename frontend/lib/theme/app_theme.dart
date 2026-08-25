import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Minimalist Monochrome (Black & White)
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF0D0D0D);
  static const Color bgCard = Color(0xFF141414);
  static const Color bgCardHover = Color(0xFF1F1F1F);
  static const Color borderSubtle = Color(0xFF27272A);
  static const Color borderGlow = Color(0xFF52525B);

  // Monochrome Accents
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cyanAccent = Color(0xFFFFFFFF);     // Mapped to pure white for crisp monochrome
  static const Color purpleAccent = Color(0xFFE4E4E7);   // Soft platinum
  static const Color blueAccent = Color(0xFFFFFFFF);     // Pure white button
  static const Color emeraldGreen = Color(0xFFD4D4D8);   // Silver / Zinc
  static const Color amberWarning = Color(0xFFA1A1AA);   // Medium zinc
  static const Color roseDanger = Color(0xFF71717A);     // Charcoal gray

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: pureWhite,
      colorScheme: const ColorScheme.dark(
        primary: pureWhite,
        secondary: textSecondary,
        surface: bgCard,
        error: textMuted,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: textSecondary),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pureWhite,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          side: const BorderSide(color: borderSubtle, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: pureWhite, width: 1),
        ),
      ),
    );
  }
}
