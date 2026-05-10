class Badge {
  final String id;
  final String name;
  final String achievement;
  final String? iconUrl;
  final String type; // e.g. "LEVEL", "COURSES_COUNT", "SPECIAL"

  Badge({
    required this.id,
    required this.name,
    required this.achievement,
    this.iconUrl,
    required this.type,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      achievement: json['achievement'] ?? '',
      iconUrl: json['iconUrl'],
      type: json['type'] ?? 'LEVEL',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'achievement': achievement,
    'iconUrl': iconUrl,
    'type': type,
  };
}
