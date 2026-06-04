import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale.
///
/// Source of truth: Frontend Reference §2 "Typography".
/// Font family: Plus Jakarta Sans (via google_fonts).
/// Colours default to the light theme; override `color:` for dark surfaces.
class AppText {
  AppText._();

  // color is nullable so primary-text styles inherit from DefaultTextStyle
  // (which Flutter sets from ThemeData.textTheme → correct for dark + light).
  // Pass an explicit colour only for secondary/tertiary variants below.
  static TextStyle _base(
    double size,
    FontWeight weight, [
    Color? color,
  ]) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // size / weight / default colour — names match §2 table.
  static TextStyle get display => _base(28, FontWeight.w700);
  static TextStyle get titleL => _base(22, FontWeight.w700);
  static TextStyle get titleM => _base(18, FontWeight.w600);
  static TextStyle get titleS => _base(16, FontWeight.w600);

  static TextStyle get bodyL => _base(16, FontWeight.w400);
  static TextStyle get bodyM => _base(14, FontWeight.w400);
  static TextStyle get bodyS => _base(13, FontWeight.w400);
  static TextStyle get bodySBold => _base(13, FontWeight.w600);

  static TextStyle get label => _base(14, FontWeight.w500);
  static TextStyle get labelS => _base(12, FontWeight.w500, AppColors.textSecondary);
  static TextStyle get caption => _base(11, FontWeight.w500, AppColors.textTertiary);
  static TextStyle get captionBold => _base(11, FontWeight.w700);
  static TextStyle get micro => _base(10, FontWeight.w600, AppColors.textTertiary);

  /// Section category labels e.g. "ACCOUNT" — uppercase, tracked. §2.
  static TextStyle get sectionLabel => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08 * 11,
        color: AppColors.textTertiary,
      );
}
