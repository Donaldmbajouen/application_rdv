import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

/// État pour la gestion des services
class ServiceState {
  final List<Service> services;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? categorieFiltre;
  final bool afficherInactifs;

  const ServiceState({
    this.services = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categorieFiltre,
    this.afficherInactifs = false,
  });

  ServiceState copyWith({
    List<Service>? services,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categorieFiltre,
    bool? afficherInactifs,
  }) {
    return ServiceState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categorieFiltre: categorieFiltre,
      afficherInactifs: afficherInactifs ?? this.afficherInactifs,
    );
  }

  List<Service> get filteredServices {
    var filtered = services.where((service) {
      // Filtre par statut actif/inactif
      if (!afficherInactifs && !service.actif) return false;
      
      // Filtre par catégorie
      if (categorieFiltre != null && 
          service.categorie?.toLowerCase() != categorieFiltre!.toLowerCase()) {
        return false;
      }
      
      // Filtre par recherche
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return service.nom.toLowerCase().contains(query) ||
               service.description?.toLowerCase().contains(query) == true ||
               service.categorie?.toLowerCase().contains(query) == true ||
               service.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      
      return true;
    }).toList();

    // Tri par nom
    filtered.sort((a, b) => a.nom.compareTo(b.nom));
    return filtered;
  }

  List<String> get categories {
    final cats = services
        .where((s) => s.categorie != null)
        .map((s) => s.categorie!)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }
}

/// Notifier pour la gestion des services
class ServiceNotifier extends StateNotifier<ServiceState> {
  final DatabaseHelper _db;

  ServiceNotifier(this._db) : super(const ServiceState()) {
    loadServices();
  }

  /// Charge tous les services depuis la base
  Future<void> loadServices() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final services = await _db.getServices();
      state = state.copyWith(services: services, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Charge seulement les services actifs
  Future<void> loadServicesActifs() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final services = await _db.getServices(activeOnly: true);
      state = state.copyWith(services: services, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Ajoute un nouveau service
  Future<bool> ajouterService(Service service) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final id = await _db.insertService(service);
      if (id > 0) {
        await loadServices();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Met à jour un service existant
  Future<bool> modifierService(Service service) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _db.updateService(service);
      if (result > 0) {
        await loadServices();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Supprime un service
  Future<bool> supprimerService(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _db.deleteService(id);
      if (result > 0) {
        await loadServices();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Récupère un service par son ID
  Future<Service?> obtenirService(int id) async {
    try {
      return await _db.getService(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Active/désactive un service
  Future<bool> changerStatutService(int id, bool actif) async {
    final service = state.services.firstWhere((s) => s.id == id);
    final serviceModifie = service.copyWith(actif: actif);
    return await modifierService(serviceModifie);
  }

  /// Met à jour la requête de recherche
  void chercherServices(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Filtre par catégorie
  void filtrerParCategorie(String? categorie) {
    state = state.copyWith(categorieFiltre: categorie);
  }

  /// Affiche/masque les services inactifs
  void afficherInactifs(bool afficher) {
    state = state.copyWith(afficherInactifs: afficher);
  }

  /// Filtre les services par tag
  List<Service> obtenirServicesParTag(String tag) {
    return state.services.where((service) => 
        service.tags.any((t) => t.toLowerCase() == tag.toLowerCase())
    ).toList();
  }

  /// Filtre les services par gamme de prix
  List<Service> obtenirServicesParPrix(double minPrix, double maxPrix) {
    return state.services.where((service) => 
        service.prix >= minPrix && service.prix <= maxPrix
    ).toList();
  }

  /// Filtre les services par durée
  List<Service> obtenirServicesParDuree(int minDuree, int maxDuree) {
    return state.services.where((service) => 
        service.dureeMinutes >= minDuree && service.dureeMinutes <= maxDuree
    ).toList();
  }

  /// Obtient les services les plus populaires (basé sur un critère)
  List<Service> obtenirServicesPopulaires({int limite = 5}) {
    final services = List<Service>.from(state.services.where((s) => s.actif));
    // Tri par prix décroissant comme proxy de popularité
    services.sort((a, b) => b.prix.compareTo(a.prix));
    return services.take(limite).toList();
  }

  /// Obtient tous les tags utilisés
  List<String> obtenirTousLesTags() {
    final tags = <String>{};
    for (final service in state.services) {
      tags.addAll(service.tags);
    }
    return tags.toList()..sort();
  }

  /// Efface tous les filtres
  void effacerFiltres() {
    state = state.copyWith(
      searchQuery: '',
      categorieFiltre: null,
      afficherInactifs: false,
    );
  }

  /// Efface l'erreur
  void effacerErreur() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour la gestion des services
/// 
/// Usage:
/// ```dart
/// // Lire l'état
/// final serviceState = ref.watch(serviceProvider);
/// 
/// // Accéder aux méthodes
/// final serviceNotifier = ref.read(serviceProvider.notifier);
/// await serviceNotifier.ajouterService(nouveauService);
/// 
/// // Rechercher et filtrer
/// serviceNotifier.chercherServices('Coupe');
/// serviceNotifier.filtrerParCategorie('Coiffure');
/// final servicesFiltres = serviceState.filteredServices;
/// ```
final serviceProvider = StateNotifierProvider<ServiceNotifier, ServiceState>((ref) {
  final db = ref.watch(databaseProvider);
  return ServiceNotifier(db);
});

/// Provider pour un service spécifique par ID
/// 
/// Usage:
/// ```dart
/// final service = ref.watch(serviceByIdProvider(serviceId));
/// service.when(
///   data: (service) => service != null ? Text(service.nom) : Text('Service non trouvé'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Erreur: $err'),
/// );
/// ```
final serviceByIdProvider = FutureProvider.family<Service?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return await db.getService(id);
});

/// Provider pour les services actifs uniquement
/// 
/// Usage:
/// ```dart
/// final servicesActifs = ref.watch(servicesActifsProvider);
/// ```
final servicesActifsProvider = Provider<List<Service>>((ref) {
  final serviceState = ref.watch(serviceProvider);
  return serviceState.services.where((service) => service.actif).toList();
});

/// Provider pour les services par catégorie
/// 
/// Usage:
/// ```dart
/// final servicesCoiffure = ref.watch(servicesByCategorieProvider('Coiffure'));
/// ```
final servicesByCategorieProvider = Provider.family<List<Service>, String>((ref, categorie) {
  final serviceState = ref.watch(serviceProvider);
  return serviceState.services.where((service) => 
      service.categorie?.toLowerCase() == categorie.toLowerCase()
  ).toList();
});

/// Provider pour les statistiques des services
/// 
/// Usage:
/// ```dart
/// final stats = ref.watch(serviceStatsProvider);
/// Text('Total services: ${stats['total']}');
/// Text('Prix moyen: ${stats['prixMoyen'].toStringAsFixed(2)}€');
/// ```
final serviceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final serviceState = ref.watch(serviceProvider);
  final services = serviceState.services;
  final servicesActifs = services.where((s) => s.actif).toList();
  
  if (services.isEmpty) {
    return {
      'total': 0,
      'actifs': 0,
      'inactifs': 0,
      'prixMoyen': 0.0,
      'prixMin': 0.0,
      'prixMax': 0.0,
      'dureeMoyenne': 0,
      'categoriesCount': 0,
      'tagsPopulaires': <Map<String, dynamic>>[],
    };
  }

  final prix = servicesActifs.map((s) => s.prix).toList();
  final durees = servicesActifs.map((s) => s.dureeMinutes).toList();

  return {
    'total': services.length,
    'actifs': servicesActifs.length,
    'inactifs': services.length - servicesActifs.length,
    'prixMoyen': prix.isNotEmpty ? prix.reduce((a, b) => a + b) / prix.length : 0.0,
    'prixMin': prix.isNotEmpty ? prix.reduce((a, b) => a < b ? a : b) : 0.0,
    'prixMax': prix.isNotEmpty ? prix.reduce((a, b) => a > b ? a : b) : 0.0,
    'dureeMoyenne': durees.isNotEmpty ? durees.reduce((a, b) => a + b) ~/ durees.length : 0,
    'categoriesCount': serviceState.categories.length,
    'tagsPopulaires': _getTopServiceTags(services, 5),
  };
});

List<Map<String, dynamic>> _getTopServiceTags(List<Service> services, int limit) {
  final tagCounts = <String, int>{};
  
  for (final service in services) {
    for (final tag in service.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
  }
  
  final sortedTags = tagCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return sortedTags.take(limit)
      .map((entry) => {'tag': entry.key, 'count': entry.value})
      .toList();
}
