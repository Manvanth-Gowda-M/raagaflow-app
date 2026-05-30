import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get headline1 => GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static TextStyle get headline2 => GoogleFonts.plusJakartaSans(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get trackTitle => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get trackArtist => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
}
