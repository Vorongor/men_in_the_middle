class Profile {
  final int? id;
  final int levelId;
  final int softwarePower;
  final int hardwarePower;
  final int rating;
  final int karma;
  final int wanted;
  final int popularity;
  final int blackTrust;
  final String legend;
  final int experience;

  const Profile({
    this.id,
    required this.levelId,
    this.softwarePower = 0,
    this.hardwarePower = 0,
    this.rating = 0,
    this.karma = 50,
    this.wanted = 1,
    this.popularity = 0,
    this.blackTrust = 1,
    required this.legend,
    this.experience = 0,
  });

  Map<String, dynamic> toMap() => {
        'level_id': levelId,
        'software_power': softwarePower,
        'hardware_power': hardwarePower,
        'rating': rating,
        'karma': karma,
        'wanted': wanted,
        'popularity': popularity,
        'black_trust': blackTrust,
        'legend': legend,
        'experience': experience,
      };

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['profile_id'] as int? ?? m['id'] as int?,
        levelId: m['level_id'] as int,
        softwarePower: m['software_power'] as int,
        hardwarePower: m['hardware_power'] as int,
        rating: m['rating'] as int,
        karma: m['karma'] as int,
        wanted: m['wanted'] as int,
        popularity: m['popularity'] as int,
        blackTrust: m['black_trust'] as int,
        legend: m['legend'] as String,
        experience: m['experience'] as int,
      );
}
