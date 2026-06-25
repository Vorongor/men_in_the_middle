class Level {
  final int id;
  final String name;
  final String description;

  const Level({required this.id, required this.name, required this.description});

  factory Level.fromMap(Map<String, dynamic> m) => Level(
        id: m['level_id'] as int? ?? m['id'] as int,
        name: m['level_name'] as String? ?? m['name'] as String,
        description: m['level_desc'] as String? ?? m['description'] as String,
      );
}
