class Service {
  final int? id;
  final String nom;
  final String? description;
  final int dureeMinutes;
  final double prix;
  final String? categorie;
  final List<String> tags;
  final bool actif;
  final DateTime dateCreation;
  final DateTime? dateModification;

  const Service({
    this.id,
    required this.nom,
    this.description,
    required this.dureeMinutes,
    required this.prix,
    this.categorie,
    this.tags = const [],
    this.actif = true,
    required this.dateCreation,
    this.dateModification,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'dureeMinutes': dureeMinutes,
      'prix': prix,
      'categorie': categorie,
      'tags': tags.join(','),
      'actif': actif ? 1 : 0,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'dateModification': dateModification?.millisecondsSinceEpoch,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id']?.toInt(),
      nom: map['nom'] ?? '',
      description: map['description'],
      dureeMinutes: map['dureeMinutes']?.toInt() ?? 30,
      prix: map['prix']?.toDouble() ?? 0.0,
      categorie: map['categorie'],
      tags: map['tags'] != null ? map['tags'].split(',').where((t) => t.isNotEmpty).toList().cast<String>() : [],
      actif: map['actif'] == 1,
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
      dateModification: map['dateModification'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dateModification']) : null,
    );
  }

  Service copyWith({
    int? id,
    String? nom,
    String? description,
    int? dureeMinutes,
    double? prix,
    String? categorie,
    List<String>? tags,
    bool? actif,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Service(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dureeMinutes: dureeMinutes ?? this.dureeMinutes,
      prix: prix ?? this.prix,
      categorie: categorie ?? this.categorie,
      tags: tags ?? this.tags,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  String get dureeFormatee {
    final heures = dureeMinutes ~/ 60;
    final minutes = dureeMinutes % 60;
    if (heures > 0) {
      return minutes > 0 ? '${heures}h${minutes}m' : '${heures}h';
    }
    return '${minutes}m';
  }

  String get prixFormate => '${prix.toStringAsFixed(2)}€';

  @override
  String toString() {
    return 'Service(id: $id, nom: $nom, duree: $dureeFormatee, prix: $prixFormate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
