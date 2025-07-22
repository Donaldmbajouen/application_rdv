import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/rendez_vous_provider.dart';

class TimeSlotPicker extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final int dureeMinutes;
  final Function(DateTime) onTimeSelected;
  final String heureDebut;
  final String heureFin;
  final int pauseMinutes;

  const TimeSlotPicker({
    super.key,
    required this.selectedDate,
    required this.dureeMinutes,
    required this.onTimeSelected,
    this.heureDebut = '09:00',
    this.heureFin = '18:00',
    this.pauseMinutes = 15,
  });

  @override
  ConsumerState<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends ConsumerState<TimeSlotPicker> {
  DateTime? _selectedSlot;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creneauxLibres = ref.watch(creneauxLibresProvider({
      'date': widget.selectedDate,
      'duree': widget.dureeMinutes,
      'heureDebut': widget.heureDebut,
      'heureFin': widget.heureFin,
      'pauseMinutes': widget.pauseMinutes,
    }));

    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choisir un créneau',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Durée: ${_formatDuration(widget.dureeMinutes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des créneaux
            Flexible(
              child: creneauxLibres.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildTimeSlotsList(theme, creneauxLibres),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedSlot != null
                        ? () {
                            widget.onTimeSelected(_selectedSlot!);
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text('Confirmer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun créneau disponible',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les créneaux sont occupés pour cette journée. Essayez une autre date ou réduisez la durée du service.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList(ThemeData theme, List<DateTime> creneaux) {
    // Grouper les créneaux par période de la journée
    final matin = creneaux.where((c) => c.hour < 12).toList();
    final apresMidi = creneaux.where((c) => c.hour >= 12 && c.hour < 18).toList();
    final soir = creneaux.where((c) => c.hour >= 18).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (matin.isNotEmpty) ...[
            _buildPeriodHeader(theme, 'Matin', Icons.wb_sunny),
            const SizedBox(height: 8),
            _buildTimeSlotGrid(theme, matin),
            const SizedBox(height: 16),
          ],
          
          if (apresMidi.isNotEmpty) ...[
            _buildPeriodHeader(theme, 'Après-midi', Icons.wb_sunny_outlined),
            const SizedBox(height: 8),
            _buildTimeSlotGrid(theme, apresMidi),
            const SizedBox(height: 16),
          ],
          
          if (soir.isNotEmpty) ...[
            _buildPeriodHeader(theme, 'Soir', Icons.nights_stay),
            const SizedBox(height: 8),
            _buildTimeSlotGrid(theme, soir),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotGrid(ThemeData theme, List<DateTime> creneaux) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: creneaux.map((creneau) {
        final isSelected = _selectedSlot == creneau;
        final startTime = _formatTime(creneau);
        final endTime = _formatTime(creneau.add(Duration(minutes: widget.dureeMinutes)));
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedSlot = creneau;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  startTime,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '- $endTime',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }
}
