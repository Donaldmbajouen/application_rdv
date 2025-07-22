# Système de Notifications - RDV App

## Fonctionnalités Implémentées

### 1. Service de Notifications (`lib/services/notification_service.dart`)
- **Initialisation** : Configuration Android/iOS avec permissions
- **Canaux de notification** Android avec sons et vibrations
- **Gestion des fuseaux horaires** avec package timezone
- **Programmation automatique** des notifications avec flutter_local_notifications

### 2. Types de Notifications
- **Rappels RDV** : Notifications programmées avant les rendez-vous (délai configurable)
- **Conflits** : Alertes immédiates lors de créneaux qui se chevauchent  
- **Changements de statut** : Notifications lors de modification d'état RDV
- **Relances clients** : Rappels pour clients inactifs (fonctionnalité future)
- **Anniversaires** : Rappels anniversaires clients (fonctionnalité future)

### 3. Modèles de Données

#### Extension AppSettings
```dart
enum TypeNotification { rappelRdv, conflit, anniversaire, relance, statut }

class ParametresNotification {
  final bool active;
  final int delaiMinutes;
  final bool son;
  final bool vibration;
  final String? sonPersonnalise;
}
```

#### Nouvelles propriétés AppSettings
- `parametresNotifications` : Configuration par type de notification
- `notificationsGroupees` : Groupement par jour
- `actionsNotifications` : Boutons d'action dans les notifications

### 4. Providers Riverpod (`lib/providers/notification_provider.dart`)
- **NotificationNotifier** : Gestion état et opérations notifications
- **Providers automatiques** : 
  - `notificationProvider` : État du service
  - `notificationsProgrammeesProvider` : Liste des notifications en attente
  - `notificationsActivesProvider` : État global actif/inactif
  - `parametresNotificationProvider` : Paramètres par type

### 5. Intégration avec RDV Provider
- **Auto-programmation** lors création RDV
- **Annulation** lors suppression RDV  
- **Reprogrammation** lors modification date/heure
- **Notifications de statut** lors changement d'état

### 6. Interface Utilisateur (`lib/screens/settings/notification_settings_screen.dart`)
- **Paramètres généraux** : Toggle global, groupement, actions
- **Configuration par type** : Activation, délais, son, vibration
- **Gestion avancée** : 
  - Visualisation notifications programmées
  - Annulation de toutes les notifications
  - Sliders pour délais configurables
- **Indicateurs d'état** : Erreurs, état du service

## Configuration Technique

### Dépendances ajoutées
```yaml
flutter_local_notifications: ^17.0.0
timezone: ^0.9.2
```

### Permissions requises

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
</array>
```

## Utilisation

### Programmation manuelle
```dart
final notifier = ref.read(notificationProvider.notifier);

// Programmer rappel RDV
await notifier.programmerNotificationsRdv(rendezVous);

// Notifier changement statut  
await notifier.notifierChangementStatut(rdv, ancienStatut);

// Annuler notifications RDV
await notifier.annulerNotificationsRdv(rdvId);
```

### Configuration utilisateur
```dart
// Accéder aux paramètres
final parametres = ref.watch(parametresNotificationProvider(TypeNotification.rappelRdv));

// Modifier paramètres
final newSettings = settings.copyWith(
  parametresNotifications: {
    TypeNotification.rappelRdv: parametres.copyWith(delaiMinutes: 30),
  }
);
ref.read(settingsProvider.notifier).updateSettings(newSettings);
```

## Fonctionnalités Avancées

### Actions dans les notifications
- **Confirmer RDV** : Action directe depuis la notification
- **Reporter RDV** : Redirection vers écran de modification
- **Appeler client** : Action pour relances clients

### Notifications groupées
- Regroupement par jour pour éviter le spam
- Affichage du nombre total de RDV du jour
- Expansion pour voir les détails

### Gestion des conflits
- Détection automatique lors création/modification RDV
- Notification immédiate avec liste des conflits
- Option pour forcer la création malgré conflits

## État et Limitations

### ✅ Fonctionnalités opérationnelles
- Service de notifications initialisé
- Programmation rappels RDV  
- Notifications de conflit
- Notifications de changement statut
- Interface de configuration complète
- Intégration avec providers RDV

### ⏳ Fonctionnalités futures
- **Anniversaires clients** : Nécessite ajout dateNaissance au modèle Client
- **Relances automatiques** : Logique de calcul dernière visite
- **Sons personnalisés** : Interface de sélection/upload
- **Actions avancées** : Navigation directe depuis notifications
- **Historique notifications** : Suivi des notifications envoyées

### 🔧 Configuration requise
1. **Permissions** : Ajouter permissions dans manifestes Android/iOS
2. **Icons** : Ajouter icônes de notification appropriées  
3. **Sounds** : Optionnel - ajouter sons personnalisés
4. **Testing** : Tester sur appareils physiques (simulateurs limités)

## Architecture

```
lib/
├── services/
│   └── notification_service.dart     # Service principal
├── providers/
│   └── notification_provider.dart    # État Riverpod
├── models/
│   └── app_settings.dart            # Extensions pour notifications
├── screens/settings/
│   └── notification_settings_screen.dart  # Interface utilisateur
└── providers/
    └── rendez_vous_provider.dart    # Intégration RDV (modifié)
```

Le système est prêt pour production avec configuration minimale des permissions et tests sur appareils réels.
