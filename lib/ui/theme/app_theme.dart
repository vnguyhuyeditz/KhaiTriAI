import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_transitions.dart';

import '../../settings/settings_controller.dart';

/// Bảng màu: nền phẳng, một màu nhấn duy nhất, viền siêu mỏng.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color card;
  final Color border;
  final Color label;
  final Color secondary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color positive;
  final Color warning;
  final Color danger;
  final Color seriesA;
  final Color seriesB;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.border,
    required this.label,
    required this.secondary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.positive,
    required this.warning,
    required this.danger,
    required this.seriesA,
    required this.seriesB,
  });

  // Màu hệ thống của Apple (iOS): xanh dương, xanh lá, cam, đỏ.
  // Bản sáng dùng tông đậm hơn cho chữ để luôn đủ tương phản trên nền trắng.
  static const light = AppPalette(
    bg: Color(0xFFF2F2F7), // systemGroupedBackground
    card: Color(0xFFFFFFFF),
    border: Color(0x14000000), // đen 8%
    label: Color(0xFF000000),
    secondary: Color(0xFF6C6C70),
    accent: Color(0xFF007AFF), // systemBlue
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1F007AFF),
    positive: Color(0xFF248A3D),
    warning: Color(0xFFC93400),
    danger: Color(0xFFD70015),
    seriesA: Color(0xFF007AFF),
    seriesB: Color(0xFFFF9500), // systemOrange
  );

  static const dark = AppPalette(
    bg: Color(0xFF000000),
    card: Color(0xFF1C1C1E), // systemGray6 (dark)
    border: Color(0x1AFFFFFF), // trắng 10%
    label: Color(0xFFFFFFFF),
    secondary: Color(0xFF98989D),
    accent: Color(0xFF0A84FF), // systemBlue (dark)
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x380A84FF),
    positive: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
    seriesA: Color(0xFF0A84FF),
    seriesB: Color(0xFFFF9F0A),
  );

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
        bg: bg,
        card: card,
        border: border,
        label: label,
        secondary: secondary,
        accent: accent ?? this.accent,
        onAccent: onAccent,
        accentSoft: accentSoft,
        positive: positive,
        warning: warning,
        danger: danger,
        seriesA: seriesA,
        seriesB: seriesB,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      card: l(card, other.card),
      border: l(border, other.border),
      label: l(label, other.label),
      secondary: l(secondary, other.secondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      positive: l(positive, other.positive),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      seriesA: l(seriesA, other.seriesA),
      seriesB: l(seriesB, other.seriesB),
    );
  }
}

extension ThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Tên kiểu chữ theo thang của Apple, ánh xạ vào TextTheme.
extension AppTextStyles on TextTheme {
  TextStyle get largeTitle => displaySmall!; // 34
  TextStyle get title1 => headlineMedium!; // 28
  TextStyle get title2 => headlineSmall!; // 22
  TextStyle get headline => titleMedium!; // 17, đậm vừa
  TextStyle get body => bodyLarge!; // 17
  TextStyle get subhead => bodyMedium!; // 15
  TextStyle get footnote => bodySmall!; // 13, màu phụ
  TextStyle get caption => labelMedium!; // 12, màu phụ
  TextStyle get button => labelLarge!; // 17, đậm vừa
}

class AppTheme {
  static const easeOut = Cubic(0.25, 1, 0.5, 1);

  static ThemeData build(Brightness brightness, AppFont font) {
    final p = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
    final family = font.family;

    // Chữ lớn nén -0.022em, chữ thường nén -0.011em.
    TextStyle s(double size, FontWeight weight,
            {double height = 1.4, bool title = false, Color? color}) =>
        TextStyle(
          fontFamily: family,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: size * (title ? -0.022 : -0.011),
          color: color ?? p.label,
        );

    final textTheme = TextTheme(
      displaySmall: s(34, FontWeight.w700, height: 1.12, title: true),
      headlineMedium: s(28, FontWeight.w700, height: 1.15, title: true),
      headlineSmall: s(22, FontWeight.w700, height: 1.2, title: true),
      titleMedium: s(17, FontWeight.w600, height: 1.3),
      bodyLarge: s(17, FontWeight.w400),
      bodyMedium: s(15, FontWeight.w400),
      bodySmall: s(13, FontWeight.w400, height: 1.35, color: p.secondary),
      labelLarge: s(17, FontWeight.w600, height: 1.2),
      labelMedium: s(12, FontWeight.w500, height: 1.3, color: p.secondary),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    ).copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      surface: p.card,
      onSurface: p.label,
      error: p.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: family,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        foregroundColor: p.label,
        titleTextStyle: textTheme.titleMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: textTheme.titleMedium,
          minimumSize: const Size(48, 48),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      // Công tắc xanh lá kiểu iOS.
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brightness == Brightness.light
                ? const Color(0xFF34C759)
                : const Color(0xFF30D158);
          }
          return p.label.withValues(alpha: 0.16);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: p.accent,
        inactiveTrackColor: p.label.withValues(alpha: 0.12),
        disabledActiveTrackColor: p.label.withValues(alpha: 0.2),
        disabledInactiveTrackColor: p.label.withValues(alpha: 0.08),
        thumbColor: Colors.white,
        overlayColor: p.accent.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
          pressedElevation: 3,
        ),
        valueIndicatorColor: p.card,
        valueIndicatorTextStyle: textTheme.footnote.copyWith(color: p.label),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: [p],
    );
  }
}
