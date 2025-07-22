import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/statistics_service.dart';

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final selectedPeriodProvider = StateProvider<StatsPeriod>((ref) {
  return StatsPeriod.month;
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final selectedServiceFilterProvider = StateProvider<int?>((ref) {
  return null;
});

final selectedClientFilterProvider = StateProvider<int?>((ref) {
  return null;
});

final statisticsDataProvider = FutureProvider.autoDispose<StatisticsData>((ref) async {
  final service = ref.watch(statisticsServiceProvider);
  final period = ref.watch(selectedPeriodProvider);
  final date = ref.watch(selectedDateProvider);
  final serviceFilter = ref.watch(selectedServiceFilterProvider);
  final clientFilter = ref.watch(selectedClientFilterProvider);

  // Cache la requête pendant 5 minutes
  ref.keepAlive();
  
  return service.getStatistics(period, customDate: date);
});

final cachedStatisticsProvider = StateNotifierProvider<CachedStatisticsNotifier, Map<String, StatisticsData>>((ref) {
  return CachedStatisticsNotifier();
});

class CachedStatisticsNotifier extends StateNotifier<Map<String, StatisticsData>> {
  CachedStatisticsNotifier() : super({});

  void cacheData(String key, StatisticsData data) {
    state = {...state, key: data};
  }

  StatisticsData? getCachedData(String key) {
    return state[key];
  }

  void clearCache() {
    state = {};
  }

  String generateCacheKey(StatsPeriod period, DateTime date) {
    return '${period.name}_${date.toIso8601String().split('T')[0]}';
  }
}
