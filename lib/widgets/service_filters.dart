import 'package:flutter/material.dart';

class ServiceFilters extends StatefulWidget {
  final String searchQuery;
  final String? selectedCategory;
  final List<String> availableCategories;
  final bool showInactive;
  final RangeValues? priceRange;
  final RangeValues? durationRange;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String?) onCategoryChanged;
  final Function(bool) onShowInactiveChanged;
  final Function(RangeValues?) onPriceRangeChanged;
  final Function(RangeValues?) onDurationRangeChanged;
  final Function(String) onSortChanged;
  final VoidCallback onClearFilters;

  const ServiceFilters({
    super.key,
    required this.searchQuery,
    this.selectedCategory,
    required this.availableCategories,
    required this.showInactive,
    this.priceRange,
    this.durationRange,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onShowInactiveChanged,
    required this.onPriceRangeChanged,
    required this.onDurationRangeChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  @override
  State<ServiceFilters> createState() => _ServiceFiltersState();
}

class _ServiceFiltersState extends State<ServiceFilters> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return widget.selectedCategory != null ||
           widget.showInactive ||
           widget.priceRange != null ||
           widget.durationRange != null ||
           widget.sortBy != 'nom';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un service...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _filtersExpanded ? Icons.expand_less : Icons.tune,
                        color: _hasActiveFilters ? colorScheme.primary : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _filtersExpanded = !_filtersExpanded;
                        });
                      },
                    ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.onSearchChanged,
            ),
            
            // Filtres avancés
            if (_filtersExpanded) ...[
              const SizedBox(height: 16),
              _buildAdvancedFilters(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tri et options d'affichage
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: widget.sortBy,
                decoration: const InputDecoration(
                  labelText: 'Trier par',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                ),
                items: const [
                  DropdownMenuItem(value: 'nom', child: Text('Nom (A-Z)')),
                  DropdownMenuItem(value: 'prix_asc', child: Text('Prix croissant')),
                  DropdownMenuItem(value: 'prix_desc', child: Text('Prix décroissant')),
                  DropdownMenuItem(value: 'duree_asc', child: Text('Durée croissante')),
                  DropdownMenuItem(value: 'duree_desc', child: Text('Durée décroissante')),
                  DropdownMenuItem(value: 'recent', child: Text('Plus récents')),
                ],
                onChanged: (value) => widget.onSortChanged(value ?? 'nom'),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: SwitchListTile(
                title: const Text(
                  'Inactifs',
                  style: TextStyle(fontSize: 12),
                ),
                value: widget.showInactive,
                onChanged: widget.onShowInactiveChanged,
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filtres par catégorie
        if (widget.availableCategories.isNotEmpty) ...[
          Text(
            'Catégories',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Toutes'),
                selected: widget.selectedCategory == null,
                onSelected: (_) => widget.onCategoryChanged(null),
              ),
              ...widget.availableCategories.map((category) {
                return FilterChip(
                  label: Text(category),
                  selected: widget.selectedCategory == category,
                  onSelected: (_) => widget.onCategoryChanged(
                    widget.selectedCategory == category ? null : category,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Filtre de prix
        PriceRangeFilter(
          currentRange: widget.priceRange,
          onRangeChanged: widget.onPriceRangeChanged,
        ),
        const SizedBox(height: 16),

        // Filtre de durée
        DurationRangeFilter(
          currentRange: widget.durationRange,
          onRangeChanged: widget.onDurationRangeChanged,
        ),
        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            if (_hasActiveFilters)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Effacer les filtres'),
                onPressed: widget.onClearFilters,
              ),
            const Spacer(),
            Chip(
              label: Text(
                '${_getActiveFiltersCount()} filtre${_getActiveFiltersCount() > 1 ? 's' : ''} actif${_getActiveFiltersCount() > 1 ? 's' : ''}',
              ),
              backgroundColor: _hasActiveFilters 
                ? colorScheme.primaryContainer 
                : colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ],
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (widget.selectedCategory != null) count++;
    if (widget.showInactive) count++;
    if (widget.priceRange != null) count++;
    if (widget.durationRange != null) count++;
    if (widget.sortBy != 'nom') count++;
    return count;
  }
}

class PriceRangeFilter extends StatefulWidget {
  final RangeValues? currentRange;
  final Function(RangeValues?) onRangeChanged;

  const PriceRangeFilter({
    super.key,
    this.currentRange,
    required this.onRangeChanged,
  });

  @override
  State<PriceRangeFilter> createState() => _PriceRangeFilterState();
}

class _PriceRangeFilterState extends State<PriceRangeFilter> {
  RangeValues _range = const RangeValues(0, 200);
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentRange != null) {
      _range = widget.currentRange!;
      _isEnabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value ?? false;
                });
                widget.onRangeChanged(_isEnabled ? _range : null);
              },
            ),
            Text(
              'Filtrer par prix',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        if (_isEnabled) ...[
          const SizedBox(height: 8),
          RangeSlider(
            values: _range,
            min: 0,
            max: 500,
            divisions: 50,
            labels: RangeLabels(
              '${_range.start.round()}€',
              '${_range.end.round()}€',
            ),
            onChanged: (values) {
              setState(() {
                _range = values;
              });
              widget.onRangeChanged(values);
            },
          ),
          Text(
            'Entre ${_range.start.round()}€ et ${_range.end.round()}€',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class DurationRangeFilter extends StatefulWidget {
  final RangeValues? currentRange;
  final Function(RangeValues?) onRangeChanged;

  const DurationRangeFilter({
    super.key,
    this.currentRange,
    required this.onRangeChanged,
  });

  @override
  State<DurationRangeFilter> createState() => _DurationRangeFilterState();
}

class _DurationRangeFilterState extends State<DurationRangeFilter> {
  RangeValues _range = const RangeValues(15, 180);
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentRange != null) {
      _range = widget.currentRange!;
      _isEnabled = true;
    }
  }

  String _formatDuration(double minutes) {
    final h = minutes.toInt() ~/ 60;
    final m = minutes.toInt() % 60;
    if (h > 0) {
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value ?? false;
                });
                widget.onRangeChanged(_isEnabled ? _range : null);
              },
            ),
            Text(
              'Filtrer par durée',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        if (_isEnabled) ...[
          const SizedBox(height: 8),
          RangeSlider(
            values: _range,
            min: 15,
            max: 300,
            divisions: 19,
            labels: RangeLabels(
              _formatDuration(_range.start),
              _formatDuration(_range.end),
            ),
            onChanged: (values) {
              setState(() {
                _range = values;
              });
              widget.onRangeChanged(values);
            },
          ),
          Text(
            'Entre ${_formatDuration(_range.start)} et ${_formatDuration(_range.end)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
