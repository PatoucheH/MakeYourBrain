class AchievementModel {
  final String id;
  final String key;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String icon;
  final String category;
  final int xpReward;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.key,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.category,
    required this.xpReward,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  String nameFor(String lang) => lang == 'fr' ? nameFr : nameEn;
  String descriptionFor(String lang) => lang == 'fr' ? descriptionFr : descriptionEn;

  factory AchievementModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: json['id'] as String? ?? json['achievement_id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionFr: json['description_fr'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏆',
      category: json['category'] as String? ?? 'general',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString())
          : unlockedAt,
    );
  }
}
