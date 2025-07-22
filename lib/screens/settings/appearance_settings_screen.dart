import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart' as theme_provider;
import '../../widgets/settings/settings_tile.dart';
import '../../widgets/settings/theme_selector.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final themeMode = ref.watch(theme_provider.themeProvider);
    final colors = Theme.of(context).colorScheme;

    if (settingsState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (settingsState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Apparence'),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette),
              onPressed: () => _showColorCustomization(context),
              tooltip: 'Personnaliser les couleurs',
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

  Widget _buildContent(BuildContext context, WidgetRef ref, settings) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sélecteur de thème avec preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_6, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Mode d\'affichage',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const ThemeSelector(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Langue
        SettingsSection(
          title: 'Localisation',
          children: [
            SettingsSelector<String>(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Changer la langue de l\'application',
              value: settings.langue,
              options: const ['fr', 'en'],
              labelBuilder: (lang) => lang == 'fr' ? 'Français' : 'English',
              onChanged: (newLang) => ref.read(settingsProvider.notifier).changerLangue(newLang),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Personnalisation avancée
        SettingsSection(
          title: 'Personnalisation',
          children: [
            SettingsNavTile(
              icon: Icons.palette,
              title: 'Couleurs personnalisées',
              subtitle: 'Personnaliser les couleurs de l\'app',
              onTap: () => _showColorCustomization(context),
            ),
            SettingsNavTile(
              icon: Icons.font_download,
              title: 'Taille de police',
              subtitle: 'Ajuster la taille du texte',
              onTap: () => _showFontSizeSettings(context, ref),
            ),
            SettingsToggle(
              icon: Icons.animation,
              title: 'Animations',
              subtitle: 'Activer les animations de l\'interface',
              value: true, // TODO: ajouter au modèle settings
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.vibration,
              title: 'Retour haptique',
              subtitle: 'Vibrations lors des interactions',
              value: true, // TODO: ajouter au modèle settings
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Interface
        SettingsSection(
          title: 'Interface',
          children: [
            SettingsToggle(
              icon: Icons.fullscreen,
              title: 'Mode plein écran',
              subtitle: 'Masquer la barre de statut',
              value: false, // TODO: ajouter au modèle settings
              onChanged: (value) {
                // TODO: implémenter
              },
            ),
            SettingsToggle(
              icon: Icons.grid_view,
              title: 'Vue compacte',
              subtitle: 'Affichage plus dense des listes',
              value: false, // TODO: ajouter au modèle settings
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
              title: 'Réinitialiser l\'apparence',
              subtitle: 'Remettre les paramètres par défaut',
              onTap: () => _confirmResetAppearance(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorCustomization(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ColorCustomizationDialog(),
    );
  }

  void _showFontSizeSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _FontSizeDialog(),
    );
  }

  void _confirmResetAppearance(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser l\'apparence'),
        content: const Text(
          'Êtes-vous sûr de vouloir remettre tous les paramètres '
          'd\'apparence par défaut ? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Remettre thème par défaut
              ref.read(theme_provider.themeProvider.notifier).setTheme(ThemeMode.light);
              // Remettre langue par défaut
              ref.read(settingsProvider.notifier).changerLangue('fr');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Apparence réinitialisée')),
              );
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

class _ColorCustomizationDialog extends StatefulWidget {
  @override
  State<_ColorCustomizationDialog> createState() => _ColorCustomizationDialogState();
}

class _ColorCustomizationDialogState extends State<_ColorCustomizationDialog> {
  Color _selectedColor = const Color(0xFF6750A4);

  static const List<Color> _predefinedColors = [
    Color(0xFF6750A4), // Material Purple
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFD32F2F), // Red
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF303F9F), // Indigo
    Color(0xFF0097A7), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Couleurs personnalisées'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez une couleur principale :'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedColors.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.outline, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cette fonctionnalité sera disponible dans une prochaine version.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
            );
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  double _fontSize = 1.0;

  final Map<double, String> _fontSizeLabels = {
    0.8: 'Petit',
    0.9: 'Petit+',
    1.0: 'Normal',
    1.1: 'Grand',
    1.2: 'Grand+',
    1.3: 'Très grand',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Taille de police'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ajustez la taille du texte :'),
          const SizedBox(height: 16),
          Text(
            'Texte d\'exemple',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * _fontSize,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _fontSize,
            min: 0.8,
            max: 1.3,
            divisions: 5,
            label: _fontSizeLabels[_fontSize],
            onChanged: (value) => setState(() => _fontSize = value),
          ),
          Text(
            _fontSizeLabels[_fontSize] ?? 'Personnalisé',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cette fonctionnalité sera disponible dans une prochaine version.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
            );
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
