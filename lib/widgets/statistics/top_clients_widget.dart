import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/statistics_service.dart';

class TopClientsWidget extends StatelessWidget {
  final List<TopClientData> data;
  final VoidCallback? onViewAll;

  const TopClientsWidget({
    super.key,
    required this.data,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Top clients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton.icon(
                    onPressed: onViewAll,
                    icon: Icon(LineIcons.arrowRight, size: 16),
                    label: const Text('Voir tout'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = data[index];
                final rank = index + 1;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildRankBadge(rank, colorScheme),
                  title: Text(
                    client.clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        LineIcons.calendar,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${client.appointmentCount} RDV',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LineIcons.coins,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Moy: ${client.avgSpent.toStringAsFixed(0)}€',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${client.totalSpent.toStringAsFixed(0)}€',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _getProgressValue(client.totalSpent),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getRankColor(rank, colorScheme),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (data.length > 3) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total clients',
                      '${data.length}',
                      LineIcons.users,
                      theme,
                    ),
                    _buildSummaryItem(
                      'Total revenus',
                      '${_getTotalRevenue().toStringAsFixed(0)}€',
                      LineIcons.euroSign,
                      theme,
                    ),
                    _buildSummaryItem(
                      'Moy par client',
                      '${_getAverageRevenue().toStringAsFixed(0)}€',
                      Icons.trending_up,
                      theme,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LineIcons.users,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun client',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les meilleurs clients apparaîtront ici',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, ColorScheme colorScheme) {
    Color badgeColor;
    IconData icon;
    
    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        icon = LineIcons.crown;
        break;
      case 2:
        badgeColor = Colors.grey.shade400;
        icon = LineIcons.medal;
        break;
      case 3:
        badgeColor = Colors.brown.shade300;
        icon = LineIcons.medal;
        break;
      default:
        badgeColor = colorScheme.primary;
        icon = LineIcons.user;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: rank <= 3
            ? Icon(
                icon,
                color: badgeColor,
                size: 18,
              )
            : Text(
                '#$rank',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
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

  Color _getRankColor(int rank, ColorScheme colorScheme) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return colorScheme.primary;
    }
  }

  double _getProgressValue(double revenue) {
    if (data.isEmpty) return 0;
    final maxRevenue = data.map((e) => e.totalSpent).reduce((a, b) => a > b ? a : b);
    return maxRevenue > 0 ? revenue / maxRevenue : 0;
  }

  double _getTotalRevenue() {
    return data.fold(0.0, (sum, client) => sum + client.totalSpent);
  }

  double _getAverageRevenue() {
    if (data.isEmpty) return 0;
    return _getTotalRevenue() / data.length;
  }
}
