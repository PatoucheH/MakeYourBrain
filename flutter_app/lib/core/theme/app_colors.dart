import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales (Brainly)
  static const Color brainPink = Color(0xFFFFB6D9);
  static const Color brainPinkLight = Color(0xFFFFD6EB);
  static const Color brainPurple = Color(0xFF5B21B6);
  static const Color brainPurpleDark = Color(0xFF4C1D95);
  static const Color brainLightPurple = Color(0xFFA78BFA);
  static const Color brainPurpleLight = Color(0xFFEDE9FE);

  // Couleurs secondaires
  static const Color accentYellow = Color(0xFFFCD34D);
  static const Color accentYellowLight = Color(0xFFFEF3C7);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentGreen = Color(0xFF34D399);

  // Niveaux de couleurs (pour les levels)
  static const Color level1_2 = Color(0xFF60A5FA);   // Bleu
  static const Color level3_4 = Color(0xFF10B981);   // Vert
  static const Color level5_6 = Color(0xFFF59E0B);   // Orange
  static const Color level7_9 = Color(0xFFEF4444);   // Rouge
  static const Color level10plus = Color(0xFF8B5CF6); // Violet

  // Couleurs neutres
  static const Color backgroundLight = Color(0xFFFAF5FF); // Légère teinte violette
  static const Color backgroundGray = Color(0xFFF3F4F6);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color white = Color(0xFFFFFFFF);

  // Couleurs fonctionnelles
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brainPurple, brainLightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [brainPink, brainPinkLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAF5FF), Color(0xFFEDE9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, Color(0xFFFAF5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: brainPurple.withValues(alpha:0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: brainPurple.withValues(alpha:0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: brainPurple.withValues(alpha:0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
