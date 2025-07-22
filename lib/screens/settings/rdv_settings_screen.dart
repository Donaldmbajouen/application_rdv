import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../widgets/settings/time_range_picker.dart';

class RdvSettingsScreen extends ConsumerWidget {
  const RdvSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;

    if (settingsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (settingsState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres RDV'),
          actions: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () => _resetToDefaults(context, ref),
              tooltip: 'Remettre par défaut',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Erreur: ${settingsState.error}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(settingsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    return _buildContent(context, ref, settingsState.settings);
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Paramètres de durée
        SettingsSection(
          title: 'Durées par défaut',
          children: [
            SettingsSlider(
              icon: Icons.schedule,
              title: 'Durée des RDV',
              subtitle: 'Durée par défaut des nouveaux rendez-vous',
              value: settings.dureeDefautMinutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 11,
              labelFormatter: (value) => '${value.round()} min',
              onChanged: (value) => ref.read(settingsProvider.notifier)
                  .changerDureeDefaut(value.round()),
            ),
            SettingsSlider(
              icon: Icons.pause,
              title: 'Pause entre RDV',
              subtitle: 'Temps de pause automatique entre les rendez-vous',
              value: settings.pauseEntreRdvMinutes.toDouble(),
              min: 0,
              max: 30,
              divisions: 6,
              labelFormatter: (value) => value == 0 ? 'Aucune' : '${value.round()} min',
              onChanged: (value) => ref.read(settingsProvider.notifier)
                  .changerPauseEntreRdv(value.round()),
            ),
            SettingsSlider(
              icon: Icons.notification_important,
              title: 'Délai de rappel',
              subtitle: 'Temps avant le RDV pour envoyer un rappel',
              value: settings.delaiRappelMinutes.toDouble(),
              min: 5,
              max: 1440,
              divisions: 20,
              labelFormatter: (value) => _formatReminderDelay(value.round()),
              onChanged: (value) => ref.read(settingsProvider.notifier)
                  .changerDelaiRappel(value.round()),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Horaires d'ouverture
        SettingsSection(
          title: 'Horaires d\'ouverture',
          children: [
            SettingsNavTile(
              icon: Icons.access_time,
              title: 'Configurer les horaires',
              subtitle: 'Définir les heures d\'ouverture par jour',
              onTap: () => _showScheduleSettings(context, ref, settings),
              badge: _buildScheduleBadge(context, settings),
            ),
            SettingsNavTile(
              icon: Icons.calendar_view_week,
              title: 'Aperçu des horaires',
              subtitle: 'Voir un résumé des horaires de la semaine',
              onTap: () => _showSchedulePreview(context, settings),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Validation et conflits
        SettingsSection(
          title: 'Validation',
          children: [
            SettingsToggle(
              icon: Icons.warning,
              title: 'Détecter les conflits',
              subtitle: 'Alerter en cas de chevauchement de RDV',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.block,
              title: 'Empêcher les conflits',
              subtitle: 'Interdire la création de RDV en conflit',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.schedule_send,
              title: 'RDV hors horaires',
              subtitle: 'Autoriser les RDV en dehors des heures d\'ouverture',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Automatisation
        SettingsSection(
          title: 'Automatisation',
          children: [
            SettingsToggle(
              icon: Icons.auto_awesome,
              title: 'Suggestions intelligentes',
              subtitle: 'Proposer automatiquement des créneaux optimaux',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.event_repeat,
              title: 'RDV récurrents',
              subtitle: 'Permettre la création de rendez-vous récurrents',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.auto_fix_high,
              title: 'Optimisation automatique',
              subtitle: 'Réorganiser automatiquement pour optimiser le planning',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Actions
        SettingsSection(
          title: 'Actions',
          children: [
            SettingsAction(
              icon: Icons.refresh,
              title: 'Réinitialiser les paramètres',
              subtitle: 'Remettre tous les paramètres RDV par défaut',
              onTap: () => _resetToDefaults(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleBadge(BuildContext context, AppSettings settings) {
    final openDays = settings.horaires.values.where((h) => h.ouvert).length;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$openDays/7',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatReminderDelay(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes == 60) {
      return '1 heure';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''}';
      } else {
        return '${hours}h${remainingMinutes}min';
      }
    } else {
      final days = minutes ~/ 1440;
      return '$days jour${days > 1 ? 's' : ''}';
    }
  }

  void _showScheduleSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ScheduleSettingsScreen(settings: settings),
      ),
    );
  }

  void _showSchedulePreview(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _SchedulePreviewDialog(settings: settings),
    );
  }

  void _resetToDefaults(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Êtes-vous sûr de vouloir remettre tous les paramètres '
          'de rendez-vous par défaut ? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Remettre les valeurs par défaut
              final defaultSettings = AppSettings.defaut();
              ref.read(settingsProvider.notifier).changerDureeDefaut(defaultSettings.dureeDefautMinutes);
              ref.read(settingsProvider.notifier).changerPauseEntreRdv(defaultSettings.pauseEntreRdvMinutes);
              ref.read(settingsProvider.notifier).changerDelaiRappel(defaultSettings.delaiRappelMinutes);
              ref.read(settingsProvider.notifier).changerHoraires(defaultSettings.horaires);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres réinitialisés')),
              );
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSettingsScreen extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _ScheduleSettingsScreen({required this.settings});

  @override
  ConsumerState<_ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends ConsumerState<_ScheduleSettingsScreen> {
  late Map<int, bool> _openDays;
  late Map<int, TimeOfDay> _openTimes;
  late Map<int, TimeOfDay> _closeTimes;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }

  void _initializeSchedule() {
    _openDays = {};
    _openTimes = {};
    _closeTimes = {};

    for (int day = 1; day <= 7; day++) {
      final horaire = widget.settings.horaires[day];
      _openDays[day] = horaire?.ouvert ?? false;
      
      final openTime = TimeUtils.stringToTime(horaire?.heureOuverture ?? '09:00');
      final closeTime = TimeUtils.stringToTime(horaire?.heureFermeture ?? '18:00');
      
      _openTimes[day] = openTime ?? const TimeOfDay(hour: 9, minute: 0);
      _closeTimes[day] = closeTime ?? const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horaires d\'ouverture'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: Column(
        children: [
          // Actions rapides
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.business),
                    label: const Text('Lun-Ven'),
                    onPressed: _setWeekdays,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.weekend),
                    label: const Text('Weekend'),
                    onPressed: _setWeekend,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.select_all),
                    label: const Text('Tous'),
                    onPressed: _setAllDays,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des jours
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                WeeklySchedulePicker(
                  openDays: _openDays,
                  openTimes: _openTimes,
                  closeTimes: _closeTimes,
                  onDayToggled: _toggleDay,
                  onOpenTimeChanged: _changeOpenTime,
                  onCloseTimeChanged: _changeCloseTime,
                ),
              ],
            ),
          ),
          
          // Bouton de sauvegarde
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder les modifications'),
                onPressed: _saveChanges,
              ),
            ),
        ],
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      _openDays[day] = !(_openDays[day] ?? false);
      _hasChanges = true;
    });
  }

  void _changeOpenTime(MapEntry<int, TimeOfDay> entry) {
    setState(() {
      _openTimes[entry.key] = entry.value;
      _hasChanges = true;
    });
  }

  void _changeCloseTime(MapEntry<int, TimeOfDay> entry) {
    setState(() {
      _closeTimes[entry.key] = entry.value;
      _hasChanges = true;
    });
  }

  void _setWeekdays() {
    setState(() {
      for (int day = 1; day <= 5; day++) {
        _openDays[day] = true;
        _openTimes[day] = const TimeOfDay(hour: 9, minute: 0);
        _closeTimes[day] = const TimeOfDay(hour: 18, minute: 0);
      }
      _openDays[6] = false;
      _openDays[7] = false;
      _hasChanges = true;
    });
  }

  void _setWeekend() {
    setState(() {
      _openDays[6] = true;
      _openDays[7] = true;
      _openTimes[6] = const TimeOfDay(hour: 10, minute: 0);
      _openTimes[7] = const TimeOfDay(hour: 10, minute: 0);
      _closeTimes[6] = const TimeOfDay(hour: 16, minute: 0);
      _closeTimes[7] = const TimeOfDay(hour: 16, minute: 0);
      _hasChanges = true;
    });
  }

  void _setAllDays() {
    setState(() {
      for (int day = 1; day <= 7; day++) {
        _openDays[day] = true;
        _openTimes[day] = const TimeOfDay(hour: 9, minute: 0);
        _closeTimes[day] = const TimeOfDay(hour: 18, minute: 0);
      }
      _hasChanges = true;
    });
  }

  void _saveChanges() async {
    final horaires = <int, HorairesOuverture>{};
    
    for (int day = 1; day <= 7; day++) {
      horaires[day] = HorairesOuverture(
        ouvert: _openDays[day] ?? false,
        heureOuverture: TimeUtils.timeToString(_openTimes[day]!),
        heureFermeture: TimeUtils.timeToString(_closeTimes[day]!),
      );
    }

    final success = await ref.read(settingsProvider.notifier).changerHoraires(horaires);
    
    if (success && mounted) {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horaires sauvegardés')),
      );
    }
  }
}

class _SchedulePreviewDialog extends StatelessWidget {
  final AppSettings settings;

  const _SchedulePreviewDialog({required this.settings});

  static const List<String> dayNames = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: const Text('Aperçu des horaires'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final day = index + 1;
            final horaire = settings.horaires[day];
            final isOpen = horaire?.ouvert ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      dayNames[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: isOpen
                        ? Text(
                            '${horaire!.heureOuverture} - ${horaire.heureFermeture}',
                            style: theme.textTheme.bodyMedium,
                          )
                        : Text(
                            'Fermé',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                  Icon(
                    isOpen ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isOpen ? Colors.green : colors.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
