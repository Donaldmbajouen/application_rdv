import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

/// Sélecteur de thème avec preview
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thème',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ThemeOption(
                title: 'Clair',
                icon: Icons.light_mode,
                isSelected: currentTheme == ThemeMode.light,
                preview: _buildThemePreview(false),
                onTap: () => themeNotifier.setTheme(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                title: 'Sombre',
                icon: Icons.dark_mode,
                isSelected: currentTheme == ThemeMode.dark,
                preview: _buildThemePreview(true),
                onTap: () => themeNotifier.setTheme(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                title: 'Auto',
                icon: Icons.auto_mode,
                isSelected: currentTheme == ThemeMode.system,
                preview: _buildAutoPreview(),
                onTap: () => themeNotifier.setTheme(ThemeMode.system),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemePreview(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF1C1B1F) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF2B2930) : const Color(0xFFF7F2FA);
    final primaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6750A4);
    final onSurfaceColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // App bar simulée
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: onSurfaceColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Contenu simulé
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  // Card simulée
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 2,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: onSurfaceColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  height: 1.5,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: onSurfaceColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Bouton simulé
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        height: 1.5,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPreview() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(child: _buildThemePreview(false)),
            const SizedBox(width: 1),
            Expanded(child: _buildThemePreview(true)),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Widget preview;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colors.primaryContainer.withOpacity(0.3) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              preview,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? colors.primary : colors.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? colors.primary : colors.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick theme toggle pour la app bar
class QuickThemeToggle extends ConsumerWidget {
  const QuickThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    IconData icon;
    String tooltip;

    switch (currentTheme) {
      case ThemeMode.light:
        icon = Icons.light_mode;
        tooltip = 'Mode clair';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        tooltip = 'Mode sombre';
        break;
      case ThemeMode.system:
        icon = Icons.auto_mode;
        tooltip = 'Mode automatique';
        break;
    }

    return PopupMenuButton<ThemeMode>(
      icon: Icon(icon),
      tooltip: tooltip,
      onSelected: themeNotifier.setTheme,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode),
              SizedBox(width: 8),
              Text('Clair'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode),
              SizedBox(width: 8),
              Text('Sombre'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.auto_mode),
              SizedBox(width: 8),
              Text('Automatique'),
            ],
          ),
        ),
      ],
    );
  }
}
