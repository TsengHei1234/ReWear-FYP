import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic ReWear colour tokens that flip between light and dark themes.
///
/// This is the single source of truth for theme-aware colours. Widgets read
/// these via `context.colors.surface` (see [AppColorsX]) instead of hardcoding
/// light-mode constants from [AppColors] — that was the dark-mode bug.
///
/// Brand-fixed colours that do NOT flip (badge backgrounds, clothing swatches,
/// danger red, favourite star) stay on [AppColors] directly.
@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderFocus,
    required this.primary,
    required this.primaryMid,
    required this.primaryLight,
    required this.onPrimaryLight,
    required this.chevron,
  });

  final Color background;
  final Color surface;
  final Color surface2;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color borderFocus;
  final Color primary;
  final Color primaryMid;
  final Color primaryLight;

  /// Text/icon colour shown on top of [primaryLight] backgrounds.
  final Color onPrimaryLight;
  final Color chevron;

  /// Light theme — the values from Frontend §1.
  static const light = AppColorsTheme(
    background: AppColors.background,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: AppColors.border,
    borderFocus: AppColors.borderFocus,
    primary: AppColors.primary,
    primaryMid: AppColors.primaryMid,
    primaryLight: AppColors.primaryLight,
    onPrimaryLight: AppColors.darkPrimaryText,
    chevron: AppColors.chevron,
  );

  /// Dark theme — the dark tokens from Frontend §1 plus derived accents.
  static const dark = AppColorsTheme(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
    borderFocus: AppColors.darkPrimary,
    primary: AppColors.darkPrimary,
    primaryMid: AppColors.primaryMid,
    primaryLight: AppColors.darkPrimaryLight,
    onPrimaryLight: AppColors.darkOnPrimaryLight,
    chevron: AppColors.darkTextTertiary,
  );

  @override
  AppColorsTheme copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderFocus,
    Color? primary,
    Color? primaryMid,
    Color? primaryLight,
    Color? onPrimaryLight,
    Color? chevron,
  }) =>
      AppColorsTheme(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        border: border ?? this.border,
        borderFocus: borderFocus ?? this.borderFocus,
        primary: primary ?? this.primary,
        primaryMid: primaryMid ?? this.primaryMid,
        primaryLight: primaryLight ?? this.primaryLight,
        onPrimaryLight: onPrimaryLight ?? this.onPrimaryLight,
        chevron: chevron ?? this.chevron,
      );

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    if (other is! AppColorsTheme) return this;
    return AppColorsTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryMid: Color.lerp(primaryMid, other.primaryMid, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      onPrimaryLight: Color.lerp(onPrimaryLight, other.onPrimaryLight, t)!,
      chevron: Color.lerp(chevron, other.chevron, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.surface`.
extension AppColorsX on BuildContext {
  AppColorsTheme get colors =>
      Theme.of(this).extension<AppColorsTheme>() ?? AppColorsTheme.light;
}
