import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../providers/service_provider.dart';
import '../widgets/service_card.dart';
import '../widgets/service_form.dart';
import '../widgets/service_filters.dart';
import '../widgets/service_stats.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showInactive = false;
  RangeValues? _priceRange;
  RangeValues? _durationRange;
  String _sortBy = 'nom';
  bool _showStats = false;

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);
    final serviceNotifier = ref.read(serviceProvider.notifier);
    final stats = ref.watch(serviceStatsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Application des filtres et du tri
    final filteredServices =
        _getFilteredAndSortedServices(serviceState.services);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: _showStats ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
            tooltip: 'Statistiques',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  serviceNotifier.loadServices();
                  break;
                case 'clear_filters':
                  _clearAllFilters();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Actualiser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Effacer les filtres'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await serviceNotifier.loadServices();
        },
        child: Column(
          children: [
            // Statistiques en en-tête (optionnel)
            if (_showStats)
              ServiceStats(
                stats: stats,
                isExpanded: true,
              )
            else
              ServiceStatsHeader(stats: stats),

            // Filtres
            ServiceFilters(
              searchQuery: _searchQuery,
              selectedCategory: _selectedCategory,
              availableCategories: serviceState.categories,
              showInactive: _showInactive,
              priceRange: _priceRange,
              durationRange: _durationRange,
              sortBy: _sortBy,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              onCategoryChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onShowInactiveChanged: (show) {
                setState(() {
                  _showInactive = show;
                });
              },
              onPriceRangeChanged: (range) {
                setState(() {
                  _priceRange = range;
                });
              },
              onDurationRangeChanged: (range) {
                setState(() {
                  _durationRange = range;
                });
              },
              onSortChanged: (sortBy) {
                setState(() {
                  _sortBy = sortBy;
                });
              },
              onClearFilters: _clearAllFilters,
            ),

            // Liste des services
            Expanded(
              child: _buildServicesList(
                filteredServices,
                serviceState,
                serviceNotifier,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(context, null),
        tooltip: 'Ajouter un service',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildServicesList(
    List<Service> services,
    ServiceState serviceState,
    ServiceNotifier serviceNotifier,
  ) {
    if (serviceState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (serviceState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              serviceState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () => serviceNotifier.loadServices(),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          service: service,
          onTap: () => _showServiceDetails(context, service),
          onEdit: () => _showServiceForm(context, service),
          onDelete: () =>
              _showDeleteConfirmation(context, service, serviceNotifier),
          onStatusChanged: (actif) =>
              _toggleServiceStatus(service, actif, serviceNotifier),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _showInactive ||
        _priceRange != null ||
        _durationRange != null ||
        _sortBy != 'nom';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.room_service_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'Aucun service trouvé' : 'Aucun service créé',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Essayez de modifier vos critères de recherche'
                : 'Créez votre premier service pour commencer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (hasFilters)
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
              onPressed: _clearAllFilters,
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Créer un service'),
              onPressed: () => _showServiceForm(context, null),
            ),
        ],
      ),
    );
  }

  List<Service> _getFilteredAndSortedServices(List<Service> services) {
    var filtered = services.where((service) {
      // Filtre par statut actif/inactif
      if (!_showInactive && !service.actif) return false;

      // Filtre par catégorie
      if (_selectedCategory != null &&
          service.categorie?.toLowerCase() !=
              _selectedCategory!.toLowerCase()) {
        return false;
      }

      // Filtre par prix
      if (_priceRange != null &&
          (service.prix < _priceRange!.start ||
              service.prix > _priceRange!.end)) {
        return false;
      }

      // Filtre par durée
      if (_durationRange != null &&
          (service.dureeMinutes < _durationRange!.start ||
              service.dureeMinutes > _durationRange!.end)) {
        return false;
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return service.nom.toLowerCase().contains(query) ||
            service.description?.toLowerCase().contains(query) == true ||
            service.categorie?.toLowerCase().contains(query) == true ||
            service.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      return true;
    }).toList();

    // Application du tri
    switch (_sortBy) {
      case 'prix_asc':
        filtered.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case 'prix_desc':
        filtered.sort((a, b) => b.prix.compareTo(a.prix));
        break;
      case 'duree_asc':
        filtered.sort((a, b) => a.dureeMinutes.compareTo(b.dureeMinutes));
        break;
      case 'duree_desc':
        filtered.sort((a, b) => b.dureeMinutes.compareTo(a.dureeMinutes));
        break;
      case 'recent':
        filtered.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
        break;
      case 'nom':
      default:
        filtered.sort((a, b) => a.nom.compareTo(b.nom));
        break;
    }

    return filtered;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _showInactive = false;
      _priceRange = null;
      _durationRange = null;
      _sortBy = 'nom';
    });
  }

  void _showServiceForm(BuildContext context, Service? service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceForm(
          service: service,
          onSubmit: (newService) async {
            final serviceNotifier = ref.read(serviceProvider.notifier);
            bool success;

            if (service == null) {
              success = await serviceNotifier.ajouterService(newService);
            } else {
              success = await serviceNotifier.modifierService(newService);
            }

            if (mounted) {
              if (success) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(service == null
                        ? 'Service créé avec succès'
                        : 'Service modifié avec succès'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(service == null
                        ? 'Erreur lors de la création du service'
                        : 'Erreur lors de la modification du service'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showServiceDetails(BuildContext context, Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceDetailsSheet(service: service),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Service service,
    ServiceNotifier serviceNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le service "${service.nom}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await serviceNotifier.supprimerService(service.id!);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service supprimé avec succès'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Erreur lors de la suppression'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleServiceStatus(
    Service service,
    bool actif,
    ServiceNotifier serviceNotifier,
  ) async {
    final success =
        await serviceNotifier.changerStatutService(service.id!, actif);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actif
              ? 'Service activé avec succès'
              : 'Service désactivé avec succès'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors du changement de statut'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ServiceDetailsSheet extends StatelessWidget {
  final Service service;

  const _ServiceDetailsSheet({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Poignée de déplacement
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.nom,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Contenu défilable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: ServiceCard(
                    service: service,
                    showActions: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
