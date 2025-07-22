import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

/// État pour la gestion des paramètres
class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? error;
  final bool hasChanges;

  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
    this.hasChanges = false,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? error,
    bool? hasChanges,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}

/// Notifier pour la gestion des paramètres
class SettingsNotifier extends StateNotifier<SettingsState> {
  final DatabaseHelper _db;

  SettingsNotifier(this._db) : super(SettingsState(settings: AppSettings.defaut())) {
    loadSettings();
  }

  /// Charge les paramètres depuis la base de données
  Future<void> loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final settingsJson = await _db.getSetting('app_settings');
      late AppSettings settings;
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        settings = AppSettings.fromMap(settingsMap);
      } else {
        settings = AppSettings.defaut();
        await sauvegarderSettings(settings);
      }
      
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        hasChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        settings: AppSettings.defaut(),
      );
    }
  }

  /// Sauvegarde les paramètres en base
  Future<bool> sauvegarderSettings(AppSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final settingsJson = jsonEncode(settings.toMap());
      await _db.saveSetting('app_settings', settingsJson);
      
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        hasChanges: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Met à jour la langue
  Future<bool> changerLangue(String langue) async {
    final nouveauxSettings = state.settings.copyWith(langue: langue);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour le mode thème
  Future<bool> changerTheme(bool themeMode) async {
    final nouveauxSettings = state.settings.copyWith(themeMode: themeMode);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour la durée par défaut des RDV
  Future<bool> changerDureeDefaut(int dureeMinutes) async {
    final nouveauxSettings = state.settings.copyWith(dureeDefautMinutes: dureeMinutes);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour la pause entre RDV
  Future<bool> changerPauseEntreRdv(int pauseMinutes) async {
    final nouveauxSettings = state.settings.copyWith(pauseEntreRdvMinutes: pauseMinutes);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour le délai de rappel
  Future<bool> changerDelaiRappel(int delaiMinutes) async {
    final nouveauxSettings = state.settings.copyWith(delaiRappelMinutes: delaiMinutes);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Active/désactive les notifications
  Future<bool> changerNotifications(bool actives) async {
    final nouveauxSettings = state.settings.copyWith(notificationsActives: actives);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour les horaires d'ouverture
  Future<bool> changerHoraires(Map<int, HorairesOuverture> horaires) async {
    final nouveauxSettings = state.settings.copyWith(horaires: horaires);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour les horaires pour un jour spécifique
  Future<bool> changerHoraireJour(int jour, HorairesOuverture horaire) async {
    final nouveauxHoraires = Map<int, HorairesOuverture>.from(state.settings.horaires);
    nouveauxHoraires[jour] = horaire;
    return await changerHoraires(nouveauxHoraires);
  }

  /// Active/désactive le verrouillage
  Future<bool> changerVerrouillage(bool actif) async {
    final nouveauxSettings = state.settings.copyWith(verrouillageActif: actif);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Met à jour le code PIN
  Future<bool> changerCodePin(String? pinCode) async {
    final nouveauxSettings = state.settings.copyWith(pinCode: pinCode);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Active/désactive la biométrie
  Future<bool> changerBiometrie(bool active) async {
    final nouveauxSettings = state.settings.copyWith(biometrieActive: active);
    state = state.copyWith(settings: nouveauxSettings, hasChanges: true);
    return await sauvegarderSettings(nouveauxSettings);
  }

  /// Remet les paramètres par défaut
  Future<bool> reinitialiserParametres() async {
    final parametresDefaut = AppSettings.defaut();
    state = state.copyWith(settings: parametresDefaut, hasChanges: true);
    return await sauvegarderSettings(parametresDefaut);
  }

  /// Applique temporairement des modifications sans sauvegarder
  void appliquerModificationsTemporaires(AppSettings settings) {
    state = state.copyWith(settings: settings, hasChanges: true);
  }

  /// Annule les modifications non sauvegardées
  Future<void> annulerModifications() async {
    await loadSettings();
  }

  /// Vérifie si l'app est ouverte à une date/heure donnée
  bool estOuvert(DateTime dateTime) {
    return state.settings.estOuvert(dateTime);
  }

  /// Obtient les horaires pour un jour donné
  HorairesOuverture? obtenirHoraireJour(int jour) {
    return state.settings.horaires[jour];
  }

  /// Obtient les jours d'ouverture
  List<int> obtenirJoursOuverture() {
    return state.settings.horaires.entries
        .where((entry) => entry.value.ouvert)
        .map((entry) => entry.key)
        .toList()..sort();
  }

  /// Valide un code PIN
  bool validerCodePin(String code) {
    return state.settings.pinCode == code;
  }

  /// Efface l'erreur
  void effacerErreur() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour la gestion des paramètres
/// 
/// Usage:
/// ```dart
/// // Lire l'état
/// final settingsState = ref.watch(settingsProvider);
/// final settings = settingsState.settings;
/// 
/// // Accéder aux méthodes
/// final settingsNotifier = ref.read(settingsProvider.notifier);
/// await settingsNotifier.changerTheme(true);
/// 
/// // Vérifier les horaires
/// final estOuvert = settingsNotifier.estOuvert(DateTime.now());
/// ```
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsNotifier(db);
});

/// Provider pour accéder directement aux paramètres
/// 
/// Usage:
/// ```dart
/// final settings = ref.watch(appSettingsProvider);
/// final themeMode = settings.themeMode;
/// ```
final appSettingsProvider = Provider<AppSettings>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.settings;
});

/// Provider pour le mode thème
/// 
/// Usage:
/// ```dart
/// final isDarkMode = ref.watch(themeModeProvider);
/// ```
final themeModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.themeMode;
});

/// Provider pour la langue
/// 
/// Usage:
/// ```dart
/// final langue = ref.watch(langueProvider);
/// ```
final langueProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.langue;
});

/// Provider pour les notifications
/// 
/// Usage:
/// ```dart
/// final notificationsActives = ref.watch(notificationsProvider);
/// ```
final notificationsProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.notificationsActives;
});

/// Provider pour les horaires d'ouverture
/// 
/// Usage:
/// ```dart
/// final horaires = ref.watch(horairesProvider);
/// ```
final horairesProvider = Provider<Map<int, HorairesOuverture>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.horaires;
});

/// Provider pour vérifier si l'app est ouverte maintenant
/// 
/// Usage:
/// ```dart
/// final estOuvertMaintenant = ref.watch(estOuvertMaintenantProvider);
/// ```
final estOuvertMaintenantProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.estOuvert(DateTime.now());
});

/// Provider pour les horaires d'un jour spécifique
/// 
/// Usage:
/// ```dart
/// final horairesLundi = ref.watch(horaireJourProvider(1)); // 1 = Lundi
/// ```
final horaireJourProvider = Provider.family<HorairesOuverture?, int>((ref, jour) {
  final horaires = ref.watch(horairesProvider);
  return horaires[jour];
});

/// Provider pour la sécurité (verrouillage actif)
/// 
/// Usage:
/// ```dart
/// final verrouillageActif = ref.watch(verrouillageProvider);
/// ```
final verrouillageProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.verrouillageActif;
});

/// Provider pour la biométrie
/// 
/// Usage:
/// ```dart
/// final biometrieActive = ref.watch(biometrieProvider);
/// ```
final biometrieProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.biometrieActive;
});

/// Provider pour les paramètres de RDV
/// 
/// Usage:
/// ```dart
/// final paramsRdv = ref.watch(parametresRdvProvider);
/// final dureeDefaut = paramsRdv['dureeDefaut'];
/// ```
final parametresRdvProvider = Provider<Map<String, int>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return {
    'dureeDefaut': settings.dureeDefautMinutes,
    'pauseEntreRdv': settings.pauseEntreRdvMinutes,
    'delaiRappel': settings.delaiRappelMinutes,
  };
});

/// Provider pour vérifier s'il y a des modifications non sauvegardées
/// 
/// Usage:
/// ```dart
/// final hasChanges = ref.watch(hasUnsavedChangesProvider);
/// if (hasChanges) {
///   // Afficher un avertissement avant de quitter
/// }
/// ```
final hasUnsavedChangesProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return settingsState.hasChanges;
});
