class Account {
  final int? id;
  final String pseudo;
  final String pass;

  const Account({this.id, required this.pseudo, required this.pass});

  Map<String, dynamic> toMap() => {'pseudo': pseudo, 'pass': pass};

  factory Account.fromMap(Map<String, dynamic> m) =>
      Account(id: m['id'] as int, pseudo: m['pseudo'] as String, pass: m['pass'] as String);
}
