class ThemeModel {
  final String id;
  final String icon;
  final String color;
  final String name;
  final String description;
  final String languageCode;

  ThemeModel({
    required this.id,
    required this.icon,
    required this.color,
    required this.name,
    required this.description,
    required this.languageCode,
  });

  // Créer un ThemeModel depuis JSON (Supabase)
  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'],
      icon: json['icon'],
      color: json['color'],
      name: json['name'],
      description: json['description'],
      languageCode: json['language_code'],
    );
  }

  // Convertir en JSON
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