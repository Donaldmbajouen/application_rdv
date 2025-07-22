import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final notificationsState = ref.watch(notificationProvider);

    if (settingsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (settingsState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(notificationProvider.notifier).resetState(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: ${settingsState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(settingsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    return _buildContent(context, ref, settingsState.settings, notificationsState);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    AsyncValue<void> notificationsState,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // État du service de notifications
        if (notificationsState.hasError)
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Erreur de notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(notificationsState.error.toString()),
                ],
              ),
            ),
          ),

        // Paramètres généraux
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paramètres généraux', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('Notifications activées'),
                  subtitle: const Text('Active ou désactive toutes les notifications'),
                  value: settings.notificationsActives,
                  onChanged: (value) => _updateGeneralSettings(ref, settings, notificationsActives: value),
                ),
                
                SwitchListTile(
                  title: const Text('Notifications groupées'),
                  subtitle: const Text('Groupe les notifications du même jour'),
                  value: settings.notificationsGroupees,
                  onChanged: settings.notificationsActives 
                      ? (value) => _updateGeneralSettings(ref, settings, notificationsGroupees: value)
                      : null,
                ),
                
                SwitchListTile(
                  title: const Text('Actions dans les notifications'),
                  subtitle: const Text('Ajoute des boutons d\'action (Confirmer, Reporter...)'),
                  value: settings.actionsNotifications,
                  onChanged: settings.notificationsActives 
                      ? (value) => _updateGeneralSettings(ref, settings, actionsNotifications: value)
                      : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Paramètres par type de notification
        if (settings.notificationsActives)
          ...TypeNotification.values.map((type) => _buildNotificationTypeCard(context, ref, settings, type)),

        const SizedBox(height: 16),

        // Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Notifications programmées'),
                  subtitle: const Text('Voir toutes les notifications en attente'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showScheduledNotifications(context, ref),
                ),
                
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Annuler toutes les notifications'),
                  subtitle: const Text('Supprime toutes les notifications programmées'),
                  trailing: const Icon(Icons.warning, color: Colors.orange),
                  onTap: () => _confirmClearAllNotifications(context, ref),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypeCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    TypeNotification type,
  ) {
    final parametres = settings.parametresNotification(type);
    final title = _getTypeTitle(type);
    final description = _getTypeDescription(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(type)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Switch(
                  value: parametres.active,
                  onChanged: (value) => _updateNotificationSettings(ref, settings, type, parametres.copyWith(active: value)),
                ),
              ],
            ),
            
            if (parametres.active) ...[
              const SizedBox(height: 16),
              
              // Délai pour les rappels
              if (type == TypeNotification.rappelRdv || type == TypeNotification.relance) ...[
                Row(
                  children: [
                    const Text('Délai: '),
                    Expanded(
                      child: Slider(
                        value: parametres.delaiMinutes.toDouble(),
                        min: type == TypeNotification.relance ? 60 : 5, // 1h min pour relance, 5min pour rappel
                        max: type == TypeNotification.relance ? 10080 : 1440, // 7j max pour relance, 24h pour rappel
                        divisions: type == TypeNotification.relance ? 20 : 30,
                        label: _formatDelai(parametres.delaiMinutes, type),
                        onChanged: (value) => _updateNotificationSettings(
                          ref,
                          settings,
                          type,
                          parametres.copyWith(delaiMinutes: value.round()),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDelai(parametres.delaiMinutes, type),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
              ],
              
              // Paramètres son et vibration
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Son'),
                      value: parametres.son,
                      onChanged: (value) => _updateNotificationSettings(
                        ref,
                        settings,
                        type,
                        parametres.copyWith(son: value ?? false),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Vibration'),
                      value: parametres.vibration,
                      onChanged: (value) => _updateNotificationSettings(
                        ref,
                        settings,
                        type,
                        parametres.copyWith(vibration: value ?? false),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeTitle(TypeNotification type) {
    switch (type) {
      case TypeNotification.rappelRdv:
        return 'Rappels de RDV';
      case TypeNotification.conflit:
        return 'Conflits de RDV';
      case TypeNotification.anniversaire:
        return 'Anniversaires clients';
      case TypeNotification.relance:
        return 'Relances clients';
      case TypeNotification.statut:
        return 'Changements de statut';
    }
  }

  String _getTypeDescription(TypeNotification type) {
    switch (type) {
      case TypeNotification.rappelRdv:
        return 'Notifications avant les rendez-vous';
      case TypeNotification.conflit:
        return 'Alertes de créneaux qui se chevauchent';
      case TypeNotification.anniversaire:
        return 'Rappels des anniversaires clients';
      case TypeNotification.relance:
        return 'Rappels pour les clients inactifs';
      case TypeNotification.statut:
        return 'Notifications de changement d\'état';
    }
  }

  IconData _getTypeIcon(TypeNotification type) {
    switch (type) {
      case TypeNotification.rappelRdv:
        return Icons.schedule;
      case TypeNotification.conflit:
        return Icons.warning;
      case TypeNotification.anniversaire:
        return Icons.cake;
      case TypeNotification.relance:
        return Icons.phone;
      case TypeNotification.statut:
        return Icons.info;
    }
  }

  String _formatDelai(int minutes, TypeNotification type) {
    if (type == TypeNotification.relance) {
      final days = minutes ~/ 1440;
      if (days >= 1) {
        return '$days jour${days > 1 ? 's' : ''}';
      } else {
        final hours = minutes ~/ 60;
        return '$hours heure${hours > 1 ? 's' : ''}';
      }
    } else {
      if (minutes >= 1440) {
        final days = minutes ~/ 1440;
        return '$days jour${days > 1 ? 's' : ''} avant';
      } else if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        if (remainingMinutes == 0) {
          return '$hours heure${hours > 1 ? 's' : ''} avant';
        } else {
          return '${hours}h${remainingMinutes}min avant';
        }
      } else {
        return '$minutes minute${minutes > 1 ? 's' : ''} avant';
      }
    }
  }

  void _updateGeneralSettings(
    WidgetRef ref,
    AppSettings settings, {
    bool? notificationsActives,
    bool? notificationsGroupees,
    bool? actionsNotifications,
  }) {
    final newSettings = settings.copyWith(
      notificationsActives: notificationsActives,
      notificationsGroupees: notificationsGroupees,
      actionsNotifications: actionsNotifications,
    );
    
    ref.read(settingsProvider.notifier).sauvegarderSettings(newSettings);
    
    // Si on désactive les notifications, annuler toutes les notifications programmées
    if (notificationsActives == false) {
      ref.read(notificationProvider.notifier).annulerToutesNotifications();
    }
  }

  void _updateNotificationSettings(
    WidgetRef ref,
    AppSettings settings,
    TypeNotification type,
    ParametresNotification nouveauxParametres,
  ) {
    final newNotificationSettings = Map<TypeNotification, ParametresNotification>.from(settings.parametresNotifications);
    newNotificationSettings[type] = nouveauxParametres;
    
    final newSettings = settings.copyWith(parametresNotifications: newNotificationSettings);
    ref.read(settingsProvider.notifier).sauvegarderSettings(newSettings);
  }

  void _showScheduledNotifications(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications programmées'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Consumer(
            builder: (context, ref, child) {
              final notifications = ref.watch(notificationsProgrammeesProvider);
              
              return notifications.when(
                data: (notifs) {
                  if (notifs.isEmpty) {
                    return const Center(
                      child: Text('Aucune notification programmée'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final notif = notifs[index];
                      return ListTile(
                        title: Text(notif.title ?? 'Sans titre'),
                        subtitle: Text(notif.body ?? 'Sans contenu'),
                        trailing: Text('ID: ${notif.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Erreur: $error'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllNotifications(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler toutes les notifications programmées ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationProvider.notifier).annulerToutesNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les notifications ont été annulées')),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
