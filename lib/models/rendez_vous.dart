enum StatutRendezVous { confirme, annule, complete, enAttente }

class RendezVous {
  final int? id;
  final int clientId;
  final int serviceId;
  final DateTime dateHeure;
  final int dureeMinutes;
  final double prix;
  final StatutRendezVous statut;
  final String? notes;
  final DateTime dateCreation;
  final DateTime? dateModification;

  // Relations
  final String? clientNom;
  final String? clientPrenom;
  final String? serviceNom;

  const RendezVous({
    this.id,
    required this.clientId,
    required this.serviceId,
    required this.dateHeure,
    required this.dureeMinutes,
    required this.prix,
    this.statut = StatutRendezVous.confirme,
    this.notes,
    required this.dateCreation,
    this.dateModification,
    this.clientNom,
    this.clientPrenom,
    this.serviceNom,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'serviceId': serviceId,
      'dateHeure': dateHeure.millisecondsSinceEpoch,
      'dureeMinutes': dureeMinutes,
      'prix': prix,
      'statut': statut.index,
      'notes': notes,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'dateModification': dateModification?.millisecondsSinceEpoch,
    };
  }

  factory RendezVous.fromMap(Map<String, dynamic> map) {
    return RendezVous(
      id: map['id']?.toInt(),
      clientId: map['clientId']?.toInt() ?? 0,
      serviceId: map['serviceId']?.toInt() ?? 0,
      dateHeure: DateTime.fromMillisecondsSinceEpoch(map['dateHeure']),
      dureeMinutes: map['dureeMinutes']?.toInt() ?? 30,
      prix: map['prix']?.toDouble() ?? 0.0,
      statut: StatutRendezVous.values[map['statut'] ?? 0],
      notes: map['notes'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation']),
      dateModification: map['dateModification'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dateModification']) : null,
      clientNom: map['clientNom'],
      clientPrenom: map['clientPrenom'],
      serviceNom: map['serviceNom'],
    );
  }

  RendezVous copyWith({
    int? id,
    int? clientId,
    int? serviceId,
    DateTime? dateHeure,
    int? dureeMinutes,
    double? prix,
    StatutRendezVous? statut,
    String? notes,
    DateTime? dateCreation,
    DateTime? dateModification,
    String? clientNom,
    String? clientPrenom,
    String? serviceNom,
  }) {
    return RendezVous(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      dateHeure: dateHeure ?? this.dateHeure,
      dureeMinutes: dureeMinutes ?? this.dureeMinutes,
      prix: prix ?? this.prix,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      clientNom: clientNom ?? this.clientNom,
      clientPrenom: clientPrenom ?? this.clientPrenom,
      serviceNom: serviceNom ?? this.serviceNom,
    );
  }

  DateTime get dateFin => dateHeure.add(Duration(minutes: dureeMinutes));

  String get clientNomComplet {
    if (clientPrenom != null && clientNom != null) {
      return '$clientPrenom $clientNom';
    }
    return 'Client non trouvé';
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

  String get statutLabel {
    switch (statut) {
      case StatutRendezVous.confirme:
        return 'Confirmé';
      case StatutRendezVous.annule:
        return 'Annulé';
      case StatutRendezVous.complete:
        return 'Complété';
      case StatutRendezVous.enAttente:
        return 'En attente';
    }
  }

  bool get estAnnule => statut == StatutRendezVous.annule;
  bool get estComplete => statut == StatutRendezVous.complete;
  bool get estConfirme => statut == StatutRendezVous.confirme;
  bool get estEnAttente => statut == StatutRendezVous.enAttente;

  bool conflit(RendezVous autre) {
    if (id == autre.id) return false;
    if (estAnnule || autre.estAnnule) return false;
    
    final finCe = dateFin;
    final finAutre = autre.dateFin;
    
    return dateHeure.isBefore(finAutre) && finCe.isAfter(autre.dateHeure);
  }

  @override
  String toString() {
    return 'RendezVous(id: $id, client: $clientNomComplet, service: $serviceNom, date: $dateHeure, statut: $statutLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RendezVous && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
