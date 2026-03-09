class DailyConceptModel {
  final String conceptName;
  final String conceptDescription;
  final String themeId;
  final String themeName;
  final DateTime conceptDate;
  final bool alreadyCompleted;

  DailyConceptModel({
    required this.conceptName,
    required this.conceptDescription,
    required this.themeId,
    this.themeName = '',
    required this.conceptDate,
    required this.alreadyCompleted,
  });

  factory DailyConceptModel.fromJson(Map<String, dynamic> json) {
    return DailyConceptModel(
      conceptName: json['concept_name'] ?? '',
      conceptDescription: json['concept_description'] ?? '',
      themeId: json['theme_id'] ?? '',
      themeName: json['theme_name'] ?? '',
      conceptDate: DateTime.tryParse(json['concept_date']?.toString() ?? '') ?? DateTime.now(),
      alreadyCompleted: json['already_completed'] ?? false,
    );
  }
}
