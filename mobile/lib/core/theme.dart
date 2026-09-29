import 'package:flutter/material.dart';
import 'app_fonts.dart';
import 'dart:ui'; // For PointerDeviceKind

class AppColors {
  // Base Palette (Slate / Modern Blue-Grey)
  static const Color foreground = Color(0xFF131B2E);
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Colors.white;

  // Brand — logo pair (identity) + blue (interaction)
  static const Color brandNavy = Color(0xFF181828); // Dark navy from the Annur logo (hero blocks)
  static const Color onNavyMuted = Color(0xB3FFFFFF); // Secondary text on navy (white 70%)
  static const Color brandYellow = Color(0xFFF8D840); // Yellow from the Annur logo (accent on navy, duotone icons)
  static const Color primary = Color(0xFF0058BE); // Annur Royal Blue — buttons, links, selected states
  static const Color primaryLight = Color(0xFF2B7FFF);
  static const Color primaryForeground = Colors.white;
  static const Color primarySoft = Color(0xFFEAF1FB); // Icon tiles, selected rows
  static const Color accentSoft = Color(0xFFDAE2FD); // Soft pastel blue (selected nav pill)
  // The old violet accent is retired; secondary now maps to the logo navy.
  static const Color secondary = brandNavy;

  // Legacy compatibility
  static const Color mandiriBlueDark = Color(0xFF0058BE);
  static const Color mandiriBlueLight = Color(0xFF2B7FFF);

  static const Color muted = Color(0xFFF1F5F9); // Slate-100
  static const Color mutedForeground = Color(0xFF64748B); // Slate-500

  // Status colors. Use the base color for icons/fills and tinted backgrounds
  // (withValues(alpha: 0.1)); use the *Strong variant for TEXT on white or
  // on a tinted background (≥ 4.5:1 contrast).
  static const Color destructive = Color(0xFFEF4444); // Red-500
  static const Color destructiveStrong = Color(0xFFB91C1C); // Red-700
  static const Color destructiveForeground = Colors.white;
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successStrong = Color(0xFF047857); // Emerald-700
  static const Color warning = Color(0xFFF59E0B); // Amber-500 (stok menipis)
  static const Color warningStrong = Color(0xFFB45309); // Amber-700

  // Opaque tints for backgrounds (Soft) and hairlines (Border) — const-safe.
  static const Color destructiveSoft = Color(0xFFFEF2F2);
  static const Color destructiveBorder = Color(0xFFFECACA);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color primaryBorder = Color(0xFFBFD3F2);

  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF0058BE);
}

class AppTheme {
  static ThemeData get lightTheme {
    // One family with real 400/500/600/700 faces (see AppFonts).
    const ff = AppFonts.family;
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: ff,
    );

    final textTheme = base.textTheme
        .copyWith(
          headlineSmall: TextStyle(fontFamily: ff, fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontFamily: ff, fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontFamily: ff, fontSize: 17, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontFamily: ff, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: ff, fontSize: 15, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontFamily: ff, fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontFamily: ff, 
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedForeground,
          ),
          labelLarge: TextStyle(fontFamily: ff, fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontFamily: ff, fontSize: 13, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontFamily: ff, fontSize: 12, fontWeight: FontWeight.w500),
        )
        .apply(
          fontFamily: ff,
          bodyColor: AppColors.foreground,
          displayColor: AppColors.foreground,
        );

    final roundedButton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final buttonText =
        TextStyle(fontFamily: ff, fontWeight: FontWeight.w600, fontSize: 15);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.brandNavy,
        onSecondary: AppColors.brandYellow,
        tertiary: AppColors.brandYellow,
        onTertiary: AppColors.brandNavy,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        onSurfaceVariant: AppColors.mutedForeground,
        surfaceTint: Colors.transparent,
        outline: AppColors.border,
        outlineVariant: AppColors.muted,
        error: AppColors.destructive,
      ),
      iconTheme: const IconThemeData(color: AppColors.foreground, size: 22),

      // AppBar — white, flat, hairline bottom border
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: AppColors.border)),
        iconTheme: IconThemeData(color: AppColors.foreground, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.foreground, size: 22),
        titleTextStyle: TextStyle(fontFamily: ff, 
          color: AppColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // Input (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.destructive, width: 2),
        ),
        hintStyle: TextStyle(fontFamily: ff, 
          color: AppColors.mutedForeground,
          fontSize: 14,
        ),
        labelStyle: TextStyle(fontFamily: ff, 
          color: AppColors.mutedForeground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(fontFamily: ff, 
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: TextStyle(fontFamily: ff, 
          color: AppColors.destructiveStrong,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.mutedForeground,
        suffixIconColor: AppColors.mutedForeground,
      ),

      // Buttons — all at least 48 dp tall
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          disabledBackgroundColor: AppColors.muted,
          disabledForegroundColor: AppColors.mutedForeground,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: roundedButton,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          disabledBackgroundColor: AppColors.muted,
          disabledForegroundColor: AppColors.mutedForeground,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: roundedButton,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: roundedButton,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: roundedButton,
          textStyle: TextStyle(fontFamily: ff, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),

      // Main "add" action on list screens: logo navy + yellow, like the Kasir button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandNavy,
        foregroundColor: AppColors.brandYellow,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        extendedTextStyle: TextStyle(fontFamily: ff, 
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mutedForeground,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        labelStyle: TextStyle(fontFamily: ff, fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: ff, fontSize: 14, fontWeight: FontWeight.w500),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.muted,
        checkmarkColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: TextStyle(fontFamily: ff, 
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        secondaryLabelStyle: TextStyle(fontFamily: ff, 
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontFamily: ff, 
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
        contentTextStyle: TextStyle(fontFamily: ff, 
          fontSize: 14,
          height: 1.5,
          color: AppColors.foreground,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandNavy,
        contentTextStyle: TextStyle(fontFamily: ff, 
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        actionTextColor: AppColors.brandYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: TextStyle(fontFamily: ff, 
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        subtitleTextStyle: TextStyle(fontFamily: ff, 
          fontSize: 13,
          color: AppColors.mutedForeground,
        ),
        minVerticalPadding: 10,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: TextStyle(fontFamily: ff, fontSize: 14, color: AppColors.foreground),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.muted,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
