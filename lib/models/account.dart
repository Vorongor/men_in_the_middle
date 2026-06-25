class Account {
  final int? id;
  final String pseudo;
  final String pass;
  final int? profileId;

  const Account({
    this.id,
    required this.pseudo,
    required this.pass,
    this.profileId,
  });

  Map<String, dynamic> toMap() => {
        'pseudo': pseudo,
        'pass': pass,
        if (profileId != null) 'profile_id': profileId,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id: m['id'] as int?,
        pseudo: m['pseudo'] as String,
        pass: m['pass'] as String,
        profileId: m['profile_id'] as int?,
      );
}
