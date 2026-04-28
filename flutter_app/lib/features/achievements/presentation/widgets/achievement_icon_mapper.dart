import 'package:flutter/material.dart';

enum AchievementTier { bronze, silver, gold, platinum, diamond, legendary }

class AchievementTierData {
  final AchievementTier tier;
  final String labelEn;
  final String labelFr;
  final List<Color> gradient;
  final Color glowColor;

  const AchievementTierData({
    required this.tier,
    required this.labelEn,
    required this.labelFr,
    required this.gradient,
    required this.glowColor,
  });

  String label(String lang) => lang == 'fr' ? labelFr : labelEn;
}

class AchievementIconMapper {
  static IconData iconForCategory(String category) {
    switch (category) {
      case 'quiz':          return Icons.menu_book_rounded;
      case 'streak':        return Icons.local_fire_department_rounded;
      case 'accuracy':      return Icons.gps_fixed_rounded;
      case 'pvp':           return Icons.shield_rounded;
      case 'daily_streak':  return Icons.today_rounded;
      case 'theme_master':  return Icons.auto_stories_rounded;
      case 'social':        return Icons.people_rounded;
      default:              return Icons.star_rounded;
    }
  }

  static AchievementTierData tierData(String category, int conditionValue) {
    return _dataFor(_tierFor(category, conditionValue));
  }

  static AchievementTier _tierFor(String category, int value) {
    switch (category) {
      case 'quiz':
        if (value <= 250)   return AchievementTier.bronze;
        if (value <= 1000)  return AchievementTier.silver;
        if (value <= 5000)  return AchievementTier.gold;
        if (value <= 10000) return AchievementTier.platinum;
        if (value <= 20000) return AchievementTier.diamond;
        return AchievementTier.legendary;
      case 'streak':
        if (value <= 7)   return AchievementTier.bronze;
        if (value <= 14)  return AchievementTier.silver;
        if (value <= 50)  return AchievementTier.gold;
        if (value <= 100) return AchievementTier.platinum;
        if (value <= 200) return AchievementTier.diamond;
        return AchievementTier.legendary;
      case 'pvp':
        if (value <= 5)   return AchievementTier.bronze;
        if (value <= 25)  return AchievementTier.silver;
        if (value <= 50)  return AchievementTier.gold;
        if (value <= 100) return AchievementTier.platinum;
        if (value <= 200) return AchievementTier.diamond;
        return AchievementTier.legendary;
      case 'accuracy':
        if (value <= 70) return AchievementTier.bronze;
        if (value <= 80) return AchievementTier.silver;
        if (value <= 90) return AchievementTier.gold;
        return AchievementTier.platinum;
      case 'daily_streak':
        if (value <= 3)  return AchievementTier.bronze;
        if (value <= 7)  return AchievementTier.silver;
        if (value <= 14) return AchievementTier.gold;
        if (value <= 30) return AchievementTier.platinum;
        if (value <= 60) return AchievementTier.diamond;
        return AchievementTier.legendary;
      case 'theme_master':
        if (value <= 1)  return AchievementTier.bronze;
        if (value <= 3)  return AchievementTier.silver;
        if (value <= 5)  return AchievementTier.gold;
        if (value <= 10) return AchievementTier.platinum;
        if (value <= 15) return AchievementTier.diamond;
        return AchievementTier.legendary;
      case 'social':
        if (value <= 1)  return AchievementTier.bronze;
        if (value <= 5)  return AchievementTier.silver;
        if (value <= 10) return AchievementTier.gold;
        if (value <= 25) return AchievementTier.platinum;
        if (value <= 50) return AchievementTier.diamond;
        return AchievementTier.legendary;
      default:
        return AchievementTier.bronze;
    }
  }

  static AchievementTierData _dataFor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const AchievementTierData(
          tier: AchievementTier.bronze,
          labelEn: 'Bronze', labelFr: 'Bronze',
          gradient: [Color(0xFFCD7F32), Color(0xFFE8A96A)],
          glowColor: Color(0xFFCD7F32),
        );
      case AchievementTier.silver:
        return const AchievementTierData(
          tier: AchievementTier.silver,
          labelEn: 'Silver', labelFr: 'Argent',
          gradient: [Color(0xFF9E9E9E), Color(0xFFE0E0E0)],
          glowColor: Color(0xFFBDBDBD),
        );
      case AchievementTier.gold:
        return const AchievementTierData(
          tier: AchievementTier.gold,
          labelEn: 'Gold', labelFr: 'Or',
          gradient: [Color(0xFFFFD700), Color(0xFFFFA000)],
          glowColor: Color(0xFFFFD700),
        );
      case AchievementTier.platinum:
        return const AchievementTierData(
          tier: AchievementTier.platinum,
          labelEn: 'Platinum', labelFr: 'Platine',
          gradient: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
          glowColor: Color(0xFF00BCD4),
        );
      case AchievementTier.diamond:
        return const AchievementTierData(
          tier: AchievementTier.diamond,
          labelEn: 'Diamond', labelFr: 'Diamant',
          gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          glowColor: Color(0xFF7C3AED),
        );
      case AchievementTier.legendary:
        return const AchievementTierData(
          tier: AchievementTier.legendary,
          labelEn: 'Legendary', labelFr: 'Légendaire',
          gradient: [Color(0xFFFF6B35), Color(0xFFFFD700)],
          glowColor: Color(0xFFFF6B35),
        );
    }
  }
}
