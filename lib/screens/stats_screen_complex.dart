import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../services/statistics_service.dart';
import '../providers/statistics_provider.dart';
import '../widgets/statistics/stat_card.dart';
import '../widgets/statistics/period_selector.dart';
import '../widgets/statistics/revenue_chart.dart';
import '../widgets/statistics/service_distribution_chart.dart';
import '../widgets/statistics/trend_chart.dart';
import '../widgets/statistics/top_clients_widget.dart';
import '../widgets/statistics/occupancy_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statisticsAsync = ref.watch(statisticsDataProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            onPressed: () => _showFilters(context, ref),
            icon: const Icon(LineIcons.filter),
            tooltip: 'Filtres',
          ),
          IconButton(
            onPressed: () => _exportData(context, ref),
            icon: const Icon(LineIcons.share),
            tooltip: 'Exporter',
          ),
          IconButton(
            onPressed: () => ref.refresh(statisticsDataProvider),
            icon: const Icon(LineIcons.syncIcon),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsDataProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de période
              const PeriodSelector(),
              const SizedBox(height: 16),

              // Données statistiques
              statisticsAsync.when(
                data: (statistics) => Column(
                  children: [
                    // KPI Cards
                    _buildKPICards(statistics, theme),
                    const SizedBox(height: 24),

                    // Graphiques principaux
                    _buildMainCharts(statistics, selectedPeriod, theme),
                    const SizedBox(height: 24),

                    // Graphiques secondaires
                    _buildSecondaryCharts(statistics, theme),
                    const SizedBox(height: 24),

                    // Top clients
                    TopClientsWidget(
                      data: statistics.topClients,
                      onViewAll: () => _showAllClients(context, statistics.topClients),
                    ),
                  ],
                ),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(StatisticsData statistics, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          title: 'Revenus',
          value: '${statistics.revenue.toStringAsFixed(0)}€',
          icon: LineIcons.euroSign,
          color: Colors.green,
          growthPercentage: statistics.comparison?.revenueGrowth,
          subtitle: 'Total période',
        ),
        StatCard(
          title: 'Rendez-vous',
          value: '${statistics.totalAppointments}',
          icon: LineIcons.calendar,
          color: Colors.blue,
          growthPercentage: statistics.comparison?.appointmentGrowth,
          subtitle: 'Total confirmés',
        ),
        StatCard(
          title: 'Clients',
          value: '${statistics.totalClients}',
          icon: LineIcons.users,
          color: Colors.orange,
          growthPercentage: statistics.comparison?.clientGrowth,
          subtitle: 'Clients uniques',
        ),
        StatCard(
          title: 'Occupation',
          value: '${statistics.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.pie_chart,
          color: Colors.purple,
          subtitle: 'Taux moyen',
        ),
      ],
    );
  }

  Widget _buildMainCharts(StatisticsData statistics, StatsPeriod period, ThemeData theme) {
    return Column(
      children: [
        // Graphique des revenus
        RevenueChart(
          data: statistics.revenueByPeriod,
          period: period,
          primaryColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),

        // Répartition par service
        ServiceDistributionChart(
          data: statistics.serviceDistribution,
          primaryColor: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildSecondaryCharts(StatisticsData statistics, ThemeData theme) {
    return Column(
      children: [
        // Évolution des RDV
        TrendChart(
          data: statistics.appointmentTrend,
          period: StatsPeriod.month, // Utiliser la période sélectionnée
          title: 'Évolution des rendez-vous',
          primaryColor: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 16),

        // Occupation par heure
        OccupancyChart(
          data: statistics.occupancyByHour,
          primaryColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // KPI Cards skeleton
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(4, (index) => const StatCardSkeleton()),
        ),
        const SizedBox(height: 24),

        // Charts skeleton
        ...List.generate(4, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LineIcons.exclamationTriangle,
              size: 48,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur lors du chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(statisticsDataProvider),
              icon: const Icon(LineIcons.syncIcon),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LineIcons.cog),
              title: const Text('Filtrer par service'),
              subtitle: const Text('Sélectionner un service spécifique'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter filtre par service
              },
            ),
            ListTile(
              leading: const Icon(LineIcons.user),
              title: const Text('Filtrer par client'),
              subtitle: const Text('Sélectionner un client spécifique'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter filtre par client
              },
            ),
            ListTile(
              leading: const Icon(LineIcons.eraser),
              title: const Text('Réinitialiser les filtres'),
              onTap: () {
                ref.read(selectedServiceFilterProvider.notifier).state = null;
                ref.read(selectedClientFilterProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.read(statisticsDataProvider);
    
    statisticsAsync.whenData((statistics) {
      final csvData = _generateCSV(statistics);
      Share.share(csvData, subject: 'Statistiques - Données');
    });

    // Afficher un snackbar pour confirmer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données exportées'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAllClients(BuildContext context, List<TopClientData> clients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Tous les clients (${clients.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: clients.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('#${index + 1}'),
                      ),
                      title: Text(client.clientName),
                      subtitle: Text('${client.appointmentCount} RDV'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${client.totalSpent.toStringAsFixed(0)}€',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Moy: ${client.avgSpent.toStringAsFixed(0)}€',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateCSV(StatisticsData statistics) {
    final buffer = StringBuffer();
    buffer.writeln('Type,Valeur,Description');
    buffer.writeln('Revenus,${statistics.revenue},"Total des revenus"');
    buffer.writeln('RDV,${statistics.totalAppointments},"Nombre de rendez-vous"');
    buffer.writeln('Clients,${statistics.totalClients},"Nombre de clients uniques"');
    buffer.writeln('Occupation,${statistics.occupancyRate},"Taux d\'occupation (%)"');
    
    buffer.writeln('\nTop Clients:');
    buffer.writeln('Nom,RDV,Total,Moyenne');
    for (final client in statistics.topClients) {
      buffer.writeln('${client.clientName},${client.appointmentCount},${client.totalSpent},${client.avgSpent}');
    }
    
    return buffer.toString();
  }
}
