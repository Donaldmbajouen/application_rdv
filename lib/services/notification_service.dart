import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/rendez_vous.dart';
import '../models/client.dart';
import '../models/app_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'rdv_notifications';
  static const String _channelName = 'Notifications RDV';
  static const String _channelDescription = 'Notifications pour les rendez-vous et rappels';

  // IDs des notifications
  static const int _rappelRdvId = 1000;
  static const int _conflitId = 2000;
  static const int _anniversaireId = 3000;
  static const int _relanceId = 4000;
  static const int _statutId = 5000;

  /// Initialise le service de notifications
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        await _createNotificationChannel();
        _initialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur initialisation notifications: $e');
      return false;
    }
  }

  /// Crée le canal de notification Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Callback pour notifications iOS en premier plan
  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    debugPrint('Notification reçue iOS: $title');
  }

  /// Callback lors du tap sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tappée: ${response.payload}');
    // TODO: Navigation vers l'écran approprié
  }

  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Programme un rappel de RDV
  Future<void> programmerRappelRdv(
    RendezVous rdv,
    ParametresNotification parametres,
  ) async {
    if (!_initialized || !parametres.active) return;

    final dateRappel = rdv.dateHeure.subtract(Duration(minutes: parametres.delaiMinutes));
    
    // Ne pas programmer si la date est déjà passée
    if (dateRappel.isBefore(DateTime.now())) return;

    final id = _rappelRdvId + (rdv.id ?? 0);
    
    await _notifications.zonedSchedule(
      id,
      'Rendez-vous dans ${parametres.delaiMinutes} minutes',
      '${rdv.clientNomComplet} - ${rdv.serviceNom}\n${_formatHeure(rdv.dateHeure)}',
      _convertToTimeZone(dateRappel),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: parametres.son,
          enableVibration: parametres.vibration,
          actions: parametres.active && rdv.statut == StatutRendezVous.confirme ? [
            const AndroidNotificationAction('confirm', 'Confirmer'),
            const AndroidNotificationAction('reschedule', 'Reporter'),
          ] : null,
        ),
        iOS: DarwinNotificationDetails(
          sound: parametres.son ? 'default' : null,
          presentAlert: true,
          presentBadge: true,
          presentSound: parametres.son,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'rdv_reminder_${rdv.id}',
    );
  }

  /// Programme une notification de conflit
  Future<void> programmerNotificationConflit(
    List<RendezVous> conflits,
    ParametresNotification parametres,
  ) async {
    if (!_initialized || !parametres.active || conflits.isEmpty) return;

    final now = DateTime.now();
    final id = _conflitId + now.millisecondsSinceEpoch % 1000;

    await _notifications.show(
      id,
      'Conflit de rendez-vous détecté',
      '${conflits.length} rendez-vous en conflit',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: parametres.son,
          enableVibration: parametres.vibration,
          styleInformation: BigTextStyleInformation(
            conflits.map((rdv) => '${rdv.clientNomComplet} - ${_formatHeure(rdv.dateHeure)}').join('\n'),
          ),
        ),
        iOS: DarwinNotificationDetails(
          sound: parametres.son ? 'default' : null,
          presentAlert: true,
          presentBadge: true,
          presentSound: parametres.son,
        ),
      ),
      payload: 'conflict_${conflits.map((r) => r.id).join('_')}',
    );
  }

  /// Programme un rappel d'anniversaire client (fonctionnalité future)
  Future<void> programmerRappelAnniversaire(
    Client client,
    ParametresNotification parametres,
  ) async {
    // TODO: Implémenter quand le modèle Client aura dateNaissance
    debugPrint('Fonctionnalité anniversaire pas encore disponible');
  }

  /// Programme une notification de relance client
  Future<void> programmerRelanceClient(
    Client client,
    DateTime derniereVisite,
    int joursDelai,
    ParametresNotification parametres,
  ) async {
    if (!_initialized || !parametres.active) return;

    final dateRelance = derniereVisite.add(Duration(days: joursDelai));
    
    // Ne pas programmer si la date est déjà passée
    if (dateRelance.isBefore(DateTime.now())) return;

    final id = _relanceId + (client.id ?? 0);

    await _notifications.zonedSchedule(
      id,
      'Relance client',
      '${client.nomComplet} n\'a pas eu de RDV depuis ${joursDelai} jours',
      _convertToTimeZone(dateRelance),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: parametres.son,
          enableVibration: parametres.vibration,
          actions: [
            const AndroidNotificationAction('call', 'Appeler'),
            const AndroidNotificationAction('schedule', 'Programmer RDV'),
          ],
        ),
        iOS: DarwinNotificationDetails(
          sound: parametres.son ? 'default' : null,
          presentAlert: true,
          presentBadge: true,
          presentSound: parametres.son,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'client_reminder_${client.id}',
    );
  }

  /// Programme une notification de changement de statut
  Future<void> programmerNotificationStatut(
    RendezVous rdv,
    StatutRendezVous ancienStatut,
    ParametresNotification parametres,
  ) async {
    if (!_initialized || !parametres.active) return;

    final id = _statutId + (rdv.id ?? 0);
    String titre, message;

    switch (rdv.statut) {
      case StatutRendezVous.confirme:
        titre = 'RDV confirmé';
        message = '${rdv.clientNomComplet} - ${_formatHeure(rdv.dateHeure)}';
        break;
      case StatutRendezVous.annule:
        titre = 'RDV annulé';
        message = '${rdv.clientNomComplet} - ${_formatHeure(rdv.dateHeure)}';
        break;
      case StatutRendezVous.complete:
        titre = 'RDV terminé';
        message = '${rdv.clientNomComplet} - ${rdv.prixFormate}';
        break;
      case StatutRendezVous.enAttente:
        titre = 'RDV en attente';
        message = '${rdv.clientNomComplet} - ${_formatHeure(rdv.dateHeure)}';
        break;
    }

    await _notifications.show(
      id,
      titre,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: parametres.son,
          enableVibration: parametres.vibration,
        ),
        iOS: DarwinNotificationDetails(
          sound: parametres.son ? 'default' : null,
          presentAlert: true,
          presentBadge: true,
          presentSound: parametres.son,
        ),
      ),
      payload: 'status_change_${rdv.id}_${rdv.statut.index}',
    );
  }

  /// Annule une notification spécifique
  Future<void> annulerNotification(int id) async {
    if (!_initialized) return;
    await _notifications.cancel(id);
  }

  /// Annule toutes les notifications liées à un RDV
  Future<void> annulerNotificationsRdv(int rdvId) async {
    if (!_initialized) return;
    
    final ids = [
      _rappelRdvId + rdvId,
      _statutId + rdvId,
    ];

    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  /// Annule toutes les notifications liées à un client
  Future<void> annulerNotificationsClient(int clientId) async {
    if (!_initialized) return;
    
    final ids = [
      _anniversaireId + clientId,
      _relanceId + clientId,
    ];

    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  /// Annule toutes les notifications
  Future<void> annulerToutesNotifications() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
  }

  /// Obtient les notifications programmées
  Future<List<PendingNotificationRequest>> obtenirNotificationsProgrammees() async {
    if (!_initialized) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Formate l'heure au format français
  String _formatHeure(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Convertit une DateTime en TZDateTime pour la programmation
  tz.TZDateTime _convertToTimeZone(DateTime dateTime) {
    // Initialise les données de fuseau horaire si nécessaire
    tz_data.initializeTimeZones();
    final location = tz.getLocation('Europe/Paris');
    return tz.TZDateTime.from(dateTime, location);
  }
}

/// Extension pour obtenir les paramètres de notification par type
extension AppSettingsNotifications on AppSettings {
  ParametresNotification parametresNotification(TypeNotification type) {
    return parametresNotifications[type] ?? const ParametresNotification();
  }

  bool isNotificationActive(TypeNotification type) {
    return notificationsActives && parametresNotification(type).active;
  }
}
