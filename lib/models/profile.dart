class Profile {
  final int? id;
  final String profileId;
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
  final int eptsBalance;
  final int uepBalance;

  const Profile({
    this.id,
    required this.profileId,
    required this.levelId,
    this.softwarePower = 0,
    this.hardwarePower = 0,
    this.rating = 0,
    this.karma = 50,
    this.wanted = 0,
    this.popularity = 0,
    this.blackTrust = 0,
    required this.legend,
    this.experience = 0,
    this.eptsBalance = 0,
    this.uepBalance = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
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
        'epts_balance': eptsBalance,
        'uep_balance': uepBalance,
      };

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as int?,
        profileId: m['profile_id'] as String? ?? '',
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
        eptsBalance: m['epts_balance'] as int? ?? 0,
        uepBalance: m['uep_balance'] as int? ?? 0,
      );
}
