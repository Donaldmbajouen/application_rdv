import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/settings/settings_tile.dart';
import '../widgets/settings/theme_selector.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/rdv_settings_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/security_settings_screen.dart';
import 'settings/data_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          const QuickThemeToggle(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSettings(context),
            tooltip: 'Rechercher dans les paramètres',
          ),
        ],
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settingsState.error != null
              ? Center(
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
                )
              : _buildContent(context, ref, settingsState.settings, isDark),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, settings, bool isDark) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profil utilisateur
        _buildUserProfile(context, theme, colors),

        const SizedBox(height: 24),

        // Apparence
        SettingsSection(
          title: 'Apparence',
          children: [
            SettingsNavTile(
              icon: Icons.palette,
              title: 'Thème et apparence',
              subtitle: isDark ? 'Mode sombre activé' : 'Mode clair activé',
              onTap: () => _navigateToScreen(context, const AppearanceSettingsScreen()),
              iconColor: colors.primary,
            ),
            SettingsSelector<String>(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Changer la langue de l\'application',
              value: settings.langue,
              options: const ['fr', 'en'],
              labelBuilder: (lang) => lang == 'fr' ? 'Français' : 'English',
              onChanged: (newLang) => ref.read(settingsProvider.notifier).changerLangue(newLang),
              iconColor: Colors.blue,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rendez-vous
        SettingsSection(
          title: 'Rendez-vous',
          children: [
            SettingsNavTile(
              icon: Icons.schedule,
              title: 'Paramètres RDV',
              subtitle: 'Durée, horaires et validation',
              onTap: () => _navigateToScreen(context, const RdvSettingsScreen()),
              iconColor: Colors.green,
              badge: _buildOpenDaysBadge(context, settings),
            ),
            SettingsSlider(
              icon: Icons.timer,
              title: 'Durée par défaut',
              subtitle: 'Durée des nouveaux rendez-vous',
              value: settings.dureeDefautMinutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 11,
              labelFormatter: (value) => '${value.round()} min',
              onChanged: (value) => ref.read(settingsProvider.notifier)
                  .changerDureeDefaut(value.round()),
              iconColor: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Notifications
        SettingsSection(
          title: 'Notifications',
          children: [
            SettingsToggle(
              icon: Icons.notifications,
              title: 'Notifications activées',
              subtitle: 'Recevoir des notifications push',
              value: settings.notificationsActives,
              onChanged: (value) => ref.read(settingsProvider.notifier).changerNotifications(value),
              iconColor: settings.notificationsActives ? Colors.blue : null,
            ),
            SettingsNavTile(
              icon: Icons.notification_important,
              title: 'Paramètres avancés',
              subtitle: 'Personnaliser chaque type de notification',
              onTap: () => _navigateToScreen(context, const NotificationSettingsScreen()),
              iconColor: Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sécurité
        SettingsSection(
          title: 'Sécurité et confidentialité',
          children: [
            SettingsToggle(
              icon: Icons.lock,
              title: 'Verrouillage de l\'app',
              subtitle: settings.verrouillageActif 
                  ? 'Application verrouillée par PIN'
                  : 'Application non verrouillée',
              value: settings.verrouillageActif,
              onChanged: null, // Géré dans l'écran dédié
              iconColor: settings.verrouillageActif ? Colors.red : Colors.grey,
            ),
            SettingsNavTile(
              icon: Icons.security,
              title: 'Paramètres de sécurité',
              subtitle: 'PIN, biométrie et protection des données',
              onTap: () => _navigateToScreen(context, const SecuritySettingsScreen()),
              iconColor: Colors.red,
              badge: settings.verrouillageActif 
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                  : const Icon(Icons.warning, color: Colors.orange, size: 16),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Données
        SettingsSection(
          title: 'Données et sauvegarde',
          children: [
            SettingsNavTile(
              icon: Icons.backup,
              title: 'Sauvegarde et restauration',
              subtitle: 'Gérer vos données et sauvegardes',
              onTap: () => _navigateToScreen(context, const DataSettingsScreen()),
              iconColor: Colors.indigo,
            ),
            SettingsNavTile(
              icon: Icons.import_export,
              title: 'Import/Export',
              subtitle: 'Exporter ou importer vos données',
              onTap: () => _navigateToScreen(context, const DataSettingsScreen()),
              iconColor: Colors.teal,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // À propos
        SettingsSection(
          title: 'À propos',
          children: [
            SettingsNavTile(
              icon: Icons.info,
              title: 'Informations sur l\'app',
              subtitle: 'Version, développeur et mentions légales',
              onTap: () => _showAboutDialog(context),
              iconColor: Colors.grey,
            ),
            SettingsNavTile(
              icon: Icons.help,
              title: 'Aide et support',
              subtitle: 'Guide d\'utilisation et contact',
              onTap: () => _showHelpDialog(context),
              iconColor: Colors.blue,
            ),
            SettingsNavTile(
              icon: Icons.star,
              title: 'Évaluer l\'application',
              subtitle: 'Donnez votre avis sur le store',
              onTap: () => _rateApp(context),
              iconColor: Colors.amber,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Actions rapides
        _buildQuickActions(context, ref, colors),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.person,
                size: 32,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilisateur RDV',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion de rendez-vous',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProfile(context),
              tooltip: 'Modifier le profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenDaysBadge(BuildContext context, settings) {
    final openDays = settings.horaires.values.where((h) => h.ouvert).length;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$openDays/7 jours',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.backup,
                    label: 'Sauvegarde',
                    onTap: () => _navigateToScreen(context, const DataSettingsScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.security,
                    label: 'Sécurité',
                    onTap: () => _navigateToScreen(context, const SecuritySettingsScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.refresh,
                    label: 'Réinitialiser',
                    onTap: () => _showResetDialog(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showSearchSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche de paramètres'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text('Elle permettra de rechercher rapidement dans tous les paramètres.'),
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

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
            SizedBox(height: 16),
            Text('Elle permettra de personnaliser votre profil utilisateur.'),
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RDV Manager',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.calendar_month, size: 48),
      children: const [
        Text('Application de gestion de rendez-vous développée avec Flutter.'),
        SizedBox(height: 16),
        Text('Fonctionnalités principales:'),
        Text('• Gestion des clients'),
        Text('• Planning des rendez-vous'),
        Text('• Notifications intelligentes'),
        Text('• Statistiques détaillées'),
        Text('• Sauvegarde sécurisée'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide et support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Guide rapide:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Utilisez l\'onglet Calendrier pour voir vos RDV'),
              Text('• L\'onglet Clients pour gérer vos contacts'),
              Text('• Créez des services dans l\'onglet Services'),
              Text('• Consultez vos stats dans l\'onglet Statistiques'),
              SizedBox(height: 16),
              Text(
                'Support:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('En cas de problème, contactez le support technique.'),
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

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'évaluation bientôt disponible')),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Cette action va remettre tous les paramètres à leurs valeurs par défaut. '
          'Vos données (clients, RDV) ne seront pas affectées.\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(settingsProvider.notifier).reinitialiserParametres();
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
