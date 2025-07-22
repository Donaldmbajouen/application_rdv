import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/statistics_service.dart';
import '../../providers/statistics_provider.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de période
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: StatsPeriod.values.map((period) {
                  final isSelected = period == selectedPeriod;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedPeriodProvider.notifier).state = period;
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getPeriodLabel(period),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected 
                                ? colorScheme.onPrimary 
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Navigation de date
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final newDate = _getPreviousDate(selectedPeriod, selectedDate);
                    ref.read(selectedDateProvider.notifier).state = newDate;
                  },
                  icon: const Icon(LineIcons.angleLeft),
                ),
                Expanded(
                  child: Text(
                    _getDateLabel(selectedPeriod, selectedDate),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final newDate = _getNextDate(selectedPeriod, selectedDate);
                    final now = DateTime.now();
                    if (_canGoToDate(selectedPeriod, newDate, now)) {
                      ref.read(selectedDateProvider.notifier).state = newDate;
                    }
                  },
                  icon: Icon(
                    LineIcons.angleRight,
                    color: _canGoToNextDate(selectedPeriod, selectedDate) 
                        ? null 
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Bouton aujourd'hui
            if (!_isCurrentPeriod(selectedPeriod, selectedDate))
              TextButton.icon(
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = DateTime.now();
                },
                icon: const Icon(LineIcons.calendar, size: 16),
                label: const Text('Aujourd\'hui'),
              ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.day:
        return 'Jour';
      case StatsPeriod.week:
        return 'Semaine';
      case StatsPeriod.month:
        return 'Mois';
      case StatsPeriod.year:
        return 'Année';
    }
  }

  String _getDateLabel(StatsPeriod period, DateTime date) {
    switch (period) {
      case StatsPeriod.day:
        return _formatDay(date);
      case StatsPeriod.week:
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return '${_formatShortDate(startOfWeek)} - ${_formatShortDate(endOfWeek)}';
      case StatsPeriod.month:
        return _formatMonth(date);
      case StatsPeriod.year:
        return date.year.toString();
    }
  }

  String _formatDay(DateTime date) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day}/${date.month}/${date.year}';
  }

  String _formatMonth(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  DateTime _getPreviousDate(StatsPeriod period, DateTime date) {
    switch (period) {
      case StatsPeriod.day:
        return date.subtract(Duration(days: 1));
      case StatsPeriod.week:
        return date.subtract(Duration(days: 7));
      case StatsPeriod.month:
        return DateTime(date.year, date.month - 1, date.day);
      case StatsPeriod.year:
        return DateTime(date.year - 1, date.month, date.day);
    }
  }

  DateTime _getNextDate(StatsPeriod period, DateTime date) {
    switch (period) {
      case StatsPeriod.day:
        return date.add(Duration(days: 1));
      case StatsPeriod.week:
        return date.add(Duration(days: 7));
      case StatsPeriod.month:
        return DateTime(date.year, date.month + 1, date.day);
      case StatsPeriod.year:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }

  bool _canGoToNextDate(StatsPeriod period, DateTime date) {
    final now = DateTime.now();
    final nextDate = _getNextDate(period, date);
    return _canGoToDate(period, nextDate, now);
  }

  bool _canGoToDate(StatsPeriod period, DateTime date, DateTime now) {
    switch (period) {
      case StatsPeriod.day:
        return date.isBefore(now) || _isSameDay(date, now);
      case StatsPeriod.week:
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        return startOfWeek.isBefore(now) || _isSameWeek(date, now);
      case StatsPeriod.month:
        return date.year < now.year || 
               (date.year == now.year && date.month <= now.month);
      case StatsPeriod.year:
        return date.year <= now.year;
    }
  }

  bool _isCurrentPeriod(StatsPeriod period, DateTime date) {
    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.day:
        return _isSameDay(date, now);
      case StatsPeriod.week:
        return _isSameWeek(date, now);
      case StatsPeriod.month:
        return date.year == now.year && date.month == now.month;
      case StatsPeriod.year:
        return date.year == now.year;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final startOfWeekA = a.subtract(Duration(days: a.weekday - 1));
    final startOfWeekB = b.subtract(Duration(days: b.weekday - 1));
    return _isSameDay(startOfWeekA, startOfWeekB);
  }
}
