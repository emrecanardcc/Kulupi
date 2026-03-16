import 'package:flutter/material.dart';

class ModernTheme {
  // Ana renk paleti
  static const Color primaryCyan = Color(0xFF00FFFF);
  static const Color secondaryBlue = Color(0xFF0080FF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Arka plan renkleri
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF2A2A2A);

  // Metin renkleri
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Glass efekt renkleri
  static const Color glassWhite = Color(0x20FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassHighlight = Color(0x10FFFFFF);

  // Gradient paletleri
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCyan, secondaryBlue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, secondaryBlue],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), successGreen],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCD34D), warningOrange],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), errorRed],
  );

  // Modern metin stilleri
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: 0.5,
  );

  // Modern buton stilleri
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryCyan,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: button,
  ).copyWith(
    overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
  );

  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primaryCyan,
    side: const BorderSide(color: primaryCyan, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: button.copyWith(color: primaryCyan),
  );

  static ButtonStyle glassButton = ElevatedButton.styleFrom(
    backgroundColor: glassWhite,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: glassBorder, width: 1),
    ),
    elevation: 0,
    textStyle: body2.copyWith(fontWeight: FontWeight.w600),
  ).copyWith(
    overlayColor: WidgetStateProperty.all(glassHighlight),
  );

  // Modern input decoration
  static InputDecoration modernInputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: body2.copyWith(color: textMuted),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textSecondary) : null,
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryCyan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // Glass morphism box decoration
  static BoxDecoration glassDecoration({
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: opacity),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Modern card decoration
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      color: color ?? cardDark,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -5,
        ),
      ],
    );
  }

  // --- THEME DATA FACTORIES ---

  // Koyu Mod (Mevcut Midnight Aura)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryCyan,
      canvasColor: surfaceDark, // BottomSheet vb. için
      cardColor: cardDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryBlue,
        tertiary: accentPurple,
        surface: surfaceDark,
        error: errorRed,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: heading3,
      ),
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: subtitle1,
        headlineSmall: subtitle2,
        bodyLarge: body1,
        bodyMedium: body2,
        labelSmall: caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton),
      inputDecorationTheme: _buildInputTheme(isDark: true),
    );
  }

  // Açık Mod (Yenilenmiş Modern Light Design)
  static ThemeData get lightTheme {
    // --- MODERN LIGHT PALETTE ---
    const Color bgLight = Color(0xFFFAFAFA); // Çok açık gri/beyaz (Ana arka plan)
    const Color surfaceLight = Color(0xFFFFFFFF); // Kartlar için tam beyaz
    const Color cardLight = Color(0xFFFFFFFF); 
    
    // Brand Colors
    const Color brandCyan = Color(0xFF00B8D4); // Biraz daha koyu ve okunur bir cyan
    
    // Text Colors
    const Color textPrimary = Colors.black; // Tam siyah (Kullanıcı isteği: Kalın siyah)
    const Color textSecondary = Color(0xFF374151); // Koyu gri (Gray 700)
    const Color textMuted = Color(0xFF6B7280); // Orta gri (Gray 500)

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: brandCyan,
      canvasColor: surfaceLight,
      cardColor: cardLight,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: brandCyan,
        secondary: brandCyan,
        tertiary: Color(0xFF7C3AED), // Violet 600
        surface: cardLight,
        error: Color(0xFFDC2626), // Red 600
        onSurface: textPrimary,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 22, // Biraz daha büyük
          fontWeight: FontWeight.w900, // En kalın
          color: Colors.black, // Tam siyah
          letterSpacing: -0.5,
          fontFamily: 'Inter',
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -1.0),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.8),
        displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textSecondary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary, height: 1.5),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB), // Gray 200
        thickness: 1,
        space: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFF3F4F6), // Gray 100
        selectedColor: brandCyan.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: brandCyan, fontWeight: FontWeight.w700),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandCyan,
          foregroundColor: Colors.black, // Cyan üzerinde siyah
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandCyan,
          side: const BorderSide(color: brandCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(isDark: false),
    );
  }

  static InputDecorationTheme _buildInputTheme({required bool isDark}) {
    final borderColor = isDark ? glassBorder : const Color(0xFFCBD5E1); // Slate 300
    final fillColor = isDark ? surfaceDark : const Color(0xFFE2E8F0); // Slate 200
    final hintColor = isDark ? textMuted : const Color(0xFF64748B); // Slate 500

    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? primaryCyan : const Color(0xFF00E5FF), width: 2),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
    );
  }
}
