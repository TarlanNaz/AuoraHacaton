import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// B2B/B2G палитра: off-white фон, белые карточки, синий primary.
/// Текст — чёрный: на Aurora OS серый Material иначе рисуется «как в Windows».
class AppTheme {
  AppTheme._();

  /// Минимальный размер зоны нажатия для полевой работы (перчатки, холод).
  static const double minTouchTarget = 48;

  // ─── Фон и поверхности (светлая «белая» демо-тема для Aurora) ────────────
  static const Color scaffoldBackground = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrayMuted = Color(0xFFF5F5F5);
  static const Color demoPanelBackground = Color(0xFFFAFAFA);
  static const Color cardBorder = Color(0xFFEEEEEE);

  // ─── Текст (высокий контраст для Aurora / Qt) ────────────────────────────
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF212121);

  // ─── Бренд: navy + deep blue ─────────────────────────────────────────────
  static const Color brandNavy = Color(0xFF1A2B4A);
  static const Color brandBlue = Color(0xFF1565C0);
  static const Color brandBlueLight = Color(0xFFF0F7FF);
  static const Color brandDarkGray = textSecondary;
  static const Color brandText = textPrimary;

  // ─── Семантика ───────────────────────────────────────────────────────────
  static const Color warningAmber = Color(0xFFFF8F00);
  static const Color warningOrange = Color(0xFFE65100);
  static const Color warningOrangeLight = Color(0xFFFFF3E0);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFFE8F5E9);
  static const Color errorMuted = Color(0xFFD32F2F);
  static const Color errorRedLight = Color(0xFFFFEBEE);

  /// Алиасы для совместимости.
  static const Color accentOrange = warningOrange;
  static const Color accentOrangeLight = warningOrangeLight;
  static const Color accentAmber = warningAmber;
  static const Color errorRed = errorMuted;
  static const Color surfaceGray = scaffoldBackground;
  static const Color auroraDeep = brandNavy;
  static const Color auroraNavy = brandBlue;
  static const Color auroraTeal = warningOrange;
  static const Color auroraMint = warningAmber;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: surfaceWhite,
      primaryContainer: surfaceWhite,
      onPrimaryContainer: Color(0xFF0D47A1),
      secondary: brandDarkGray,
      onSecondary: surfaceWhite,
      secondaryContainer: demoPanelBackground,
      onSecondaryContainer: textPrimary,
      tertiary: warningOrange,
      onTertiary: surfaceWhite,
      tertiaryContainer: warningOrangeLight,
      onTertiaryContainer: Color(0xFFBF360C),
      error: errorMuted,
      onError: surfaceWhite,
      errorContainer: errorRedLight,
      onErrorContainer: Color(0xFFB71C1C),
      surface: scaffoldBackground,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: Color(0xFF90A4AE),
      outlineVariant: cardBorder,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: brandNavy,
      onInverseSurface: surfaceWhite,
      inversePrimary: brandBlueLight,
      surfaceTint: brandBlue,
      surfaceContainerHighest: surfaceGrayMuted,
      surfaceContainerHigh: demoPanelBackground,
      surfaceContainer: scaffoldBackground,
      surfaceContainerLow: surfaceWhite,
      surfaceContainerLowest: surfaceWhite,
      surfaceBright: surfaceWhite,
      surfaceDim: Color(0xFFF0F0F0),
    );

    final textTheme = _textTheme(scheme);

    return _baseTheme(scheme, textTheme).copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      applyElevationOverlayColor: false,
      dividerColor: const Color(0xFFBDBDBD),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: surfaceWhite,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            height: 1.4,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: warningAmber, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.4,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black12,
        color: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 8,
        minTileHeight: minTouchTarget,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        highlightElevation: 6,
        extendedSizeConstraints: const BoxConstraints(
          minHeight: minTouchTarget,
          minWidth: minTouchTarget,
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            height: 1.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: textSecondary,
          height: 1.45,
        ),
        labelStyle: const TextStyle(color: textPrimary, height: 1.4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: demoPanelBackground,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandNavy,
        contentTextStyle: const TextStyle(color: Colors.white, height: 1.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
      primary: brandBlue,
      error: errorMuted,
    );
    return _baseTheme(scheme, _textTheme(scheme));
  }

  static ThemeData _baseTheme(ColorScheme scheme, TextTheme textTheme) {
    final applied = textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      textTheme: applied,
      primaryTextTheme: applied,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme _) {
    const primary = textPrimary;
    const secondary = textSecondary;

    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.4,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.25,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.45,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.45,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.45,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: secondary,
      ),
    );
  }
}
