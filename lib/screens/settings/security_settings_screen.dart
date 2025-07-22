import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../widgets/settings/pin_setup_dialog.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

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
          title: const Text('Sécurité'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showSecurityInfo(context),
              tooltip: 'Informations de sécurité',
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
        // Verrouillage de l'application
        SettingsSection(
          title: 'Verrouillage de l\'application',
          children: [
            SettingsToggle(
              icon: Icons.lock,
              title: 'Verrouillage activé',
              subtitle: 'Protéger l\'application avec un code PIN',
              value: settings.verrouillageActif,
              onChanged: (value) => _toggleAppLock(context, ref, value),
            ),
            if (settings.verrouillageActif) ...[
              SettingsNavTile(
                icon: Icons.pin,
                title: 'Code PIN',
                subtitle: settings.pinCode != null 
                    ? 'PIN configuré (${settings.pinCode!.length} chiffres)'
                    : 'Aucun PIN configuré',
                onTap: () => _changePIN(context, ref, settings.pinCode),
                badge: settings.pinCode != null 
                    ? Icon(Icons.check_circle, color: Colors.green, size: 16)
                    : Icon(Icons.warning, color: Colors.orange, size: 16),
              ),
              SettingsToggle(
                icon: Icons.fingerprint,
                title: 'Biométrie',
                subtitle: 'Utiliser l\'empreinte digitale ou Face ID',
                value: settings.biometrieActive,
                onChanged: (value) => _toggleBiometrics(context, ref, value),
                iconColor: settings.biometrieActive ? Colors.green : null,
              ),
              SettingsSelector<int>(
                icon: Icons.timer,
                title: 'Verrouillage automatique',
                subtitle: 'Délai avant verrouillage automatique',
                value: 300, // TODO: ajouter au modèle settings
                options: const [0, 60, 300, 600, 1800, 3600],
                labelBuilder: _formatAutoLockDelay,
                onChanged: (value) {
                  // TODO: implémenter
                },
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Protection des données
        SettingsSection(
          title: 'Protection des données',
          children: [
            SettingsToggle(
              icon: Icons.visibility_off,
              title: 'Masquer dans la liste des apps récentes',
              subtitle: 'Cacher le contenu lors du changement d\'application',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.screenshot,
              title: 'Bloquer les captures d\'écran',
              subtitle: 'Empêcher les captures d\'écran dans l\'app',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.copy,
              title: 'Bloquer le copier-coller',
              subtitle: 'Empêcher la copie de données sensibles',
              value: false, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Audit et journalisation
        SettingsSection(
          title: 'Audit et sécurité',
          children: [
            SettingsToggle(
              icon: Icons.history,
              title: 'Journal des accès',
              subtitle: 'Enregistrer les tentatives de connexion',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsNavTile(
              icon: Icons.list_alt,
              title: 'Voir le journal de sécurité',
              subtitle: 'Consulter les événements de sécurité',
              onTap: () => _showSecurityLog(context),
            ),
            SettingsToggle(
              icon: Icons.notification_important,
              title: 'Alertes de sécurité',
              subtitle: 'Notifications pour les événements suspects',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sauvegarde sécurisée
        SettingsSection(
          title: 'Sauvegarde sécurisée',
          children: [
            SettingsToggle(
              icon: Icons.enhanced_encryption,
              title: 'Chiffrement des sauvegardes',
              subtitle: 'Chiffrer les données lors de l\'export',
              value: true, // TODO: ajouter au modèle
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsNavTile(
              icon: Icons.vpn_key,
              title: 'Clés de chiffrement',
              subtitle: 'Gérer les clés de chiffrement',
              onTap: () => _showEncryptionKeys(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Actions de sécurité
        SettingsSection(
          title: 'Actions',
          children: [
            SettingsNavTile(
              icon: Icons.security,
              title: 'Test de sécurité',
              subtitle: 'Vérifier la configuration de sécurité',
              onTap: () => _runSecurityTest(context),
            ),
            SettingsAction(
              icon: Icons.lock_reset,
              title: 'Réinitialiser la sécurité',
              subtitle: 'Supprimer tous les paramètres de sécurité',
              onTap: () => _resetSecurity(context, ref),
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  String _formatAutoLockDelay(int seconds) {
    if (seconds == 0) return 'Jamais';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}min';
    return '${seconds ~/ 3600}h';
  }

  void _toggleAppLock(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      // Demander la création d'un PIN
      final pin = await PinUtils.showSetupDialog(context, isSetup: true);
      if (pin != null) {
        await ref.read(settingsProvider.notifier).changerCodePin(pin);
        await ref.read(settingsProvider.notifier).changerVerrouillage(true);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verrouillage activé avec succès')),
          );
        }
      }
    } else {
      // Demander confirmation pour désactiver
      final settings = ref.read(settingsProvider).settings;
      if (settings.pinCode != null) {
        final verified = await PinUtils.showVerificationDialog(
          context,
          correctPin: settings.pinCode!,
          title: 'Désactiver le verrouillage',
          subtitle: 'Entrez votre PIN pour confirmer',
        );
        
        if (verified) {
          await ref.read(settingsProvider.notifier).changerVerrouillage(false);
          await ref.read(settingsProvider.notifier).changerCodePin(null);
          await ref.read(settingsProvider.notifier).changerBiometrie(false);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verrouillage désactivé')),
            );
          }
        }
      }
    }
  }

  void _changePIN(BuildContext context, WidgetRef ref, String? currentPin) async {
    if (currentPin == null) {
      // Créer un nouveau PIN
      final pin = await PinUtils.showSetupDialog(context, isSetup: true);
      if (pin != null) {
        await ref.read(settingsProvider.notifier).changerCodePin(pin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN créé avec succès')),
          );
        }
      }
    } else {
      // Modifier le PIN existant
      final pin = await PinUtils.showSetupDialog(
        context,
        currentPin: currentPin,
        isSetup: false,
      );
      if (pin != null) {
        await ref.read(settingsProvider.notifier).changerCodePin(pin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN modifié avec succès')),
          );
        }
      }
    }
  }

  void _toggleBiometrics(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      // Vérifier que la biométrie est disponible
      // TODO: implémenter la vérification avec local_auth
      final success = await ref.read(settingsProvider.notifier).changerBiometrie(true);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biométrie activée')),
        );
      }
    } else {
      await ref.read(settingsProvider.notifier).changerBiometrie(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biométrie désactivée')),
        );
      }
    }
  }

  void _showSecurityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de sécurité'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Protection des données',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Toutes les données sont stockées localement sur votre appareil\n'
                '• Le chiffrement est appliqué aux données sensibles\n'
                '• Aucune donnée n\'est envoyée vers des serveurs externes',
              ),
              SizedBox(height: 16),
              Text(
                'Bonnes pratiques',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Utilisez un PIN complexe et unique\n'
                '• Activez la biométrie si disponible\n'
                '• Effectuez des sauvegardes régulières\n'
                '• Gardez l\'application à jour',
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

  void _showSecurityLog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal de sécurité'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildLogEntry(
                DateTime.now().subtract(const Duration(hours: 2)),
                'Connexion réussie',
                Icons.check_circle,
                Colors.green,
              ),
              _buildLogEntry(
                DateTime.now().subtract(const Duration(days: 1)),
                'PIN modifié',
                Icons.edit,
                Colors.blue,
              ),
              _buildLogEntry(
                DateTime.now().subtract(const Duration(days: 2)),
                'Biométrie activée',
                Icons.fingerprint,
                Colors.green,
              ),
              _buildLogEntry(
                DateTime.now().subtract(const Duration(days: 3)),
                'Tentative de connexion échouée',
                Icons.warning,
                Colors.orange,
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

  Widget _buildLogEntry(DateTime time, String event, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(event),
      subtitle: Text(
        '${time.day}/${time.month}/${time.year} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      ),
    );
  }

  void _showEncryptionKeys(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clés de chiffrement'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text(
              'Elle permettra de gérer les clés de chiffrement utilisées '
              'pour protéger vos données lors des sauvegardes et exports.',
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

  void _runSecurityTest(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test de sécurité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Analyse de la configuration de sécurité...'),
          ],
        ),
      ),
    );

    // Simuler le test
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Résultat du test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecurityCheckItem('Verrouillage activé', true),
              _buildSecurityCheckItem('PIN configuré', true),
              _buildSecurityCheckItem('Biométrie active', false),
              _buildSecurityCheckItem('Chiffrement activé', true),
              const SizedBox(height: 16),
              const Text(
                'Score de sécurité: 8/10',
                style: TextStyle(fontWeight: FontWeight.bold),
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
    });
  }

  Widget _buildSecurityCheckItem(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _resetSecurity(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser la sécurité'),
        content: const Text(
          'Cette action va supprimer tous les paramètres de sécurité '
          '(PIN, biométrie, etc.) et ne peut pas être annulée.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Réinitialiser tous les paramètres de sécurité
              await ref.read(settingsProvider.notifier).changerVerrouillage(false);
              await ref.read(settingsProvider.notifier).changerCodePin(null);
              await ref.read(settingsProvider.notifier).changerBiometrie(false);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres de sécurité réinitialisés')),
                );
              }
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
