import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

/// Provider pour l'instance de base de données
/// 
/// Usage:
/// ```dart
/// final db = ref.watch(databaseProvider);
/// final clients = await db.getClients();
/// ```
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Provider pour initialiser la base de données
/// 
/// Usage:
/// ```dart
/// ref.watch(databaseInitProvider).when(
///   data: (_) => Text('Base initialisée'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Erreur: $err'),
/// );
/// ```
final databaseInitProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.database; // Force l'initialisation
  return true;
});
