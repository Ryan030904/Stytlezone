import 'package:flutter/material.dart';

// ═══════════════════════════════════════
// SHOP COLORS - ThemeExtension for smooth lerp
// ═══════════════════════════════════════
class ShopColors extends ThemeExtension<ShopColors> {
  final Color card;
  final Color bg;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color headerBg;

  const ShopColors({
    required this.card,
    required this.bg,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.headerBg,
  });

  static const light = ShopColors(
    card: Colors.white,
    bg: Color(0xFFFAFAF5),
    surface: Color(0xFFF1EDE9),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    headerBg: Colors.white,
  );

  static const dark = ShopColors(
    card: Color(0xFF1E293B),
    bg: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF334155),
    headerBg: Color(0xFF1E293B),
  );

  @override
  ShopColors copyWith({
    Color? card, Color? bg, Color? surface,
    Color? textPrimary, Color? textSecondary,
    Color? border, Color? headerBg,
  }) {
    return ShopColors(
      card: card ?? this.card,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      headerBg: headerBg ?? this.headerBg,
    );
  }

  @override
  ShopColors lerp(ShopColors? other, double t) {
    if (other is! ShopColors) return this;
    return ShopColors(
      card: Color.lerp(card, other.card, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
    );
  }
}

// ═══════════════════════════════════════
// SHOP THEME
// ═══════════════════════════════════════
class ShopTheme {
  // Brand colors
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryPurpleLight = Color(0xFF9F67FF);
  static const Color primaryPurpleDark = Color(0xFF5B21B6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color saleRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color starYellow = Color(0xFFFBBF24);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
  );
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
  );
  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFEC4899)],
  );
  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E1036), Color(0xFF2D1B69), Color(0xFF4C1D95)],
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacing3XL = 64.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  static const double maxContentWidth = 1320.0;
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1200.0;

  // Responsive helpers
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Quick access to ShopColors extension (smooth lerp)
  static ShopColors colors(BuildContext context) =>
      Theme.of(context).extension<ShopColors>() ?? ShopColors.light;

  // Card shadows
  static List<BoxShadow> cardShadow(BuildContext context) =>
      isDark(context) ? [] : [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> cardHoverShadow(BuildContext context) =>
      isDark(context)
          ? [BoxShadow(color: primaryPurple.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]
          : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))];

  // ═══════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: const Color(0xFFFAFAF5),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple, brightness: Brightness.light,
        surface: const Color(0xFFFAFAF5), primary: primaryPurple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, elevation: 0,
        scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLG)),
      ),
      textTheme: _textTheme(const Color(0xFF1A1A2E), const Color(0xFF64748B)),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(const Color(0xFF1A1A2E)),
      inputDecorationTheme: _inputDecoration(Colors.white, const Color(0xFFE2E8F0), const Color(0xFF94A3B8)),
      extensions: const [ShopColors.light],
    );
  }

  // ═══════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple, brightness: Brightness.dark,
        surface: const Color(0xFF0F172A), primary: primaryPurpleLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B), elevation: 0,
        scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B), elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      textTheme: _textTheme(const Color(0xFFF1F5F9), const Color(0xFF94A3B8)),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(Colors.white),
      inputDecorationTheme: _inputDecoration(const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF64748B)),
      extensions: const [ShopColors.dark],
    );
  }

  // ═══════════════════════════════════════
  // SHARED BUILDERS
  // ═══════════════════════════════════════
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: primary, height: 1.1),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: primary, height: 1.2),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary, height: 1.3),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: secondary, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.5),
    );
  }

  static ElevatedButtonThemeData _elevatedButton() {
    return ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: primaryPurple, foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      elevation: 0,
    ));
  }

  static OutlinedButtonThemeData _outlinedButton(Color fg) {
    return OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
      side: BorderSide(color: fg.withValues(alpha: 0.3), width: 1.5),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    ));
  }

  static InputDecorationTheme _inputDecoration(Color fill, Color border, Color hint) {
    return InputDecorationTheme(
      filled: true, fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusFull), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusFull), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusFull), borderSide: const BorderSide(color: primaryPurple, width: 2)),
      hintStyle: TextStyle(fontSize: 14, color: hint),
    );
  }
}
