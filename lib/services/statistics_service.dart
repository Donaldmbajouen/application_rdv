import '../database/database_helper.dart';
import '../models/rendez_vous.dart';

enum StatsPeriod { day, week, month, year }

class StatisticsData {
  final double revenue;
  final int totalAppointments;
  final int totalClients;
  final double occupancyRate;
  final List<RevenueDataPoint> revenueByPeriod;
  final List<ServiceDistribution> serviceDistribution;
  final List<TrendDataPoint> appointmentTrend;
  final List<TopClientData> topClients;
  final List<OccupancyData> occupancyByHour;
  final StatisticsComparison? comparison;

  StatisticsData({
    required this.revenue,
    required this.totalAppointments,
    required this.totalClients,
    required this.occupancyRate,
    required this.revenueByPeriod,
    required this.serviceDistribution,
    required this.appointmentTrend,
    required this.topClients,
    required this.occupancyByHour,
    this.comparison,
  });
}

class RevenueDataPoint {
  final String label;
  final double value;
  final DateTime date;

  RevenueDataPoint({required this.label, required this.value, required this.date});
}

class ServiceDistribution {
  final String serviceName;
  final double value;
  final int count;

  ServiceDistribution({required this.serviceName, required this.value, required this.count});
}

class TrendDataPoint {
  final DateTime date;
  final double value;

  TrendDataPoint({required this.date, required this.value});
}

class TopClientData {
  final String clientName;
  final int appointmentCount;
  final double totalSpent;
  final double avgSpent;

  TopClientData({
    required this.clientName,
    required this.appointmentCount,
    required this.totalSpent,
    required this.avgSpent,
  });
}

class OccupancyData {
  final int hour;
  final int appointmentCount;
  final double occupancyRate;

  OccupancyData({required this.hour, required this.appointmentCount, required this.occupancyRate});
}

class StatisticsComparison {
  final double revenueGrowth;
  final double appointmentGrowth;
  final double clientGrowth;

  StatisticsComparison({
    required this.revenueGrowth,
    required this.appointmentGrowth,
    required this.clientGrowth,
  });
}

class StatisticsService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<StatisticsData> getStatistics(StatsPeriod period, {DateTime? customDate}) async {
    final now = customDate ?? DateTime.now();
    final dateRange = _getDateRange(period, now);
    final previousDateRange = _getPreviousDateRange(period, dateRange.start);

    // Récupérer les données principales
    final results = await Future.wait([
      _getBasicStats(dateRange.start, dateRange.end),
      _getBasicStats(previousDateRange.start, previousDateRange.end),
      _getRevenueByPeriod(period, dateRange.start, dateRange.end),
      _getServiceDistribution(dateRange.start, dateRange.end),
      _getAppointmentTrend(period, dateRange.start, dateRange.end),
      _getTopClients(dateRange.start, dateRange.end),
      _getOccupancyByHour(dateRange.start, dateRange.end),
    ]);

    final currentStats = results[0] as Map<String, dynamic>;
    final previousStats = results[1] as Map<String, dynamic>;
    final revenueByPeriod = results[2] as List<RevenueDataPoint>;
    final serviceDistribution = results[3] as List<ServiceDistribution>;
    final appointmentTrend = results[4] as List<TrendDataPoint>;
    final topClients = results[5] as List<TopClientData>;
    final occupancyByHour = results[6] as List<OccupancyData>;

    final comparison = StatisticsComparison(
      revenueGrowth: _calculateGrowth(currentStats['revenus'] as double, previousStats['revenus'] as double),
      appointmentGrowth: _calculateGrowth((currentStats['nombreRdv'] as int).toDouble(), (previousStats['nombreRdv'] as int).toDouble()),
      clientGrowth: _calculateGrowth((currentStats['nombreClients'] as int).toDouble(), (previousStats['nombreClients'] as int).toDouble()),
    );

    return StatisticsData(
      revenue: currentStats['revenus'] as double,
      totalAppointments: currentStats['nombreRdv'] as int,
      totalClients: currentStats['nombreClients'] as int,
      occupancyRate: currentStats['tauxOccupation'] as double,
      revenueByPeriod: revenueByPeriod,
      serviceDistribution: serviceDistribution,
      appointmentTrend: appointmentTrend,
      topClients: topClients,
      occupancyByHour: occupancyByHour,
      comparison: comparison,
    );
  }

  DateTimeRange _getDateRange(StatsPeriod period, DateTime date) {
    switch (period) {
      case StatsPeriod.day:
        final start = DateTime(date.year, date.month, date.day);
        return DateTimeRange(start: start, end: start.add(Duration(days: 1)));
      case StatsPeriod.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day);
        return DateTimeRange(start: weekStart, end: weekStart.add(Duration(days: 7)));
      case StatsPeriod.month:
        final start = DateTime(date.year, date.month, 1);
        return DateTimeRange(start: start, end: DateTime(date.year, date.month + 1, 1));
      case StatsPeriod.year:
        final start = DateTime(date.year, 1, 1);
        return DateTimeRange(start: start, end: DateTime(date.year + 1, 1, 1));
    }
  }

  DateTimeRange _getPreviousDateRange(StatsPeriod period, DateTime currentStart) {
    switch (period) {
      case StatsPeriod.day:
        final start = currentStart.subtract(Duration(days: 1));
        return DateTimeRange(start: start, end: start.add(Duration(days: 1)));
      case StatsPeriod.week:
        final start = currentStart.subtract(Duration(days: 7));
        return DateTimeRange(start: start, end: start.add(Duration(days: 7)));
      case StatsPeriod.month:
        final start = DateTime(currentStart.year, currentStart.month - 1, 1);
        return DateTimeRange(start: start, end: DateTime(currentStart.year, currentStart.month, 1));
      case StatsPeriod.year:
        final start = DateTime(currentStart.year - 1, 1, 1);
        return DateTimeRange(start: start, end: DateTime(currentStart.year, 1, 1));
    }
  }

  Future<Map<String, dynamic>> _getBasicStats(DateTime start, DateTime end) async {
    final db = await _db.database;
    
    final revenus = await db.rawQuery('''
      SELECT COALESCE(SUM(prix), 0) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    final nombreRdv = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    final nombreClients = await db.rawQuery('''
      SELECT COUNT(DISTINCT clientId) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    // Calcul taux d'occupation simplifié (8h-18h = 10h par jour)
    final joursTravailles = end.difference(start).inDays;
    final heuresDisponibles = joursTravailles * 10 * 60; // 10h en minutes
    final minutesOccupees = await db.rawQuery('''
      SELECT COALESCE(SUM(dureeMinutes), 0) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    final tauxOccupation = heuresDisponibles > 0 
        ? ((minutesOccupees.first['total'] as num) / heuresDisponibles * 100)
        : 0.0;

    return {
      'revenus': (revenus.first['total'] as num).toDouble(),
      'nombreRdv': nombreRdv.first['total'] as int,
      'nombreClients': nombreClients.first['total'] as int,
      'tauxOccupation': tauxOccupation.toDouble(),
    };
  }

  Future<List<RevenueDataPoint>> _getRevenueByPeriod(StatsPeriod period, DateTime start, DateTime end) async {
    final db = await _db.database;
    String dateFormat;
    String groupBy;

    switch (period) {
      case StatsPeriod.day:
        dateFormat = "%H";
        groupBy = "strftime('%H', datetime(dateHeure/1000, 'unixepoch'))";
        break;
      case StatsPeriod.week:
        dateFormat = "%w";
        groupBy = "strftime('%w', datetime(dateHeure/1000, 'unixepoch'))";
        break;
      case StatsPeriod.month:
        dateFormat = "%d";
        groupBy = "strftime('%d', datetime(dateHeure/1000, 'unixepoch'))";
        break;
      case StatsPeriod.year:
        dateFormat = "%m";
        groupBy = "strftime('%m', datetime(dateHeure/1000, 'unixepoch'))";
        break;
    }

    final result = await db.rawQuery('''
      SELECT 
        $groupBy as periode,
        COALESCE(SUM(prix), 0) as revenus,
        dateHeure
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
      GROUP BY $groupBy
      ORDER BY periode
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    return result.map((row) {
      final periode = row['periode'] as String;
      final revenus = (row['revenus'] as num).toDouble();
      final dateTime = DateTime.fromMillisecondsSinceEpoch(row['dateHeure'] as int);
      
      return RevenueDataPoint(
        label: _formatPeriodLabel(period, periode),
        value: revenus,
        date: dateTime,
      );
    }).toList();
  }

  Future<List<ServiceDistribution>> _getServiceDistribution(DateTime start, DateTime end) async {
    final db = await _db.database;
    
    final result = await db.rawQuery('''
      SELECT 
        s.nom as serviceName,
        COUNT(*) as count,
        COALESCE(SUM(r.prix), 0) as totalRevenue
      FROM rendez_vous r
      JOIN services s ON r.serviceId = s.id
      WHERE r.dateHeure >= ? AND r.dateHeure < ? AND r.statut != 1
      GROUP BY r.serviceId, s.nom
      ORDER BY totalRevenue DESC
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    return result.map((row) => ServiceDistribution(
      serviceName: row['serviceName'] as String,
      value: (row['totalRevenue'] as num).toDouble(),
      count: row['count'] as int,
    )).toList();
  }

  Future<List<TrendDataPoint>> _getAppointmentTrend(StatsPeriod period, DateTime start, DateTime end) async {
    final db = await _db.database;
    String dateFormat;
    Duration interval;

    switch (period) {
      case StatsPeriod.day:
        dateFormat = "%H";
        interval = Duration(hours: 1);
        break;
      case StatsPeriod.week:
        dateFormat = "%Y-%m-%d";
        interval = Duration(days: 1);
        break;
      case StatsPeriod.month:
        dateFormat = "%Y-%m-%d";
        interval = Duration(days: 1);
        break;
      case StatsPeriod.year:
        dateFormat = "%Y-%m";
        interval = Duration(days: 30);
        break;
    }

    final result = await db.rawQuery('''
      SELECT 
        strftime('$dateFormat', datetime(dateHeure/1000, 'unixepoch')) as periode,
        COUNT(*) as count,
        MIN(dateHeure) as firstDate
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
      GROUP BY strftime('$dateFormat', datetime(dateHeure/1000, 'unixepoch'))
      ORDER BY periode
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    return result.map((row) {
      final count = (row['count'] as int).toDouble();
      final firstDate = DateTime.fromMillisecondsSinceEpoch(row['firstDate'] as int);
      
      return TrendDataPoint(date: firstDate, value: count);
    }).toList();
  }

  Future<List<TopClientData>> _getTopClients(DateTime start, DateTime end) async {
    final db = await _db.database;
    
    final result = await db.rawQuery('''
      SELECT 
        c.nom || ' ' || c.prenom as clientName,
        COUNT(*) as appointmentCount,
        COALESCE(SUM(r.prix), 0) as totalSpent
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      WHERE r.dateHeure >= ? AND r.dateHeure < ? AND r.statut != 1
      GROUP BY r.clientId, c.nom, c.prenom
      ORDER BY totalSpent DESC
      LIMIT 10
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    return result.map((row) {
      final appointmentCount = row['appointmentCount'] as int;
      final totalSpent = (row['totalSpent'] as num).toDouble();
      
      return TopClientData(
        clientName: row['clientName'] as String,
        appointmentCount: appointmentCount,
        totalSpent: totalSpent,
        avgSpent: appointmentCount > 0 ? totalSpent / appointmentCount : 0,
      );
    }).toList();
  }

  Future<List<OccupancyData>> _getOccupancyByHour(DateTime start, DateTime end) async {
    final db = await _db.database;
    
    final result = await db.rawQuery('''
      SELECT 
        strftime('%H', datetime(dateHeure/1000, 'unixepoch')) as hour,
        COUNT(*) as appointmentCount
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
      GROUP BY strftime('%H', datetime(dateHeure/1000, 'unixepoch'))
      ORDER BY hour
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    final maxCount = result.isNotEmpty 
        ? result.map((r) => r['appointmentCount'] as int).reduce((a, b) => a > b ? a : b)
        : 1;

    return result.map((row) {
      final hour = int.parse(row['hour'] as String);
      final appointmentCount = row['appointmentCount'] as int;
      final occupancyRate = (appointmentCount / maxCount * 100);
      
      return OccupancyData(
        hour: hour,
        appointmentCount: appointmentCount,
        occupancyRate: occupancyRate,
      );
    }).toList();
  }

  String _formatPeriodLabel(StatsPeriod period, String value) {
    switch (period) {
      case StatsPeriod.day:
        return "${value}h";
      case StatsPeriod.week:
        final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        final index = int.tryParse(value) ?? 0;
        return days[index];
      case StatsPeriod.month:
        return value;
      case StatsPeriod.year:
        final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                       'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
        final index = (int.tryParse(value) ?? 1) - 1;
        return months[index];
    }
  }

  double _calculateGrowth(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
