import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Configuración de la Fuente Base
  static TextStyle _baseMulish(double size, FontWeight weight, double height, Color color) {
    return GoogleFonts.mulish(
      fontSize: size,
      fontWeight: weight,
      height: height / size, // Convierte line-height de CSS a ratio de Flutter
      color: color,
    );
  }

  // --- ESCALA DE TAMAÑOS (Tailwind) ---
  static TextStyle textXs = _baseMulish(12, FontWeight.w400, 18, AppColors.textSecondary);
  static TextStyle textSm = _baseMulish(14, FontWeight.w400, 21, AppColors.textSecondary);
  static TextStyle textBase = _baseMulish(16, FontWeight.w400, 24, AppColors.textPrimary);
  static TextStyle textLg = _baseMulish(18, FontWeight.w500, 27, AppColors.textPrimary);
  static TextStyle textXl = _baseMulish(20, FontWeight.w500, 30, AppColors.textPrimary);
  static TextStyle text2Xl = _baseMulish(24, FontWeight.w500, 36, AppColors.textPrimary);
  static TextStyle text3Xl = _baseMulish(30, FontWeight.w500, 45, AppColors.textPrimary);
  static TextStyle textSmall = textSm;

  // Estilos para widgets
  static TextStyle labelLarge = textLg.copyWith(fontWeight: FontWeight.w400);
  static TextStyle bodySmall = textXs;
  static TextStyle buttonText = textSm.copyWith(fontWeight: FontWeight.w600);
  static TextStyle headlineSmall = textBase.copyWith(fontWeight: FontWeight.w600, fontSize: 20);

  static TextStyle bodyLarge = textLg;
  static TextStyle bodyMedium = textBase;
  static TextStyle heading2 = text2Xl.copyWith(fontWeight: FontWeight.bold);
  static TextStyle heading3 = textXl.copyWith(fontWeight: FontWeight.w600);
  static TextStyle heading4 = text3Xl.copyWith(fontWeight: FontWeight.w600);

  // --- REDONDEO (Border Radius) ---
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 10.0; // El base de tu Figma
  static const double radiusXl = 14.0;
  static const double radiusFull = 9999.0;

  // --- SOMBRAS (Shadows) ---
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
      spreadRadius: -1,
    ),
  ];

  // --- PADDINGS COMUNES (Tailwind-like) ---
  static const EdgeInsets padding16 = EdgeInsets.all(16.0);
  static const EdgeInsets paddingH22 = EdgeInsets.symmetric(horizontal: 22.0);
  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: 8.0);

  // Estilo específico para tu Navbar Label
  static TextStyle navLabel = GoogleFonts.mulish(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5, // 15px / 10px
  );
}
