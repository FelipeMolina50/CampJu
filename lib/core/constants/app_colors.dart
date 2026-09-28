import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppColors {
  // PRINCIPAL (Tokens de AppTheme)
  static const Color primary = AppTheme.primary;
  static const Color primaryDark = AppTheme.primaryDark;
  static const Color primaryContainer = AppTheme.primaryContainer;

  // ACENTOS
  static const Color accent = AppTheme.accent;
  static const Color accentYellow = AppTheme.accent;
  static const Color accentPink = AppTheme.like;
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color secondary = AppTheme.secondary;
  
  // CURSOS
  static const Color coursePrimary = AppTheme.primary;

  // MENSAJES (Chat)
  static const Color msgSent = AppTheme.primary;
  static const Color msgReceived = Color(0xFFEAE8E1);

  // FUNCIONAL
  static const Color location = AppTheme.secondary;
  static const Color error = AppTheme.error;
  static const Color like = AppTheme.like;

  // ESTRUCTURA
  static const Color surface = AppTheme.surface;
  static const Color border = AppTheme.border;
  static const Color textSecondary = AppTheme.onSurfaceMuted;
  static const Color textPrimary = AppTheme.onSurface;
  
  static const Color background = AppTheme.background;
}
