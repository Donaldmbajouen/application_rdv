import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rendez_vous.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';
import 'notification_provider.dart';

/// État pour la gestion des rendez-vous
class RendezVousState {
  final List<RendezVous> rendezVous;
  final bool isLoading;
  final String? error;
  final DateTime? dateFiltre;
  final int? clientFiltre;
  final StatutRendezVous? statutFiltre;
  final List<RendezVous> conflits;

  const RendezVousState({
    this.rendezVous = const [],
    this.isLoading = false,
    this.error,
    this.dateFiltre,
    this.clientFiltre,
    this.statutFiltre,
    this.conflits = const [],
  });

  RendezVousState copyWith({
    List<RendezVous>? rendezVous,
    bool? isLoading,
    String? error,
    DateTime? dateFiltre,
    int? clientFiltre,
    StatutRendezVous? statutFiltre,
    List<RendezVous>? conflits,
  }) {
    return RendezVousState(
      rendezVous: rendezVous ?? this.rendezVous,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateFiltre: dateFiltre,
      clientFiltre: clientFiltre,
      statutFiltre: statutFiltre,
      conflits: conflits ?? this.conflits,
    );
  }

  List<RendezVous> get filteredRendezVous {
    var filtered = rendezVous.where((rdv) {
      // Filtre par date
      if (dateFiltre != null) {
        final dateRdv = DateTime(rdv.dateHeure.year, rdv.dateHeure.month, rdv.dateHeure.day);
        final dateRecherche = DateTime(dateFiltre!.year, dateFiltre!.month, dateFiltre!.day);
        if (!dateRdv.isAtSameMomentAs(dateRecherche)) return false;
      }
      
      // Filtre par client
      if (clientFiltre != null && rdv.clientId != clientFiltre) return false;
      
      // Filtre par statut
      if (statutFiltre != null && rdv.statut != statutFiltre) return false;
      
      return true;
    }).toList();

    // Tri par date/heure
    filtered.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    return filtered;
  }

  List<RendezVous> get rendezVousAujourdhui {
    final aujourdhui = DateTime.now();
    final debutJournee = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
    final finJournee = debutJournee.add(const Duration(days: 1));
    
    return rendezVous.where((rdv) =>
        rdv.dateHeure.isAfter(debutJournee) && rdv.dateHeure.isBefore(finJournee)
    ).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  }

  List<RendezVous> get prochainRendezVous {
    final maintenant = DateTime.now();
    return rendezVous.where((rdv) =>
        rdv.dateHeure.isAfter(maintenant) && !rdv.estAnnule
    ).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  }
}

/// Notifier pour la gestion des rendez-vous
class RendezVousNotifier extends StateNotifier<RendezVousState> {
  final DatabaseHelper _db;
  final Ref _ref;

  RendezVousNotifier(this._db, this._ref) : super(const RendezVousState()) {
    loadRendezVous();
  }

  /// Charge tous les rendez-vous depuis la base
  Future<void> loadRendezVous() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rdvs = await _db.getRendezVous();
      state = state.copyWith(rendezVous: rdvs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Charge les rendez-vous pour une date spécifique
  Future<void> loadRendezVousParDate(DateTime date) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rdvs = await _db.getRendezVous(date: date);
      state = state.copyWith(rendezVous: rdvs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Charge les rendez-vous pour un client spécifique
  Future<void> loadRendezVousParClient(int clientId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rdvs = await _db.getRendezVous(clientId: clientId);
      state = state.copyWith(rendezVous: rdvs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Ajoute un nouveau rendez-vous avec vérification des conflits
  Future<bool> ajouterRendezVous(RendezVous rdv) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Vérifier les conflits
      final conflits = await _db.getConflits(rdv.dateHeure, rdv.dureeMinutes);
      if (conflits.isNotEmpty) {
        state = state.copyWith(
          conflits: conflits,
          error: 'Conflit détecté avec ${conflits.length} autre(s) rendez-vous',
          isLoading: false,
        );
        return false;
      }
      
      final id = await _db.insertRendezVous(rdv);
      if (id > 0) {
        await loadRendezVous();
        
        // Programmer les notifications pour le nouveau RDV
        final rdvAvecId = rdv.copyWith(id: id);
        final notificationNotifier = _ref.read(notificationProvider.notifier);
        await notificationNotifier.programmerNotificationsRdv(rdvAvecId);
        
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Ajoute un rendez-vous en forçant malgré les conflits
  Future<bool> ajouterRendezVousMalgreConflits(RendezVous rdv) async {
    try {
      state = state.copyWith(isLoading: true, error: null, conflits: []);
      final id = await _db.insertRendezVous(rdv);
      if (id > 0) {
        await loadRendezVous();
        
        // Programmer les notifications pour le nouveau RDV
        final rdvAvecId = rdv.copyWith(id: id);
        final notificationNotifier = _ref.read(notificationProvider.notifier);
        await notificationNotifier.programmerNotificationsRdv(rdvAvecId);
        
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Met à jour un rendez-vous existant
  Future<bool> modifierRendezVous(RendezVous rdv) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Vérifier les conflits (exclure le RDV en cours de modification)
      final conflits = await _db.getConflits(rdv.dateHeure, rdv.dureeMinutes, excludeId: rdv.id);
      if (conflits.isNotEmpty) {
        state = state.copyWith(
          conflits: conflits,
          error: 'Conflit détecté avec ${conflits.length} autre(s) rendez-vous',
          isLoading: false,
        );
        return false;
      }
      
      final result = await _db.updateRendezVous(rdv);
      if (result > 0) {
        await loadRendezVous();
        
        // Reprogrammer les notifications pour le RDV modifié
        final notificationNotifier = _ref.read(notificationProvider.notifier);
        await notificationNotifier.annulerNotificationsRdv(rdv.id!);
        await notificationNotifier.programmerNotificationsRdv(rdv);
        
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Supprime un rendez-vous
  Future<bool> supprimerRendezVous(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Annuler les notifications avant suppression
      final notificationNotifier = _ref.read(notificationProvider.notifier);
      await notificationNotifier.annulerNotificationsRdv(id);
      
      final result = await _db.deleteRendezVous(id);
      if (result > 0) {
        await loadRendezVous();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Change le statut d'un rendez-vous
  Future<bool> changerStatutRendezVous(int id, StatutRendezVous nouveauStatut) async {
    try {
      final rdv = state.rendezVous.firstWhere((r) => r.id == id);
      final ancienStatut = rdv.statut;
      final rdvModifie = rdv.copyWith(statut: nouveauStatut);
      
      final result = await modifierRendezVous(rdvModifie);
      
      // Notifier le changement de statut
      if (result) {
        final notificationNotifier = _ref.read(notificationProvider.notifier);
        await notificationNotifier.notifierChangementStatut(rdvModifie, ancienStatut);
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Récupère un rendez-vous par son ID
  Future<RendezVous?> obtenirRendezVous(int id) async {
    try {
      return await _db.getRendezVousById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Vérifie les conflits pour un créneau donné
  Future<List<RendezVous>> verifierConflits(DateTime dateHeure, int dureeMinutes, {int? excludeId}) async {
    try {
      return await _db.getConflits(dateHeure, dureeMinutes, excludeId: excludeId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Applique un filtre par date
  void filtrerParDate(DateTime? date) {
    state = state.copyWith(dateFiltre: date);
  }

  /// Applique un filtre par client
  void filtrerParClient(int? clientId) {
    state = state.copyWith(clientFiltre: clientId);
  }

  /// Applique un filtre par statut
  void filtrerParStatut(StatutRendezVous? statut) {
    state = state.copyWith(statutFiltre: statut);
  }

  /// Obtient les rendez-vous pour une période donnée
  List<RendezVous> obtenirRendezVousPeriode(DateTime debut, DateTime fin) {
    return state.rendezVous.where((rdv) =>
        rdv.dateHeure.isAfter(debut) && rdv.dateHeure.isBefore(fin)
    ).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  }

  /// Obtient les créneaux libres pour une date donnée
  List<DateTime> obtenirCreneauxLibres(DateTime date, int dureeMinutes, {
    String heureDebut = '09:00',
    String heureFin = '18:00',
    int pauseMinutes = 15,
  }) {
    final creneauxLibres = <DateTime>[];
    final rdvsJour = state.rendezVous.where((rdv) {
      final dateRdv = DateTime(rdv.dateHeure.year, rdv.dateHeure.month, rdv.dateHeure.day);
      final dateRecherche = DateTime(date.year, date.month, date.day);
      return dateRdv.isAtSameMomentAs(dateRecherche) && !rdv.estAnnule;
    }).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

    final heureDebutParts = heureDebut.split(':');
    final heureFinParts = heureFin.split(':');
    var creneauActuel = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(heureDebutParts[0]),
      int.parse(heureDebutParts[1]),
    );
    final finJournee = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(heureFinParts[0]),
      int.parse(heureFinParts[1]),
    );

    while (creneauActuel.add(Duration(minutes: dureeMinutes)).isBefore(finJournee) ||
           creneauActuel.add(Duration(minutes: dureeMinutes)).isAtSameMomentAs(finJournee)) {
      
      final finCreneau = creneauActuel.add(Duration(minutes: dureeMinutes));
      bool conflit = false;

      for (final rdv in rdvsJour) {
        if (creneauActuel.isBefore(rdv.dateFin) && finCreneau.isAfter(rdv.dateHeure)) {
          conflit = true;
          break;
        }
      }

      if (!conflit) {
        creneauxLibres.add(creneauActuel);
      }

      creneauActuel = creneauActuel.add(Duration(minutes: pauseMinutes));
    }

    return creneauxLibres;
  }

  /// Efface tous les filtres
  void effacerFiltres() {
    state = state.copyWith(
      dateFiltre: null,
      clientFiltre: null,
      statutFiltre: null,
    );
  }

  /// Efface les conflits
  void effacerConflits() {
    state = state.copyWith(conflits: []);
  }

  /// Efface l'erreur
  void effacerErreur() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour la gestion des rendez-vous
/// 
/// Usage:
/// ```dart
/// // Lire l'état
/// final rdvState = ref.watch(rendezVousProvider);
/// 
/// // Accéder aux méthodes
/// final rdvNotifier = ref.read(rendezVousProvider.notifier);
/// await rdvNotifier.ajouterRendezVous(nouveauRdv);
/// 
/// // Filtrer
/// rdvNotifier.filtrerParDate(DateTime.now());
/// final rdvsFiltres = rdvState.filteredRendezVous;
/// 
/// // Vérifier conflits
/// final conflits = await rdvNotifier.verifierConflits(dateTime, 30);
/// ```
final rendezVousProvider = StateNotifierProvider<RendezVousNotifier, RendezVousState>((ref) {
  final db = ref.watch(databaseProvider);
  return RendezVousNotifier(db, ref);
});

/// Provider pour un rendez-vous spécifique par ID
/// 
/// Usage:
/// ```dart
/// final rdv = ref.watch(rendezVousByIdProvider(rdvId));
/// rdv.when(
///   data: (rdv) => rdv != null ? Text(rdv.clientNomComplet) : Text('RDV non trouvé'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Erreur: $err'),
/// );
/// ```
final rendezVousByIdProvider = FutureProvider.family<RendezVous?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return await db.getRendezVousById(id);
});

/// Provider pour les rendez-vous d'aujourd'hui
/// 
/// Usage:
/// ```dart
/// final rdvsAujourdhui = ref.watch(rendezVousAujourdhuiProvider);
/// ```
final rendezVousAujourdhuiProvider = Provider<List<RendezVous>>((ref) {
  final rdvState = ref.watch(rendezVousProvider);
  return rdvState.rendezVousAujourdhui;
});

/// Provider pour les prochains rendez-vous
/// 
/// Usage:
/// ```dart
/// final prochainsRdvs = ref.watch(prochainsRendezVousProvider);
/// ```
final prochainsRendezVousProvider = Provider<List<RendezVous>>((ref) {
  final rdvState = ref.watch(rendezVousProvider);
  return rdvState.prochainRendezVous;
});

/// Provider pour les rendez-vous par date
/// 
/// Usage:
/// ```dart
/// final rdvsDate = ref.watch(rendezVousByDateProvider(DateTime.now()));
/// ```
final rendezVousByDateProvider = Provider.family<List<RendezVous>, DateTime>((ref, date) {
  final rdvState = ref.watch(rendezVousProvider);
  final dateRecherche = DateTime(date.year, date.month, date.day);
  
  return rdvState.rendezVous.where((rdv) {
    final dateRdv = DateTime(rdv.dateHeure.year, rdv.dateHeure.month, rdv.dateHeure.day);
    return dateRdv.isAtSameMomentAs(dateRecherche);
  }).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
});

/// Provider pour les créneaux libres d'une date
/// 
/// Usage:
/// ```dart
/// final creneaux = ref.watch(creneauxLibresProvider((date: DateTime.now(), duree: 30)));
/// ```
final creneauxLibresProvider = Provider.family<List<DateTime>, Map<String, dynamic>>((ref, params) {
  final rdvNotifier = ref.read(rendezVousProvider.notifier);
  return rdvNotifier.obtenirCreneauxLibres(
    params['date'] as DateTime,
    params['duree'] as int,
    heureDebut: params['heureDebut'] as String? ?? '09:00',
    heureFin: params['heureFin'] as String? ?? '18:00',
    pauseMinutes: params['pauseMinutes'] as int? ?? 15,
  );
});

/// Provider pour les statistiques des rendez-vous
/// 
/// Usage:
/// ```dart
/// final stats = ref.watch(rendezVousStatsProvider);
/// Text('Total RDV: ${stats['total']}');
/// ```
final rendezVousStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final rdvState = ref.watch(rendezVousProvider);
  final rdvs = rdvState.rendezVous;
  
  if (rdvs.isEmpty) {
    return {
      'total': 0,
      'confirmes': 0,
      'annules': 0,
      'completes': 0,
      'enAttente': 0,
      'aujourdhui': 0,
      'semaine': 0,
      'revenuTotal': 0.0,
      'revenuMoyen': 0.0,
    };
  }

  final aujourdhui = DateTime.now();
  final debutJournee = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  final finJournee = debutJournee.add(const Duration(days: 1));
  final debutSemaine = debutJournee.subtract(Duration(days: aujourdhui.weekday - 1));
  final finSemaine = debutSemaine.add(const Duration(days: 7));

  final rdvsAujourdhui = rdvs.where((rdv) =>
      rdv.dateHeure.isAfter(debutJournee) && rdv.dateHeure.isBefore(finJournee)
  ).length;

  final rdvsSemaine = rdvs.where((rdv) =>
      rdv.dateHeure.isAfter(debutSemaine) && rdv.dateHeure.isBefore(finSemaine)
  ).length;

  final rdvsCompletes = rdvs.where((rdv) => rdv.estComplete).toList();
  final revenuTotal = rdvsCompletes.fold(0.0, (sum, rdv) => sum + rdv.prix);

  return {
    'total': rdvs.length,
    'confirmes': rdvs.where((rdv) => rdv.estConfirme).length,
    'annules': rdvs.where((rdv) => rdv.estAnnule).length,
    'completes': rdvsCompletes.length,
    'enAttente': rdvs.where((rdv) => rdv.estEnAttente).length,
    'aujourdhui': rdvsAujourdhui,
    'semaine': rdvsSemaine,
    'revenuTotal': revenuTotal,
    'revenuMoyen': rdvsCompletes.isNotEmpty ? revenuTotal / rdvsCompletes.length : 0.0,
  };
});
