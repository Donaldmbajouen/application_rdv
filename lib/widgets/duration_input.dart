import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationInput extends StatefulWidget {
  final int initialMinutes;
  final ValueChanged<int> onChanged;
  final String? label;
  final bool showPresets;

  const DurationInput({
    super.key,
    required this.initialMinutes,
    required this.onChanged,
    this.label,
    this.showPresets = true,
  });

  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late final TextEditingController _heuresController;
  late final TextEditingController _minutesController;
  
  int _heures = 0;
  int _minutes = 0;

  final List<int> _presetsMinutes = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _initializeFromMinutes(widget.initialMinutes);
    _heuresController = TextEditingController(text: _heures.toString());
    _minutesController = TextEditingController(text: _minutes.toString());
  }

  void _initializeFromMinutes(int totalMinutes) {
    _heures = totalMinutes ~/ 60;
    _minutes = totalMinutes % 60;
  }

  @override
  void dispose() {
    _heuresController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    final totalMinutes = (_heures * 60) + _minutes;
    widget.onChanged(totalMinutes);
  }

  void _setPreset(int minutes) {
    setState(() {
      _initializeFromMinutes(minutes);
      _heuresController.text = _heures.toString();
      _minutesController.text = _minutes.toString();
    });
    _updateDuration();
  }

  void _onHeuresChanged(String value) {
    final heures = int.tryParse(value) ?? 0;
    setState(() {
      _heures = heures.clamp(0, 23);
    });
    _updateDuration();
  }

  void _onMinutesChanged(String value) {
    final minutes = int.tryParse(value) ?? 0;
    setState(() {
      _minutes = minutes.clamp(0, 59);
    });
    _updateDuration();
  }

  String _formatDuration(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) {
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label ?? 'Durée',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        
        // Saisie manuelle
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heuresController,
                decoration: const InputDecoration(
                  labelText: 'Heures',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'h',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: _onHeuresChanged,
                validator: (value) {
                  final heures = int.tryParse(value ?? '0') ?? 0;
                  if (heures < 0 || heures > 23) {
                    return 'Entre 0 et 23h';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: _onMinutesChanged,
                validator: (value) {
                  final minutes = int.tryParse(value ?? '0') ?? 0;
                  if (minutes < 0 || minutes > 59) {
                    return 'Entre 0 et 59min';
                  }
                  final totalMinutes = (_heures * 60) + minutes;
                  if (totalMinutes <= 0) {
                    return 'Durée > 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        // Affichage du total
        if ((_heures > 0 || _minutes > 0)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Durée totale: ${_formatDuration((_heures * 60) + _minutes)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Presets rapides
        if (widget.showPresets) ...[
          const SizedBox(height: 16),
          Text(
            'Durées fréquentes',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetsMinutes.map((minutes) {
              final isSelected = ((_heures * 60) + _minutes) == minutes;
              return FilterChip(
                label: Text(_formatDuration(minutes)),
                selected: isSelected,
                onSelected: (_) => _setPreset(minutes),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Widget simplifié pour afficher juste la durée formatée avec possibilité de modification
class DurationDisplay extends StatelessWidget {
  final int minutes;
  final VoidCallback? onTap;
  final bool showEdit;

  const DurationDisplay({
    super.key,
    required this.minutes,
    this.onTap,
    this.showEdit = false,
  });

  String _formatDuration(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) {
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(minutes),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showEdit) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 14,
                color: colorScheme.onSecondaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
