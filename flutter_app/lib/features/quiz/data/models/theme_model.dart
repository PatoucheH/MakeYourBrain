class ThemeModel {
  final String id;
  final String icon;
  final String? iconPath;
  final String color;
  final String name;
  final String description;
  final String languageCode;

  ThemeModel({
    required this.id,
    required this.icon,
    this.iconPath,
    required this.color,
    required this.name,
    required this.description,
    required this.languageCode,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '📚',
      iconPath: json['icon_path']?.toString(),
      color: json['color']?.toString() ?? '#6366F1',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      languageCode: json['language_code']?.toString() ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon,
      'color': color,
      'name': name,
      'description': description,
      'language_code': languageCode,
    };
  }
}
