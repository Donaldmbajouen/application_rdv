import 'package:flutter/material.dart';

class ServiceStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const ServiceStats({
    super.key,
    required this.stats,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête avec toggle
            InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Statistiques des services',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onToggle != null)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            
            // Statistiques principales (toujours visibles)
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: '${stats['total']}',
                    icon: Icons.room_service,
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Actifs',
                    value: '${stats['actifs']}',
                    icon: Icons.visibility,
                    color: Colors.green,
                  ),
                ),
                if (stats['inactifs'] > 0)
                  Expanded(
                    child: _StatItem(
                      label: 'Inactifs',
                      value: '${stats['inactifs']}',
                      icon: Icons.visibility_off,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),

            // Statistiques détaillées (si développé)
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Prix
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Prix moyen',
                      value: '${stats['prixMoyen'].toStringAsFixed(1)}€',
                      icon: Icons.euro,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Prix min',
                      value: '${stats['prixMin'].toStringAsFixed(0)}€',
                      icon: Icons.arrow_downward,
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Prix max',
                      value: '${stats['prixMax'].toStringAsFixed(0)}€',
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Durée et catégories
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Durée moy.',
                      value: _formatDuration(stats['dureeMoyenne']),
                      icon: Icons.access_time,
                      color: colorScheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Catégories',
                      value: '${stats['categoriesCount']}',
                      icon: Icons.category,
                      color: Colors.purple,
                    ),
                  ),
                  const Expanded(child: SizedBox()), // Placeholder pour l'alignement
                ],
              ),

              // Tags populaires
              if (stats['tagsPopulaires'] != null && 
                  (stats['tagsPopulaires'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tags populaires',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (stats['tagsPopulaires'] as List<Map<String, dynamic>>)
                      .map((tagData) => Chip(
                        label: Text('${tagData['tag']} (${tagData['count']})'),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        labelStyle: theme.textTheme.bodySmall,
                      ))
                      .toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) {
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return '${m}min';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Widget compact pour afficher des stats en en-tête
class ServiceStatsHeader extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ServiceStatsHeader({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CompactStat(
            label: 'Services',
            value: '${stats['total']}',
            color: colorScheme.primary,
          ),
          _CompactStat(
            label: 'Actifs',
            value: '${stats['actifs']}',
            color: Colors.green,
          ),
          _CompactStat(
            label: 'Prix moy.',
            value: '${stats['prixMoyen'].toStringAsFixed(0)}€',
            color: colorScheme.tertiary,
          ),
          _CompactStat(
            label: 'Catégories',
            value: '${stats['categoriesCount']}',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
