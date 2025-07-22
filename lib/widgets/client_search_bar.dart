import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';

class ClientSearchBar extends ConsumerStatefulWidget {
  final Function(List<String>)? onSelectedTagsChanged;
  
  const ClientSearchBar({
    super.key,
    this.onSelectedTagsChanged,
  });

  @override
  ConsumerState<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends ConsumerState<ClientSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(clientProvider.notifier).chercherClients(query);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    widget.onSelectedTagsChanged?.call(_selectedTags);
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _searchController.clear();
    });
    _onSearchChanged('');
    widget.onSelectedTagsChanged?.call(_selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final allTags = ref.read(clientProvider.notifier).obtenirTousLesTags();
    
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un client...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty || _selectedTags.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearFilters,
                              )
                            : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      tooltip: _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
                    ),
                  ],
                ),
                if (_showFilters && allTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Filtrer par tags:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: allTags.map((tag) => FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (_) => _toggleTag(tag),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_selectedTags.isNotEmpty || clientState.searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${clientState.filteredClients.length} client(s) trouvé(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
