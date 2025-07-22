class HorairesOuverture {
  final bool ouvert;
  final String heureOuverture;
  final String heureFermeture;

  const HorairesOuverture({
    required this.ouvert,
    required this.heureOuverture,
    required this.heureFermeture,
  });

  Map<String, dynamic> toMap() {
    return {
      'ouvert': ouvert,
      'heureOuverture': heureOuverture,
      'heureFermeture': heureFermeture,
    };
  }

  factory HorairesOuverture.fromMap(Map<String, dynamic> map) {
    return HorairesOuverture(
      ouvert: map['ouvert'] ?? false,
      heureOuverture: map['heureOuverture'] ?? '09:00',
      heureFermeture: map['heureFermeture'] ?? '18:00',
    );
  }
}

enum TypeNotification { rappelRdv, conflit, anniversaire, relance, statut }

class ParametresNotification {
  final bool active;
  final int delaiMinutes;
  final bool son;
  final bool vibration;
  final String? sonPersonnalise;

  const ParametresNotification({
    this.active = true,
    this.delaiMinutes = 60,
    this.son = true,
    this.vibration = true,
    this.sonPersonnalise,
  });

  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'delaiMinutes': delaiMinutes,
      'son': son,
      'vibration': vibration,
      'sonPersonnalise': sonPersonnalise,
    };
  }

  factory ParametresNotification.fromMap(Map<String, dynamic> map) {
    return ParametresNotification(
      active: map['active'] ?? true,
      delaiMinutes: map['delaiMinutes'] ?? 60,
      son: map['son'] ?? true,
      vibration: map['vibration'] ?? true,
      sonPersonnalise: map['sonPersonnalise'],
    );
  }

  ParametresNotification copyWith({
    bool? active,
    int? delaiMinutes,
    bool? son,
    bool? vibration,
    String? sonPersonnalise,
  }) {
    return ParametresNotification(
      active: active ?? this.active,
      delaiMinutes: delaiMinutes ?? this.delaiMinutes,
      son: son ?? this.son,
      vibration: vibration ?? this.vibration,
      sonPersonnalise: sonPersonnalise ?? this.sonPersonnalise,
    );
  }
}

class AppSettings {
  final String langue;
  final bool themeMode; // true = dark, false = light
  final int dureeDefautMinutes;
  final int pauseEntreRdvMinutes;
  final int delaiRappelMinutes;
  final bool notificationsActives;
  final Map<TypeNotification, ParametresNotification> parametresNotifications;
  final bool notificationsGroupees;
  final bool actionsNotifications;
  final Map<int, HorairesOuverture> horaires; // 1-7 (lundi-dimanche)
  final bool verrouillageActif;
  final String? pinCode;
  final bool biometrieActive;

  const AppSettings({
    this.langue = 'fr',
    this.themeMode = false,
    this.dureeDefautMinutes = 30,
    this.pauseEntreRdvMinutes = 5,
    this.delaiRappelMinutes = 60,
    this.notificationsActives = true,
    this.parametresNotifications = const {},
    this.notificationsGroupees = true,
    this.actionsNotifications = true,
    this.horaires = const {},
    this.verrouillageActif = false,
    this.pinCode,
    this.biometrieActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'langue': langue,
      'themeMode': themeMode,
      'dureeDefautMinutes': dureeDefautMinutes,
      'pauseEntreRdvMinutes': pauseEntreRdvMinutes,
      'delaiRappelMinutes': delaiRappelMinutes,
      'notificationsActives': notificationsActives,
      'parametresNotifications': parametresNotifications.map((k, v) => MapEntry(k.index.toString(), v.toMap())),
      'notificationsGroupees': notificationsGroupees,
      'actionsNotifications': actionsNotifications,
      'horaires': horaires.map((k, v) => MapEntry(k.toString(), v.toMap())),
      'verrouillageActif': verrouillageActif,
      'pinCode': pinCode,
      'biometrieActive': biometrieActive,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    Map<int, HorairesOuverture> horairesParsed = {};
    Map<TypeNotification, ParametresNotification> notificationsParsed = {};
    
    if (map['horaires'] is Map) {
      final horairesMap = map['horaires'] as Map;
      for (var entry in horairesMap.entries) {
        final jour = int.tryParse(entry.key.toString());
        if (jour != null && entry.value is Map) {
          horairesParsed[jour] = HorairesOuverture.fromMap(entry.value as Map<String, dynamic>);
        }
      }
    }

    if (map['parametresNotifications'] is Map) {
      final notifMap = map['parametresNotifications'] as Map;
      for (var entry in notifMap.entries) {
        final typeIndex = int.tryParse(entry.key.toString());
        if (typeIndex != null && typeIndex < TypeNotification.values.length && entry.value is Map) {
          notificationsParsed[TypeNotification.values[typeIndex]] = 
              ParametresNotification.fromMap(entry.value as Map<String, dynamic>);
        }
      }
    }

    return AppSettings(
      langue: map['langue'] ?? 'fr',
      themeMode: map['themeMode'] ?? false,
      dureeDefautMinutes: map['dureeDefautMinutes'] ?? 30,
      pauseEntreRdvMinutes: map['pauseEntreRdvMinutes'] ?? 5,
      delaiRappelMinutes: map['delaiRappelMinutes'] ?? 60,
      notificationsActives: map['notificationsActives'] ?? true,
      parametresNotifications: notificationsParsed,
      notificationsGroupees: map['notificationsGroupees'] ?? true,
      actionsNotifications: map['actionsNotifications'] ?? true,
      horaires: horairesParsed,
      verrouillageActif: map['verrouillageActif'] ?? false,
      pinCode: map['pinCode'],
      biometrieActive: map['biometrieActive'] ?? false,
    );
  }

  AppSettings copyWith({
    String? langue,
    bool? themeMode,
    int? dureeDefautMinutes,
    int? pauseEntreRdvMinutes,
    int? delaiRappelMinutes,
    bool? notificationsActives,
    Map<TypeNotification, ParametresNotification>? parametresNotifications,
    bool? notificationsGroupees,
    bool? actionsNotifications,
    Map<int, HorairesOuverture>? horaires,
    bool? verrouillageActif,
    String? pinCode,
    bool? biometrieActive,
  }) {
    return AppSettings(
      langue: langue ?? this.langue,
      themeMode: themeMode ?? this.themeMode,
      dureeDefautMinutes: dureeDefautMinutes ?? this.dureeDefautMinutes,
      pauseEntreRdvMinutes: pauseEntreRdvMinutes ?? this.pauseEntreRdvMinutes,
      delaiRappelMinutes: delaiRappelMinutes ?? this.delaiRappelMinutes,
      notificationsActives: notificationsActives ?? this.notificationsActives,
      parametresNotifications: parametresNotifications ?? this.parametresNotifications,
      notificationsGroupees: notificationsGroupees ?? this.notificationsGroupees,
      actionsNotifications: actionsNotifications ?? this.actionsNotifications,
      horaires: horaires ?? this.horaires,
      verrouillageActif: verrouillageActif ?? this.verrouillageActif,
      pinCode: pinCode ?? this.pinCode,
      biometrieActive: biometrieActive ?? this.biometrieActive,
    );
  }

  static AppSettings defaut() {
    const horairesTravail = HorairesOuverture(
      ouvert: true,
      heureOuverture: '09:00',
      heureFermeture: '18:00',
    );
    
    const horairesFerme = HorairesOuverture(
      ouvert: false,
      heureOuverture: '09:00',
      heureFermeture: '18:00',
    );

    const parametresDefaut = ParametresNotification(
      active: true,
      delaiMinutes: 60,
      son: true,
      vibration: true,
    );

    return AppSettings(
      parametresNotifications: {
        TypeNotification.rappelRdv: parametresDefaut,
        TypeNotification.conflit: parametresDefaut.copyWith(delaiMinutes: 0),
        TypeNotification.anniversaire: parametresDefaut.copyWith(delaiMinutes: 0),
        TypeNotification.relance: parametresDefaut.copyWith(delaiMinutes: 1440), // 24h
        TypeNotification.statut: parametresDefaut.copyWith(delaiMinutes: 0),
      },
      horaires: {
        1: horairesTravail, // Lundi
        2: horairesTravail, // Mardi
        3: horairesTravail, // Mercredi
        4: horairesTravail, // Jeudi
        5: horairesTravail, // Vendredi
        6: horairesFerme,   // Samedi
        7: horairesFerme,   // Dimanche
      },
    );
  }

  bool estOuvert(DateTime dateTime) {
    final jour = dateTime.weekday;
    final horaire = horaires[jour];
    
    if (horaire == null || !horaire.ouvert) return false;
    
    final heure = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return heure.compareTo(horaire.heureOuverture) >= 0 && heure.compareTo(horaire.heureFermeture) <= 0;
  }

  @override
  String toString() {
    return 'AppSettings(langue: $langue, themeMode: $themeMode, dureeDefaut: ${dureeDefautMinutes}min)';
  }
}
