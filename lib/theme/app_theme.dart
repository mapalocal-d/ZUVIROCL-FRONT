import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =========================================================
  // PALETA DE COLORES ZUVIRO
  // =========================================================

  static const Color background = Colors.black;
  static const Color surface = Color(0xFF181818);
  static const Color surfaceLight = Color(0xFF222222);
  static const Color primary = Color(0xFF10B981);
  static const Color secondary = Color(0xFF34D399);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFBBF24);
  static const Color success = Color(0xFF10B981);
  static const Color textMain = Colors.white;
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color textHint = Color(0xFF555555);
  static const Color divider = Color(0xFF2A2A2A);

  // =========================================================
  // CONSTANTES DE DISEÑO (DRY)
  // =========================================================

  static final BorderRadius _inputRadius = BorderRadius.circular(16);
  static final BorderRadius _buttonRadius = BorderRadius.circular(18);
  static final BorderRadius _cardRadius = BorderRadius.circular(16);
  static final BorderRadius _dialogRadius = BorderRadius.circular(20);
  static final BorderRadius _snackBarRadius = BorderRadius.circular(12);

  static const double _buttonHeight = 56.0;
  static const double _inputHorizontalPadding = 20.0;
  static const double _inputVerticalPadding = 18.0;

  // =========================================================
  // TEMA OSCURO PRINCIPAL
  // =========================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      dividerColor: divider,

      // --- COLOR SCHEME ---
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      // --- APP BAR ---
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textMain,
          letterSpacing: 1.2,
        ),
      ),

      // --- TIPOGRAFÍA ---
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          color: textMain,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        titleLarge: GoogleFonts.montserrat(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.montserrat(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: const TextStyle(color: textMain, fontSize: 16),
        bodyMedium: const TextStyle(color: textMuted, fontSize: 14),
        bodySmall: const TextStyle(color: textMuted, fontSize: 12),
        labelLarge: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.1,
        ),
      ),

      // --- INPUTS ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _inputHorizontalPadding,
          vertical: _inputVerticalPadding,
        ),
        hintStyle: const TextStyle(color: textHint),
        helperStyle: const TextStyle(color: textMuted, fontSize: 12),
        errorStyle: const TextStyle(color: error, fontSize: 12),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: const BorderSide(color: Colors.transparent, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- BOTÓN PRINCIPAL (Esmeralda sólido) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white54,
          minimumSize: const Size.fromHeight(_buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
        ),
      ),

      // --- BOTÓN SECUNDARIO (Borde esmeralda, fondo transparente) ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size.fromHeight(_buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
      ),

      // --- BOTÓN DE TEXTO (Links: "¿Olvidaste tu contraseña?") ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // --- TARJETAS (Suscripciones, Sesiones, Historial) ---
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: _cardRadius),
      ),

      // --- SNACKBAR (Feedback de API: errores, éxito) ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: textMain, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: _snackBarRadius),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // --- DIÁLOGOS (Logout, Eliminar cuenta, Confirmaciones) ---
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: _dialogRadius),
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          color: textMain,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),

      // --- BOTTOM SHEET (Opciones, Filtros) ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBarrierColor: Colors.black54,
      ),

      // --- DIVIDER ---
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // --- CHECKBOX / SWITCH (Términos y condiciones, opciones) ---
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return surface;
        }),
      ),

      // --- PROGRESS INDICATOR ---
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surface,
      ),

      // --- ICON ---
      iconTheme: const IconThemeData(
        color: textMuted,
        size: 24,
      ),

      // --- FLOATING ACTION BUTTON ---
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // --- TAB BAR ---
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),

      // --- TOOLTIP ---
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: textMain, fontSize: 12),
      ),
    );
  }

  // =========================================================
  // HELPERS DE ESTILO REUTILIZABLES
  // =========================================================

  /// Sombra esmeralda para widgets destacados (botón principal, FAB)
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Decoración para contenedores tipo tarjeta personalizados
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: _cardRadius,
        border: Border.all(color: divider, width: 0.5),
      );

  /// Decoración para contenedores con borde esmeralda (seleccionado/activo)
  static BoxDecoration get activeCardDecoration => BoxDecoration(
        color: surface,
        borderRadius: _cardRadius,
        border: Border.all(color: primary, width: 1.5),
      );

  /// Gradiente esmeralda para headers o fondos especiales
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [
          primary,
          secondary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
