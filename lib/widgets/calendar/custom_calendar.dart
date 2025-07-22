import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/rendez_vous.dart';
import '../../providers/rendez_vous_provider.dart';

class CustomCalendar extends ConsumerStatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final CalendarFormat calendarFormat;
  final Function(CalendarFormat) onFormatChanged;

  const CustomCalendar({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  @override
  ConsumerState<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends ConsumerState<CustomCalendar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rdvState = ref.watch(rendezVousProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(8),
      child: TableCalendar<RendezVous>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: widget.focusedDay,
        selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
        calendarFormat: widget.calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        // Style du calendrier
        calendarStyle: CalendarStyle(
          // Jours normaux
          defaultTextStyle: theme.textTheme.bodyMedium!,
          defaultDecoration: const BoxDecoration(),
          
          // Jour sélectionné
          selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          
          // Jour d'aujourd'hui
          todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          
          // Weekend
          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.error,
          ),
          
          // Jours hors mois
          outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          
          // Indicateurs d'événements
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          markersAnchor: 1.2,
          markersOffset: const PositionedOffset(bottom: 2),
          
          // Espacement
          cellMargin: const EdgeInsets.all(4),
          rowDecoration: const BoxDecoration(),
        ),
        
        // Style de l'en-tête
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          formatButtonTextStyle: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface,
          ),
          titleTextStyle: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        
        // Style des jours de la semaine
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.error.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Événements personnalisés
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, rdvState.rendezVous, false, false);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, rdvState.rendezVous, true, false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, rdvState.rendezVous, false, true);
          },
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox();
            
            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((rdv) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rdv.statut),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        
        onDaySelected: widget.onDaySelected,
        onPageChanged: widget.onPageChanged,
        onFormatChanged: widget.onFormatChanged,
      ),
    );
  }

  List<RendezVous> _getEventsForDay(DateTime day) {
    final rdvState = ref.read(rendezVousProvider);
    return rdvState.rendezVous.where((rdv) {
      return isSameDay(rdv.dateHeure, day);
    }).toList();
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<RendezVous> allRdvs,
    bool isSelected,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final rdvsForDay = allRdvs.where((rdv) => isSameDay(rdv.dateHeure, day)).toList();
    
    // Compter les RDV par statut
    final confirmes = rdvsForDay.where((rdv) => rdv.statut == StatutRendezVous.confirme).length;
    final enAttente = rdvsForDay.where((rdv) => rdv.statut == StatutRendezVous.enAttente).length;
    final completes = rdvsForDay.where((rdv) => rdv.statut == StatutRendezVous.complete).length;
    
    Color? backgroundColor;
    Color? textColor;
    
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: rdvsForDay.isNotEmpty && !isSelected && !isToday
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor ?? (rdvsForDay.isNotEmpty
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant),
                fontWeight: rdvsForDay.isNotEmpty || isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          
          // Indicateur de charge de travail
          if (rdvsForDay.isNotEmpty && !isSelected && !isToday)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getWorkloadColor(rdvsForDay.length),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          
          // Mini indicateurs de statut
          if (rdvsForDay.isNotEmpty && (confirmes > 0 || enAttente > 0 || completes > 0))
            Positioned(
              bottom: 2,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (confirmes > 0)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (enAttente > 0)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (completes > 0)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatutRendezVous statut) {
    switch (statut) {
      case StatutRendezVous.confirme:
        return Colors.green;
      case StatutRendezVous.enAttente:
        return Colors.orange;
      case StatutRendezVous.annule:
        return Colors.red;
      case StatutRendezVous.complete:
        return Colors.blue;
    }
  }

  Color _getWorkloadColor(int count) {
    if (count >= 6) return Colors.red.shade400;
    if (count >= 4) return Colors.orange.shade400;
    if (count >= 2) return Colors.blue.shade400;
    return Colors.green.shade400;
  }
}
