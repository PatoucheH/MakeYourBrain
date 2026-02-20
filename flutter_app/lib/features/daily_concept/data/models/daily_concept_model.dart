class DailyConceptModel {
  final String conceptName;
  final String conceptDescription;
  final String themeId;
  final DateTime conceptDate;
  final bool alreadyCompleted;

  DailyConceptModel({
    required this.conceptName,
    required this.conceptDescription,
    required this.themeId,
    required this.conceptDate,
    required this.alreadyCompleted,
  });

  factory DailyConceptModel.fromJson(Map<String, dynamic> json) {
    return DailyConceptModel(
      conceptName: json['concept_name'] ?? '',
      conceptDescription: json['concept_description'] ?? '',
      themeId: json['theme_id'] ?? '',
      conceptDate: DateTime.parse(json['concept_date']),
      alreadyCompleted: json['already_completed'] ?? false,
    );
  }
}
