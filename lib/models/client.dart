class Client {
  final int? id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String? notes;
  final List<String> tags;
  final DateTime dateCreation;
  final DateTime? dateModification;

  const Client({
    this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    this.notes,
    this.tags = const [],
    required this.dateCreation,
    this.dateModification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'notes': notes,
      'tags': tags.join(','),
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'dateModification': dateModification?.millisecondsSinceEpoch,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id']?.toInt(),
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'],
      email: map['email'],
      notes: map['notes'],
      tags: map['tags'] != null ? map['tags'].split(',').where((t) => t.isNotEmpty).toList().cast<String>() : [],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
      dateModification: map['dateModification'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dateModification']) : null,
    );
  }

  Client copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? notes,
    List<String>? tags,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  String get nomComplet => '$prenom $nom';

  @override
  String toString() {
    return 'Client(id: $id, nom: $nom, prenom: $prenom, telephone: $telephone, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
