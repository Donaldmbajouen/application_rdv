import 'package:flutter/material.dart';

/// Widget pour sélectionner une plage horaire
class TimeRangePicker extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isEnabled;
  final ValueChanged<TimeOfDay>? onStartTimeChanged;
  final ValueChanged<TimeOfDay>? onEndTimeChanged;
  final String? label;

  const TimeRangePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    this.isEnabled = true,
    this.onStartTimeChanged,
    this.onEndTimeChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: _TimeButton(
                time: startTime,
                label: 'Ouverture',
                enabled: isEnabled,
                onChanged: onStartTimeChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.arrow_forward,
                color: colors.onSurface.withOpacity(0.5),
              ),
            ),
            Expanded(
              child: _TimeButton(
                time: endTime,
                label: 'Fermeture',
                enabled: isEnabled,
                onChanged: onEndTimeChanged,
              ),
            ),
          ],
        ),
        if (isEnabled) ...[
          const SizedBox(height: 8),
          Text(
            _formatDuration(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration() {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    final durationMinutes = end > start ? end - start : (24 * 60) - start + end;
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (minutes == 0) {
      return '$hours heure${hours > 1 ? 's' : ''}';
    } else if (hours == 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay time;
  final String label;
  final bool enabled;
  final ValueChanged<TimeOfDay>? onChanged;

  const _TimeButton({
    required this.time,
    required this.label,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: enabled 
                ? colors.onSurface.withOpacity(0.7)
                : colors.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: enabled 
              ? colors.surfaceVariant.withOpacity(0.5)
              : colors.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled && onChanged != null ? () => _selectTime(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: enabled 
                        ? colors.onSurface
                        : colors.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time.format(context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled 
                          ? colors.onSurface
                          : colors.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      onChanged?.call(selectedTime);
    }
  }
}

/// Widget pour configurer les horaires de la semaine
class WeeklySchedulePicker extends StatelessWidget {
  final Map<int, bool> openDays;
  final Map<int, TimeOfDay> openTimes;
  final Map<int, TimeOfDay> closeTimes;
  final ValueChanged<int>? onDayToggled;
  final ValueChanged<MapEntry<int, TimeOfDay>>? onOpenTimeChanged;
  final ValueChanged<MapEntry<int, TimeOfDay>>? onCloseTimeChanged;

  const WeeklySchedulePicker({
    super.key,
    required this.openDays,
    required this.openTimes,
    required this.closeTimes,
    this.onDayToggled,
    this.onOpenTimeChanged,
    this.onCloseTimeChanged,
  });

  static const List<String> dayNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(7, (index) {
        final dayIndex = index + 1; // 1-7 pour lundi-dimanche
        final isOpen = openDays[dayIndex] ?? false;
        final openTime = openTimes[dayIndex] ?? const TimeOfDay(hour: 9, minute: 0);
        final closeTime = closeTimes[dayIndex] ?? const TimeOfDay(hour: 18, minute: 0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DayScheduleRow(
            dayName: dayNames[index],
            isOpen: isOpen,
            openTime: openTime,
            closeTime: closeTime,
            onToggled: () => onDayToggled?.call(dayIndex),
            onOpenTimeChanged: (time) => onOpenTimeChanged?.call(MapEntry(dayIndex, time)),
            onCloseTimeChanged: (time) => onCloseTimeChanged?.call(MapEntry(dayIndex, time)),
          ),
        );
      }),
    );
  }
}

class _DayScheduleRow extends StatelessWidget {
  final String dayName;
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final VoidCallback? onToggled;
  final ValueChanged<TimeOfDay>? onOpenTimeChanged;
  final ValueChanged<TimeOfDay>? onCloseTimeChanged;

  const _DayScheduleRow({
    required this.dayName,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.onToggled,
    this.onOpenTimeChanged,
    this.onCloseTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: onToggled != null ? (_) => onToggled!() : null,
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 16),
              TimeRangePicker(
                startTime: openTime,
                endTime: closeTime,
                isEnabled: true,
                onStartTimeChanged: onOpenTimeChanged,
                onEndTimeChanged: onCloseTimeChanged,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Fermé',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Utilitaires pour les horaires
class TimeUtils {
  /// Convertit TimeOfDay en String (HH:mm)
  static String timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Convertit String (HH:mm) en TimeOfDay
  static TimeOfDay? stringToTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Vérifie si time1 est avant time2
  static bool isBefore(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 < minutes2;
  }

  /// Calcule la durée entre deux heures en minutes
  static int durationInMinutes(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (endMinutes >= startMinutes) {
      return endMinutes - startMinutes;
    } else {
      // Le lendemain
      return (24 * 60) - startMinutes + endMinutes;
    }
  }

  /// Formate une durée en minutes en string lisible
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours == 0) {
      return '${mins}min';
    } else if (mins == 0) {
      return '${hours}h';
    } else {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
  }
}
