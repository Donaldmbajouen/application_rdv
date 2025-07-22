import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/service.dart';
import '../models/rendez_vous.dart';
import '../models/app_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'rdv_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table clients
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        telephone TEXT,
        email TEXT,
        notes TEXT,
        tags TEXT,
        dateCreation INTEGER NOT NULL,
        dateModification INTEGER
      )
    ''');

    // Table services
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        dureeMinutes INTEGER NOT NULL,
        prix REAL NOT NULL,
        categorie TEXT,
        tags TEXT,
        actif INTEGER NOT NULL DEFAULT 1,
        dateCreation INTEGER NOT NULL,
        dateModification INTEGER
      )
    ''');

    // Table rendez-vous
    await db.execute('''
      CREATE TABLE rendez_vous (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        serviceId INTEGER NOT NULL,
        dateHeure INTEGER NOT NULL,
        dureeMinutes INTEGER NOT NULL,
        prix REAL NOT NULL,
        statut INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        dateCreation INTEGER NOT NULL,
        dateModification INTEGER,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES services (id) ON DELETE CASCADE
      )
    ''');

    // Table settings
    await db.execute('''
      CREATE TABLE settings (
        cle TEXT PRIMARY KEY,
        valeur TEXT NOT NULL
      )
    ''');

    // Index pour optimiser les requêtes
    await db.execute('CREATE INDEX idx_rdv_date ON rendez_vous (dateHeure)');
    await db.execute('CREATE INDEX idx_rdv_client ON rendez_vous (clientId)');
    await db.execute('CREATE INDEX idx_rdv_service ON rendez_vous (serviceId)');

    // Insérer des données d'exemple
    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures ici
  }

  Future<void> _insertSampleData(Database db) async {
    // Client d'exemple
    await db.insert('clients', {
      'nom': 'Martin',
      'prenom': 'Jean',
      'telephone': '0123456789',
      'email': 'jean.martin@email.com',
      'notes': 'Client régulier',
      'tags': 'Fidèle,VIP',
      'dateCreation': DateTime.now().millisecondsSinceEpoch,
    });

    // Service d'exemple
    await db.insert('services', {
      'nom': 'Coupe classique',
      'description': 'Coupe de cheveux standard',
      'dureeMinutes': 30,
      'prix': 25.0,
      'categorie': 'Coiffure',
      'tags': 'Populaire',
      'actif': 1,
      'dateCreation': DateTime.now().millisecondsSinceEpoch,
    });

    // RDV d'exemple
    final demain = DateTime.now().add(Duration(days: 1));
    final rdvDate = DateTime(demain.year, demain.month, demain.day, 10, 0);
    
    await db.insert('rendez_vous', {
      'clientId': 1,
      'serviceId': 1,
      'dateHeure': rdvDate.millisecondsSinceEpoch,
      'dureeMinutes': 30,
      'prix': 25.0,
      'statut': 0,
      'notes': 'Premier RDV',
      'dateCreation': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Méthodes CRUD pour les clients
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final maps = await db.query('clients', orderBy: 'nom, prenom');
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(int id) async {
    final db = await database;
    final maps = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Client.fromMap(maps.first) : null;
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.copyWith(dateModification: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Méthodes CRUD pour les services
  Future<int> insertService(Service service) async {
    final db = await database;
    return await db.insert('services', service.toMap());
  }

  Future<List<Service>> getServices({bool activeOnly = false}) async {
    final db = await database;
    final where = activeOnly ? 'actif = ?' : null;
    final whereArgs = activeOnly ? [1] : null;
    final maps = await db.query('services', where: where, whereArgs: whereArgs, orderBy: 'nom');
    return maps.map((map) => Service.fromMap(map)).toList();
  }

  Future<Service?> getService(int id) async {
    final db = await database;
    final maps = await db.query('services', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Service.fromMap(maps.first) : null;
  }

  Future<int> updateService(Service service) async {
    final db = await database;
    return await db.update(
      'services',
      service.copyWith(dateModification: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // Méthodes CRUD pour les rendez-vous
  Future<int> insertRendezVous(RendezVous rdv) async {
    final db = await database;
    return await db.insert('rendez_vous', rdv.toMap());
  }

  Future<List<RendezVous>> getRendezVous({DateTime? date, int? clientId}) async {
    final db = await database;
    String sql = '''
      SELECT 
        r.*,
        c.nom as clientNom,
        c.prenom as clientPrenom,
        s.nom as serviceNom
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      JOIN services s ON r.serviceId = s.id
    ''';
    
    List<String> conditions = [];
    List<dynamic> args = [];

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      conditions.add('r.dateHeure >= ? AND r.dateHeure < ?');
      args.addAll([startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);
    }

    if (clientId != null) {
      conditions.add('r.clientId = ?');
      args.add(clientId);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    sql += ' ORDER BY r.dateHeure';

    final maps = await db.rawQuery(sql, args);
    return maps.map((map) => RendezVous.fromMap(map)).toList();
  }

  Future<RendezVous?> getRendezVousById(int id) async {
    final db = await database;
    final sql = '''
      SELECT 
        r.*,
        c.nom as clientNom,
        c.prenom as clientPrenom,
        s.nom as serviceNom
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      JOIN services s ON r.serviceId = s.id
      WHERE r.id = ?
    ''';
    
    final maps = await db.rawQuery(sql, [id]);
    return maps.isNotEmpty ? RendezVous.fromMap(maps.first) : null;
  }

  Future<int> updateRendezVous(RendezVous rdv) async {
    final db = await database;
    return await db.update(
      'rendez_vous',
      rdv.copyWith(dateModification: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [rdv.id],
    );
  }

  Future<int> deleteRendezVous(int id) async {
    final db = await database;
    return await db.delete('rendez_vous', where: 'id = ?', whereArgs: [id]);
  }

  // Vérification des conflits
  Future<List<RendezVous>> getConflits(DateTime dateHeure, int dureeMinutes, {int? excludeId}) async {
    final db = await database;
    final debut = dateHeure.millisecondsSinceEpoch;
    final fin = dateHeure.add(Duration(minutes: dureeMinutes)).millisecondsSinceEpoch;
    
    String sql = '''
      SELECT 
        r.*,
        c.nom as clientNom,
        c.prenom as clientPrenom,
        s.nom as serviceNom
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      JOIN services s ON r.serviceId = s.id
      WHERE r.statut != 1 -- pas annulé
      AND (
        (r.dateHeure < ? AND (r.dateHeure + r.dureeMinutes * 60000) > ?)
        OR
        (r.dateHeure < ? AND (r.dateHeure + r.dureeMinutes * 60000) > ?)
      )
    ''';
    
    List<dynamic> args = [fin, debut, fin, debut];
    
    if (excludeId != null) {
      sql += ' AND r.id != ?';
      args.add(excludeId);
    }

    final maps = await db.rawQuery(sql, args);
    return maps.map((map) => RendezVous.fromMap(map)).toList();
  }

  // Statistiques détaillées pour les graphiques
  Future<List<Map<String, dynamic>>> getRevenuesByPeriod(DateTime debut, DateTime fin, String groupFormat) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        strftime('$groupFormat', datetime(dateHeure/1000, 'unixepoch')) as periode,
        COALESCE(SUM(prix), 0) as revenus,
        COUNT(*) as nombreRdv,
        MIN(dateHeure) as firstDate
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
      GROUP BY strftime('$groupFormat', datetime(dateHeure/1000, 'unixepoch'))
      ORDER BY periode
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);
  }

  Future<List<Map<String, dynamic>>> getServiceStatistics(DateTime debut, DateTime fin) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        s.nom as serviceName,
        s.id as serviceId,
        COUNT(*) as count,
        COALESCE(SUM(r.prix), 0) as totalRevenue,
        COALESCE(AVG(r.prix), 0) as avgPrice
      FROM rendez_vous r
      JOIN services s ON r.serviceId = s.id
      WHERE r.dateHeure >= ? AND r.dateHeure < ? AND r.statut != 1
      GROUP BY r.serviceId, s.nom
      ORDER BY totalRevenue DESC
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);
  }

  Future<List<Map<String, dynamic>>> getOccupancyByHour(DateTime debut, DateTime fin) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        strftime('%H', datetime(dateHeure/1000, 'unixepoch')) as hour,
        COUNT(*) as appointmentCount,
        COALESCE(SUM(dureeMinutes), 0) as totalMinutes
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ? AND statut != 1
      GROUP BY strftime('%H', datetime(dateHeure/1000, 'unixepoch'))
      ORDER BY hour
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);
  }

  Future<List<Map<String, dynamic>>> getTopClientsDetailed(DateTime debut, DateTime fin, {int limit = 10}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.id as clientId,
        c.nom || ' ' || c.prenom as clientName,
        COUNT(*) as appointmentCount,
        COALESCE(SUM(r.prix), 0) as totalSpent,
        COALESCE(AVG(r.prix), 0) as avgSpent,
        MIN(r.dateHeure) as firstVisit,
        MAX(r.dateHeure) as lastVisit
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      WHERE r.dateHeure >= ? AND r.dateHeure < ? AND r.statut != 1
      GROUP BY r.clientId, c.nom, c.prenom
      ORDER BY totalSpent DESC
      LIMIT ?
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch, limit]);
  }

  // Statistiques globales (pour compatibilité)
  Future<Map<String, dynamic>> getStatistiques(DateTime debut, DateTime fin) async {
    final db = await database;
    
    final revenus = await db.rawQuery('''
      SELECT COALESCE(SUM(prix), 0) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ?
      AND statut != 1
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);

    final nombreRdv = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ?
      AND statut != 1
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);

    final nombreClients = await db.rawQuery('''
      SELECT COUNT(DISTINCT clientId) as total
      FROM rendez_vous
      WHERE dateHeure >= ? AND dateHeure < ?
      AND statut != 1
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);

    final topClients = await db.rawQuery('''
      SELECT 
        c.nom,
        c.prenom,
        COUNT(*) as nombreRdv,
        SUM(r.prix) as totalDepense
      FROM rendez_vous r
      JOIN clients c ON r.clientId = c.id
      WHERE r.dateHeure >= ? AND r.dateHeure < ?
      AND r.statut != 1
      GROUP BY r.clientId
      ORDER BY nombreRdv DESC
      LIMIT 5
    ''', [debut.millisecondsSinceEpoch, fin.millisecondsSinceEpoch]);

    return {
      'revenus': (revenus.first['total'] as num).toDouble(),
      'nombreRdv': nombreRdv.first['total'] as int,
      'nombreClients': nombreClients.first['total'] as int,
      'topClients': topClients,
    };
  }

  // Settings
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'cle': key, 'valeur': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'cle = ?', whereArgs: [key]);
    return maps.isNotEmpty ? maps.first['valeur'] as String : null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
