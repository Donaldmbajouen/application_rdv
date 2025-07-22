import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

/// État pour la gestion des clients
class ClientState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ClientState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ClientState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Client> get filteredClients {
    if (searchQuery.isEmpty) return clients;
    
    final query = searchQuery.toLowerCase();
    return clients.where((client) {
      return client.nom.toLowerCase().contains(query) ||
             client.prenom.toLowerCase().contains(query) ||
             client.email?.toLowerCase().contains(query) == true ||
             client.telephone?.contains(query) == true ||
             client.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }
}

/// Notifier pour la gestion des clients
class ClientNotifier extends StateNotifier<ClientState> {
  final DatabaseHelper _db;

  ClientNotifier(this._db) : super(const ClientState()) {
    loadClients();
  }

  /// Charge tous les clients depuis la base
  Future<void> loadClients() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final clients = await _db.getClients();
      state = state.copyWith(clients: clients, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Ajoute un nouveau client
  Future<bool> ajouterClient(Client client) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final id = await _db.insertClient(client);
      if (id > 0) {
        await loadClients();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Met à jour un client existant
  Future<bool> modifierClient(Client client) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _db.updateClient(client);
      if (result > 0) {
        await loadClients();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Supprime un client
  Future<bool> supprimerClient(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _db.deleteClient(id);
      if (result > 0) {
        await loadClients();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Récupère un client par son ID
  Future<Client?> obtenirClient(int id) async {
    try {
      return await _db.getClient(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Met à jour la requête de recherche
  void chercherClients(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Filtre les clients par tag
  List<Client> obtenirClientsParTag(String tag) {
    return state.clients.where((client) => 
        client.tags.any((t) => t.toLowerCase() == tag.toLowerCase())
    ).toList();
  }

  /// Obtient les clients les plus récents
  List<Client> obtenirClientsRecents({int limite = 5}) {
    final clients = List<Client>.from(state.clients);
    clients.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return clients.take(limite).toList();
  }

  /// Obtient tous les tags utilisés
  List<String> obtenirTousLesTags() {
    final tags = <String>{};
    for (final client in state.clients) {
      tags.addAll(client.tags);
    }
    return tags.toList()..sort();
  }

  /// Efface l'erreur
  void effacerErreur() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour la gestion des clients
/// 
/// Usage:
/// ```dart
/// // Lire l'état
/// final clientState = ref.watch(clientProvider);
/// 
/// // Accéder aux méthodes
/// final clientNotifier = ref.read(clientProvider.notifier);
/// await clientNotifier.ajouterClient(nouveauClient);
/// 
/// // Rechercher
/// clientNotifier.chercherClients('Martin');
/// final clientsFiltres = clientState.filteredClients;
/// ```
final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>((ref) {
  final db = ref.watch(databaseProvider);
  return ClientNotifier(db);
});

/// Provider pour un client spécifique par ID
/// 
/// Usage:
/// ```dart
/// final client = ref.watch(clientByIdProvider(clientId));
/// client.when(
///   data: (client) => client != null ? Text(client.nomComplet) : Text('Client non trouvé'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Erreur: $err'),
/// );
/// ```
final clientByIdProvider = FutureProvider.family<Client?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return await db.getClient(id);
});

/// Provider pour les clients filtrés par tag
/// 
/// Usage:
/// ```dart
/// final clientsVIP = ref.watch(clientsByTagProvider('VIP'));
/// ```
final clientsByTagProvider = Provider.family<List<Client>, String>((ref, tag) {
  final clientState = ref.watch(clientProvider);
  return clientState.clients.where((client) => 
      client.tags.any((t) => t.toLowerCase() == tag.toLowerCase())
  ).toList();
});

/// Provider pour les statistiques des clients
/// 
/// Usage:
/// ```dart
/// final stats = ref.watch(clientStatsProvider);
/// Text('Total clients: ${stats.total}');
/// ```
final clientStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final clientState = ref.watch(clientProvider);
  final clients = clientState.clients;
  
  return {
    'total': clients.length,
    'avecTelephone': clients.where((c) => c.telephone?.isNotEmpty == true).length,
    'avecEmail': clients.where((c) => c.email?.isNotEmpty == true).length,
    'avecTags': clients.where((c) => c.tags.isNotEmpty).length,
    'tagsPopulaires': _getTopTags(clients, 5),
  };
});

List<Map<String, dynamic>> _getTopTags(List<Client> clients, int limit) {
  final tagCounts = <String, int>{};
  
  for (final client in clients) {
    for (final tag in client.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
  }
  
  final sortedTags = tagCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return sortedTags.take(limit)
      .map((entry) => {'tag': entry.key, 'count': entry.value})
      .toList();
}
