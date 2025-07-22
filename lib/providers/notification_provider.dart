import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../models/rendez_vous.dart';
import '../models/client.dart';
import '../models/app_settings.dart';
import 'settings_provider.dart';
import 'rendez_vous_provider.dart';

/// Provider pour le service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notifier pour la gestion des notifications
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationService _notificationService;
  final Ref _ref;

  NotificationNotifier(this._notificationService, this._ref) : super(const AsyncValue.data(null)) {
    _initialize();
  }

  /// Initialise le service de notifications
  Future<void> _initialize() async {
    state = const AsyncValue.loading();
    try {
      final success = await _notificationService.initialize();
      if (success) {
        await _notificationService.requestPermissions();
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error('Échec de l\'initialisation des notifications', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Programme les notifications pour un RDV
  Future<void> programmerNotificationsRdv(RendezVous rdv) async {
    try {
      final settings = _ref.read(appSettingsProvider);
      if (!settings.notificationsActives) return;

      // Notification de rappel
      final parametresRappel = settings.parametresNotification(TypeNotification.rappelRdv);
      if (parametresRappel.active) {
        await _notificationService.programmerRappelRdv(rdv, parametresRappel);
      }

      // Vérifier les conflits si c'est un nouveau RDV
      if (rdv.id != null) {
        final rdvProvider = _ref.read(rendezVousProvider.notifier);
        final conflits = await rdvProvider.verifierConflits(
          rdv.dateHeure,
          rdv.dureeMinutes,
          excludeId: rdv.id,
        );

        if (conflits.isNotEmpty) {
          final parametresConflit = settings.parametresNotification(TypeNotification.conflit);
          if (parametresConflit.active) {
            await _notificationService.programmerNotificationConflit(conflits, parametresConflit);
          }
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Annule les notifications pour un RDV
  Future<void> annulerNotificationsRdv(int rdvId) async {
    try {
      await _notificationService.annulerNotificationsRdv(rdvId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Programme les notifications pour un client
  Future<void> programmerNotificationsClient(Client client) async {
    try {
      final settings = _ref.read(appSettingsProvider);
      if (!settings.notificationsActives) return;

      // Notification d'anniversaire (si disponible)
      final parametresAnniversaire = settings.parametresNotification(TypeNotification.anniversaire);
      if (parametresAnniversaire.active) {
        await _notificationService.programmerRappelAnniversaire(client, parametresAnniversaire);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Annule les notifications pour un client
  Future<void> annulerNotificationsClient(int clientId) async {
    try {
      await _notificationService.annulerNotificationsClient(clientId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Programme une notification de changement de statut
  Future<void> notifierChangementStatut(
    RendezVous rdv,
    StatutRendezVous ancienStatut,
  ) async {
    try {
      final settings = _ref.read(appSettingsProvider);
      if (!settings.notificationsActives) return;

      final parametresStatut = settings.parametresNotification(TypeNotification.statut);
      if (parametresStatut.active) {
        await _notificationService.programmerNotificationStatut(rdv, ancienStatut, parametresStatut);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Programme une notification de relance client
  Future<void> programmerRelanceClient(
    Client client,
    DateTime derniereVisite,
    int joursDelai,
  ) async {
    try {
      final settings = _ref.read(appSettingsProvider);
      if (!settings.notificationsActives) return;

      final parametresRelance = settings.parametresNotification(TypeNotification.relance);
      if (parametresRelance.active) {
        await _notificationService.programmerRelanceClient(
          client,
          derniereVisite,
          joursDelai,
          parametresRelance,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Obtient les notifications programmées
  Future<List<PendingNotificationRequest>> obtenirNotificationsProgrammees() async {
    try {
      return await _notificationService.obtenirNotificationsProgrammees();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }

  /// Annule toutes les notifications
  Future<void> annulerToutesNotifications() async {
    try {
      await _notificationService.annulerToutesNotifications();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Réinitialise l'état
  void resetState() {
    state = const AsyncValue.data(null);
  }
}

/// Provider pour le gestionnaire de notifications
final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service, ref);
});

/// Provider pour les notifications programmées
final notificationsProgrammeesProvider = FutureProvider<List<PendingNotificationRequest>>((ref) async {
  final notifier = ref.watch(notificationProvider.notifier);
  return await notifier.obtenirNotificationsProgrammees();
});

/// Provider pour vérifier si les notifications sont activées
final notificationsActivesProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.notificationsActives;
});

/// Provider pour les paramètres de notification par type
final parametresNotificationProvider = Provider.family<ParametresNotification, TypeNotification>((ref, type) {
  final settings = ref.watch(appSettingsProvider);
  return settings.parametresNotification(type);
});
