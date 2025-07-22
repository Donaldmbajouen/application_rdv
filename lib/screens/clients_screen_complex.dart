import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../widgets/client_card.dart';
import '../widgets/client_search_bar.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  List<String> _selectedTags = [];

  List<dynamic> _getFilteredClients(ClientState clientState) {
    var clients = clientState.filteredClients;
    
    // Filtrer par tags sélectionnés
    if (_selectedTags.isNotEmpty) {
      clients = clients.where((client) {
        return _selectedTags.every((selectedTag) => 
          client.tags.any((clientTag) => 
            clientTag.toLowerCase() == selectedTag.toLowerCase()));
      }).toList();
    }
    
    return clients;
  }

  Future<void> _refreshClients() async {
    await ref.read(clientProvider.notifier).loadClients();
  }

  Future<void> _deleteClient(BuildContext context, int clientId, String clientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Êtes-vous sûr de vouloir supprimer $clientName ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(clientProvider.notifier).supprimerClient(clientId);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$clientName supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final clientStats = ref.watch(clientStatsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredClients = _getFilteredClients(clientState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshClients,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques en haut
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${clientStats['total']} clients',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${clientStats['avecTelephone']} avec téléphone • ${clientStats['avecEmail']} avec email',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.people,
                      size: 40,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Barre de recherche
          ClientSearchBar(
            onSelectedTagsChanged: (selectedTags) {
              setState(() {
                _selectedTags = selectedTags;
              });
            },
          ),
          
          // Liste des clients
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshClients,
              child: clientState.isLoading && filteredClients.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des clients...'),
                      ],
                    ),
                  )
                : clientState.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erreur: ${clientState.error}'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refreshClients,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              clientState.searchQuery.isNotEmpty || _selectedTags.isNotEmpty
                                ? 'Aucun client trouvé'
                                : 'Aucun client enregistré',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              clientState.searchQuery.isNotEmpty || _selectedTags.isNotEmpty
                                ? 'Essayez d\'ajuster vos critères de recherche'
                                : 'Commencez par ajouter votre premier client',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (clientState.searchQuery.isEmpty && _selectedTags.isEmpty) ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ClientFormScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _refreshClients();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter un client'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = filteredClients[index];
                          return ClientCard(
                            client: client,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ClientDetailScreen(clientId: client.id!),
                                ),
                              );
                            },
                            onEdit: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ClientFormScreen(client: client),
                                ),
                              );
                              if (result == true) {
                                _refreshClients();
                              }
                            },
                            onDelete: () => _deleteClient(
                              context,
                              client.id!,
                              client.nomComplet,
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ClientFormScreen(),
            ),
          );
          if (result == true) {
            _refreshClients();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau client'),
      ),
    );
  }
}
