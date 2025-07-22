import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rendez_vous.dart';

import '../../providers/rendez_vous_provider.dart';
import '../../providers/client_provider.dart';

class RdvFilters extends ConsumerStatefulWidget {
  const RdvFilters({super.key});

  @override
  ConsumerState<RdvFilters> createState() => _RdvFiltersState();
}

class _RdvFiltersState extends ConsumerState<RdvFilters> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rdvState = ref.watch(rendezVousProvider);
    final clientState = ref.watch(clientProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtres',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Effacer'),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par statut
          _buildStatutFilter(theme, rdvState),
          
          const SizedBox(height: 20),
          
          // Filtre par client
          _buildClientFilter(theme, rdvState, clientState),
          
          const SizedBox(height: 20),
          
          // Filtre par date
          _buildDateFilter(theme, rdvState),
          
          const SizedBox(height: 24),
          
          // Résumé des filtres actifs
          _buildActiveFilters(theme, rdvState),
        ],
      ),
    );
  }

  Widget _buildStatutFilter(ThemeData theme, RendezVousState rdvState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatutChip(
              theme,
              'Tous',
              null,
              rdvState.statutFiltre == null,
              () => _setStatutFilter(null),
            ),
            ...StatutRendezVous.values.map((statut) {
              return _buildStatutChip(
                theme,
                _getStatutLabel(statut),
                statut,
                rdvState.statutFiltre == statut,
                () => _setStatutFilter(statut),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatutChip(
    ThemeData theme,
    String label,
    StatutRendezVous? statut,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color? backgroundColor;
    Color? textColor;
    IconData? icon;
    
    if (statut != null) {
      switch (statut) {
        case StatutRendezVous.confirme:
          backgroundColor = isSelected ? Colors.green : Colors.green.withOpacity(0.1);
          textColor = isSelected ? Colors.white : Colors.green;
          icon = Icons.check_circle;
          break;
        case StatutRendezVous.enAttente:
          backgroundColor = isSelected ? Colors.orange : Colors.orange.withOpacity(0.1);
          textColor = isSelected ? Colors.white : Colors.orange;
          icon = Icons.schedule;
          break;
        case StatutRendezVous.annule:
          backgroundColor = isSelected ? Colors.red : Colors.red.withOpacity(0.1);
          textColor = isSelected ? Colors.white : Colors.red;
          icon = Icons.cancel;
          break;
        case StatutRendezVous.complete:
          backgroundColor = isSelected ? Colors.blue : Colors.blue.withOpacity(0.1);
          textColor = isSelected ? Colors.white : Colors.blue;
          icon = Icons.done_all;
          break;
      }
    } else {
      backgroundColor = isSelected 
          ? theme.colorScheme.primary 
          : theme.colorScheme.surfaceVariant;
      textColor = isSelected 
          ? theme.colorScheme.onPrimary 
          : theme.colorScheme.onSurfaceVariant;
      icon = Icons.all_inclusive;
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor?.withOpacity(0.3) ?? Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientFilter(
    ThemeData theme,
    RendezVousState rdvState,
    ClientState clientState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        DropdownButtonFormField<int?>(
          value: rdvState.clientFiltre,
          decoration: InputDecoration(
            hintText: 'Tous les clients',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Tous les clients'),
            ),
            ...clientState.clients.map((client) {
              return DropdownMenuItem<int?>(
                value: client.id,
                child: Text(client.nomComplet),
              );
            }).toList(),
          ],
          onChanged: (clientId) => _setClientFilter(clientId),
        ),
      ],
    );
  }

  Widget _buildDateFilter(ThemeData theme, RendezVousState rdvState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        rdvState.dateFiltre != null
                            ? _formatDate(rdvState.dateFiltre!)
                            : 'Toutes les dates',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (rdvState.dateFiltre != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _setDateFilter(null),
                icon: const Icon(Icons.clear),
                tooltip: 'Effacer le filtre de date',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFilters(ThemeData theme, RendezVousState rdvState) {
    final activeFilters = <String>[];
    
    if (rdvState.statutFiltre != null) {
      activeFilters.add('Statut: ${_getStatutLabel(rdvState.statutFiltre!)}');
    }
    
    if (rdvState.clientFiltre != null) {
      final client = ref.read(clientProvider).clients
          .where((c) => c.id == rdvState.clientFiltre)
          .firstOrNull;
      if (client != null) {
        activeFilters.add('Client: ${client.nomComplet}');
      }
    }
    
    if (rdvState.dateFiltre != null) {
      activeFilters.add('Date: ${_formatDate(rdvState.dateFiltre!)}');
    }
    
    if (activeFilters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Aucun filtre actif',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtres actifs:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          ...activeFilters.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                '• $filter',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _setStatutFilter(StatutRendezVous? statut) {
    ref.read(rendezVousProvider.notifier).filtrerParStatut(statut);
  }

  void _setClientFilter(int? clientId) {
    ref.read(rendezVousProvider.notifier).filtrerParClient(clientId);
  }

  void _setDateFilter(DateTime? date) {
    ref.read(rendezVousProvider.notifier).filtrerParDate(date);
  }

  void _clearFilters() {
    ref.read(rendezVousProvider.notifier).effacerFiltres();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: ref.read(rendezVousProvider).dateFiltre ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      _setDateFilter(date);
    }
  }

  String _getStatutLabel(StatutRendezVous statut) {
    switch (statut) {
      case StatutRendezVous.confirme:
        return 'Confirmé';
      case StatutRendezVous.enAttente:
        return 'En attente';
      case StatutRendezVous.annule:
        return 'Annulé';
      case StatutRendezVous.complete:
        return 'Complété';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
