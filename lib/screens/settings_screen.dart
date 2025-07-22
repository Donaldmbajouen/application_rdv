import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import '../providers/theme_provider.dart' as theme_provider;
import 'package:flutter/material.dart' show ThemeMode;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(theme_provider.themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil utilisateur
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Utilisateur RDV',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestion de rendez-vous',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section Apparence
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.palette),
                  title: Text('Apparence', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(LineIcons.moon),
                  title: const Text('Thème'),
                  subtitle: Text(_getThemeLabel(currentTheme)),
                  trailing: DropdownButton<ThemeMode>(
                    value: currentTheme,
                    onChanged: (theme) {
                      if (theme != null) {
                        ref.read(theme_provider.themeProvider.notifier).setTheme(theme);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Clair'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Sombre'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Système'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section RDV
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.calendar),
                  title: Text('Rendez-vous', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(LineIcons.clock),
                  title: const Text('Durée par défaut'),
                  subtitle: const Text('30 minutes'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LineIcons.businessTime),
                  title: const Text('Horaires d\'ouverture'),
                  subtitle: const Text('Lundi-Vendredi 9h-18h'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Notifications
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.bell),
                  title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(LineIcons.bellSlash),
                  title: const Text('Rappels RDV'),
                  subtitle: const Text('1 heure avant'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Sécurité
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.lock),
                  title: Text('Sécurité', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(LineIcons.key),
                  title: const Text('Code PIN'),
                  subtitle: const Text('Non configuré'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LineIcons.fingerprint),
                  title: const Text('Authentification biométrique'),
                  subtitle: const Text('Désactivée'),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Données
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.database),
                  title: Text('Données', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(LineIcons.download),
                  title: const Text('Exporter les données'),
                  subtitle: const Text('CSV, JSON'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LineIcons.upload),
                  title: const Text('Importer les données'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LineIcons.trash),
                  title: const Text('Réinitialiser'),
                  subtitle: const Text('Supprimer toutes les données'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showResetConfirmation(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Section À propos
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(LineIcons.infoCircle),
                  title: Text('À propos', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const ListTile(
                  leading: Icon(LineIcons.mobilePhone),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(LineIcons.heart),
                  title: const Text('Évaluer l\'application'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Automatique';
    }
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les données'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos données (clients, services, rendez-vous).\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité en cours de développement'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
