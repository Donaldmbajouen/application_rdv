import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/rendez_vous.dart';
import '../providers/rendez_vous_provider.dart';
import '../providers/client_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/calendar/custom_calendar.dart';
import '../widgets/calendar/rdv_card.dart';
import '../widgets/calendar/rdv_form.dart';
import '../widgets/calendar/rdv_filters.dart';


class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les données initiales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rendezVousProvider.notifier).loadRendezVous();
      ref.read(clientProvider.notifier).loadClients();
      ref.read(serviceProvider.notifier).loadServices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rdvState = ref.watch(rendezVousProvider);
    
    return Scaffold(
      appBar: _buildAppBar(theme, rdvState),
      body: rdvState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Onglets pour les vues
                _buildTabBar(theme),
                
                // Contenu selon l'onglet sélectionné
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMonthView(),
                      _buildWeekView(),
                      _buildDayView(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar(ThemeData theme, RendezVousState rdvState) {
    String title;
    switch (_tabController.index) {
      case 0:
        title = DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay);
        break;
      case 1:
        final startOfWeek = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        title = '${DateFormat('dd/MM', 'fr_FR').format(startOfWeek)} - ${DateFormat('dd/MM', 'fr_FR').format(endOfWeek)}';
        break;
      case 2:
        title = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDay);
        break;
      default:
        title = 'Calendrier';
    }
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (rdvState.filteredRendezVous.isNotEmpty)
            Text(
              '${rdvState.filteredRendezVous.length} RDV',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        // Filtres
        if (rdvState.dateFiltre != null || 
            rdvState.clientFiltre != null || 
            rdvState.statutFiltre != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showFilters,
              icon: Badge(
                backgroundColor: theme.colorScheme.error,
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filtres actifs',
            ),
          )
        else
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtres',
          ),
        
        // Actions selon la vue
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'today',
              child: Row(
                children: [
                  Icon(Icons.today),
                  SizedBox(width: 8),
                  Text('Aujourd\'hui'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualiser'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text('Statistiques'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        tabs: const [
          Tab(
            icon: Icon(Icons.calendar_month),
            text: 'Mois',
          ),
          Tab(
            icon: Icon(Icons.view_week),
            text: 'Semaine',
          ),
          Tab(
            icon: Icon(Icons.today),
            text: 'Jour',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        // Calendrier
        CustomCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          calendarFormat: _calendarFormat,
          onDaySelected: _onDaySelected,
          onPageChanged: _onPageChanged,
          onFormatChanged: _onFormatChanged,
        ),
        
        // Liste des RDV du jour sélectionné
        Expanded(
          child: _buildSelectedDayAppointments(),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return Column(
      children: [
        // Navigation semaine
        _buildWeekNavigation(),
        
        // Vue semaine
        Expanded(
          child: _buildWeekGrid(),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    return Column(
      children: [
        // Navigation jour
        _buildDayNavigation(),
        
        // Vue jour
        Expanded(
          child: _buildDaySchedule(),
        ),
      ],
    );
  }

  Widget _buildSelectedDayAppointments() {
    final rdvsJour = ref.watch(rendezVousByDateProvider(_selectedDay));
    final filteredRdvs = _applyFilters(rdvsJour);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredRdvs.length} RDV',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredRdvs.isEmpty
                ? _buildEmptyDayState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredRdvs.length,
                    itemBuilder: (context, index) {
                      final rdv = filteredRdvs[index];
                      return RdvCard(
                        rdv: rdv,
                        onTap: () => _showRdvDetails(rdv),
                        onEdit: () => _editRdv(rdv),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final theme = Theme.of(context);
    final startOfWeek = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              'Semaine du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(startOfWeek)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigateWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNavigation() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateDay(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDay),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigateDay(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid() {
    // Simplified week view - showing days with appointment counts
    final startOfWeek = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = startOfWeek.add(Duration(days: index));
        final rdvsJour = ref.watch(rendezVousByDateProvider(day));
        final isToday = isSameDay(day, DateTime.now());
        final isSelected = isSameDay(day, _selectedDay);
        
        return _buildWeekDayCard(day, rdvsJour, isToday, isSelected);
      },
    );
  }

  Widget _buildWeekDayCard(DateTime day, List<RendezVous> rdvs, bool isToday, bool isSelected) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => _onDaySelected(day, day),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer
              : isToday 
                  ? theme.colorScheme.secondaryContainer 
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              DateFormat('E', 'fr_FR').format(day),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? theme.colorScheme.onPrimaryContainer
                    : isToday 
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (rdvs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rdvs.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule() {
    final rdvsJour = ref.watch(rendezVousByDateProvider(_selectedDay));
    final filteredRdvs = _applyFilters(rdvsJour);
    
    if (filteredRdvs.isEmpty) {
      return _buildEmptyDayState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredRdvs.length,
      itemBuilder: (context, index) {
        final rdv = filteredRdvs[index];
        return RdvCard(
          rdv: rdv,
          onTap: () => _showRdvDetails(rdv),
          onEdit: () => _editRdv(rdv),
        );
      },
    );
  }

  Widget _buildEmptyDayState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun rendez-vous',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour ajouter un rendez-vous',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _addNewRdv,
      tooltip: 'Nouveau rendez-vous',
      child: const Icon(Icons.add),
    );
  }

  List<RendezVous> _applyFilters(List<RendezVous> rdvs) {
    final rdvState = ref.read(rendezVousProvider);
    
    return rdvs.where((rdv) {
      // Filtre par statut
      if (rdvState.statutFiltre != null && rdv.statut != rdvState.statutFiltre) {
        return false;
      }
      
      // Filtre par client
      if (rdvState.clientFiltre != null && rdv.clientId != rdvState.clientFiltre) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _navigateWeek(int weeks) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: 7 * weeks));
      _focusedDay = _selectedDay;
    });
  }

  void _navigateDay(int days) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: days));
      _focusedDay = _selectedDay;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'today':
        setState(() {
          _selectedDay = DateTime.now();
          _focusedDay = DateTime.now();
        });
        break;
      case 'refresh':
        ref.read(rendezVousProvider.notifier).loadRendezVous();
        break;
      case 'stats':
        _showStats();
        break;
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => const RdvFilters(),
    );
  }

  void _showStats() {
    final stats = ref.read(rendezVousStatsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total RDV: ${stats['total']}'),
            Text('Confirmés: ${stats['confirmes']}'),
            Text('En attente: ${stats['enAttente']}'),
            Text('Complétés: ${stats['completes']}'),
            Text('Annulés: ${stats['annules']}'),
            const SizedBox(height: 8),
            Text('Aujourd\'hui: ${stats['aujourdhui']}'),
            Text('Cette semaine: ${stats['semaine']}'),
            const SizedBox(height: 8),
            Text('Revenu total: ${stats['revenuTotal'].toStringAsFixed(2)}€'),
            Text('Revenu moyen: ${stats['revenuMoyen'].toStringAsFixed(2)}€'),
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

  void _addNewRdv() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RdvForm(
          dateInitiale: _selectedDay,
          heureInitiale: TimeOfDay.now(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(rendezVousProvider.notifier).loadRendezVous();
      }
    });
  }

  void _editRdv(RendezVous rdv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RdvForm(rdv: rdv),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(rendezVousProvider.notifier).loadRendezVous();
      }
    });
  }

  void _showRdvDetails(RendezVous rdv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => _buildRdvDetails(rdv),
    );
  }

  Widget _buildRdvDetails(RendezVous rdv) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Détails du rendez-vous',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          RdvCard(
            rdv: rdv,
            onEdit: () {
              Navigator.of(context).pop();
              _editRdv(rdv);
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _editRdv(rdv);
                  },
                  child: const Text('Modifier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
