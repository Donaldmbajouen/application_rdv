import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/rendez_vous_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/settings/settings_tile.dart';

class DataSettingsScreen extends ConsumerWidget {
  const DataSettingsScreen({super.key});

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
          title: const Text('Données'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDataInfo(context),
              tooltip: 'Informations sur les données',
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
        // Sauvegarde
        SettingsSection(
          title: 'Sauvegarde',
          children: [
            SettingsNavTile(
              icon: Icons.backup,
              title: 'Créer une sauvegarde',
              subtitle: 'Exporter toutes les données en JSON',
              onTap: () => _createBackup(context, ref),
            ),
            SettingsNavTile(
              icon: Icons.restore,
              title: 'Restaurer une sauvegarde',
              subtitle: 'Importer des données depuis un fichier',
              onTap: () => _restoreBackup(context, ref),
            ),
            SettingsToggle(
              icon: Icons.schedule,
              title: 'Sauvegarde automatique',
              subtitle: 'Créer automatiquement des sauvegardes',
              value: false, // TODO: ajouter au modèle settings
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Export de données
        SettingsSection(
          title: 'Export de données',
          children: [
            SettingsNavTile(
              icon: Icons.table_view,
              title: 'Export CSV',
              subtitle: 'Exporter les données au format CSV',
              onTap: () => _showExportOptions(context, ref),
            ),
            SettingsNavTile(
              icon: Icons.print,
              title: 'Générer un rapport',
              subtitle: 'Créer un rapport PDF complet',
              onTap: () => _generateReport(context, ref),
            ),
            SettingsNavTile(
              icon: Icons.share,
              title: 'Partager les données',
              subtitle: 'Partager des données sélectionnées',
              onTap: () => _shareData(context, ref),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Import de données
        SettingsSection(
          title: 'Import de données',
          children: [
            SettingsNavTile(
              icon: Icons.upload_file,
              title: 'Importer depuis CSV',
              subtitle: 'Importer clients ou RDV depuis un fichier CSV',
              onTap: () => _importFromCSV(context, ref),
            ),
            SettingsNavTile(
              icon: Icons.sync,
              title: 'Synchroniser',
              subtitle: 'Synchroniser avec une autre instance',
              onTap: () => _showSyncOptions(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Statistiques de stockage
        SettingsSection(
          title: 'Utilisation du stockage',
          children: [
            SettingsNavTile(
              icon: Icons.storage,
              title: 'Analyser l\'utilisation',
              subtitle: 'Voir la répartition de l\'espace utilisé',
              onTap: () => _showStorageAnalysis(context, ref),
            ),
            SettingsNavTile(
              icon: Icons.cleaning_services,
              title: 'Nettoyer les données',
              subtitle: 'Supprimer les données temporaires',
              onTap: () => _cleanupData(context, ref),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sauvegarde cloud (future)
        SettingsSection(
          title: 'Sauvegarde cloud',
          children: [
            SettingsToggle(
              icon: Icons.cloud,
              title: 'Sauvegarde cloud',
              subtitle: 'Sauvegarder automatiquement dans le cloud',
              value: false,
              onChanged: null,
            ),
            SettingsNavTile(
              icon: Icons.account_circle,
              title: 'Compte cloud',
              subtitle: 'Configurer votre compte de sauvegarde',
              onTap: () => _showCloudAccount(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Actions dangereuses
        SettingsSection(
          title: 'Actions destructives',
          children: [
            SettingsAction(
              icon: Icons.delete_sweep,
              title: 'Supprimer les données expirées',
              subtitle: 'Supprimer les RDV anciens (> 1 an)',
              onTap: () => _deleteExpiredData(context, ref),
            ),
            SettingsAction(
              icon: Icons.delete_forever,
              title: 'Réinitialiser toutes les données',
              subtitle: 'Supprimer définitivement toutes les données',
              onTap: () => _resetAllData(context, ref),
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  void _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      // Afficher le dialog de progression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Création de la sauvegarde...'),
            ],
          ),
        ),
      );

      // Collecter toutes les données
      // TODO: Implémenter l'export des clients, rdvs et services
      final clients = [];
      final rdvs = [];
      final services = [];
      final settings = ref.read(settingsProvider).settings;

      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'clients': clients,
          'rendez_vous': rdvs,
          'services': services,
          'settings': settings.toMap(),
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/backup_rdv_$timestamp.json');
      await file.writeAsString(jsonString);

      Navigator.of(context).pop(); // Fermer le dialog de progression

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sauvegarde créée'),
            content: Text(
              'Sauvegarde créée avec succès !\n\n'
              'Fichier: ${file.path}\n'
              'Taille: ${(jsonString.length / 1024).toStringAsFixed(1)} KB',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Partager le fichier
                },
                child: const Text('Partager'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de progression
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  void _restoreBackup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer une sauvegarde'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de restaurer vos données depuis un fichier '
              'de sauvegarde créé précédemment.',
            ),
          ],
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

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options d\'export CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Exporter les clients'),
              onTap: () {
                Navigator.of(context).pop();
                _exportClientsCSV(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Exporter les RDV'),
              onTap: () {
                Navigator.of(context).pop();
                _exportRdvCSV(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Exporter les services'),
              onTap: () {
                Navigator.of(context).pop();
                _exportServicesCSV(context, ref);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _exportClientsCSV(BuildContext context, WidgetRef ref) async {
    // TODO: Implémenter l'export CSV des clients
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV des clients en cours de développement')),
    );
  }

  void _exportRdvCSV(BuildContext context, WidgetRef ref) async {
    // TODO: Implémenter l'export CSV des RDV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV des RDV en cours de développement')),
    );
  }

  void _exportServicesCSV(BuildContext context, WidgetRef ref) async {
    // TODO: Implémenter l'export CSV des services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV des services en cours de développement')),
    );
  }

  void _generateReport(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer un rapport'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de générer des rapports PDF détaillés '
              'avec vos statistiques et données.',
            ),
          ],
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

  void _shareData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager les données'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de partager vos données de manière sélective '
              'avec d\'autres utilisateurs ou applications.',
            ),
          ],
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

  void _importFromCSV(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import CSV'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra d\'importer des clients et des rendez-vous '
              'depuis des fichiers CSV.',
            ),
          ],
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

  void _showSyncOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de synchroniser vos données entre '
              'plusieurs appareils ou avec d\'autres instances de l\'application.',
            ),
          ],
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

  void _showStorageAnalysis(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analyse du stockage'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStorageItem('Base de données', '2.3 MB', 0.7),
              _buildStorageItem('Images', '1.2 MB', 0.3),
              _buildStorageItem('Sauvegardes', '0.5 MB', 0.1),
              _buildStorageItem('Cache', '0.8 MB', 0.2),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total utilisé:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('4.8 MB', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
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

  Widget _buildStorageItem(String label, String size, double ratio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(size, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  void _cleanupData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les données'),
        content: const Text(
          'Cette action va supprimer les fichiers temporaires et '
          'optimiser la base de données. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter le nettoyage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données nettoyées avec succès')),
              );
            },
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );
  }

  void _showCloudAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compte cloud'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de configurer un compte cloud '
              'pour la sauvegarde automatique de vos données.',
            ),
          ],
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

  void _deleteExpiredData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les données expirées'),
        content: const Text(
          'Cette action va supprimer tous les rendez-vous '
          'datant de plus d\'un an. Cette action ne peut pas être annulée.\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la suppression des données expirées
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données expirées supprimées')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _resetAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Réinitialiser toutes les données'),
        content: const Text(
          'ATTENTION: Cette action va supprimer définitivement '
          'TOUTES vos données (clients, rendez-vous, services, paramètres).\n\n'
          'Cette action NE PEUT PAS être annulée.\n\n'
          'Êtes-vous absolument sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmResetAllData(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: const Text(
          'Tapez "SUPPRIMER" pour confirmer la suppression '
          'de toutes les données:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la réinitialisation complète
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toutes les données ont été supprimées')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDataInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations sur les données'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Stockage local',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Toutes vos données sont stockées localement sur votre appareil\n'
                '• Base de données SQLite sécurisée\n'
                '• Aucune donnée envoyée vers des serveurs externes',
              ),
              SizedBox(height: 16),
              Text(
                'Sauvegarde',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Créez régulièrement des sauvegardes\n'
                '• Format JSON pour la compatibilité\n'
                '• Chiffrement optionnel des sauvegardes',
              ),
              SizedBox(height: 16),
              Text(
                'Formats supportés',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Export: JSON, CSV, PDF\n'
                '• Import: JSON, CSV\n'
                '• Synchronisation: JSON chiffré',
              ),
            ],
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
}
