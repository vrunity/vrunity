import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  /// Get or initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inspection.db');

    return openDatabase(
      path,
      version: 2, // Increment version for schema updates
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  /// Retrieve data by serial number
  Future<Map<String, dynamic>?> getDetailsBySerial(String serialNumber) async {
    final db = await database;
    print("Querying database for serial number: $serialNumber");

    final result = await db.query(
      'offline_data',
      where: 'serial_no = ?',
      whereArgs: [serialNumber],
    );

    if (result.isNotEmpty) {
      final data = result.first;
      print("Data found for serial number: $serialNumber -> $data");
      return data; // Return the first match
    } else {
      print("No data found for serial number: $serialNumber");
      return null; // No data found
    }
  }
  /// Create tables when the database is created
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE offline_data (
      tag_number TEXT PRIMARY KEY,
      type TEXT,
      capacity REAL,
      checkin_checkout INTEGER,
      company_name TEXT,
      site_name TEXT,
      site_location TEXT,
      serial_no TEXT,
      year_of_mfg TEXT,
      remarks TEXT
    )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Example: Adding a new column if needed
      // await db.execute('ALTER TABLE offline_data ADD COLUMN new_column TEXT');
    }
  }

  /// Insert data into the offline_data table
  Future<void> insertTagData({
    required String tagNumber,
    required String type,
    required double capacity,
    required int checkinCheckout,
    String? companyName,
    String? siteName,
    String? siteLocation,
    String? serialNo,
    String? yearOfMfg,
    String? remarks,
  }) async {
    final db = await database;
    await db.insert(
      'offline_data',
      {
        'tag_number': tagNumber,
        'type': type,
        'capacity': capacity,
        'checkin_checkout': checkinCheckout,
        'company_name': companyName ?? 'N/A',
        'site_name': siteName ?? 'N/A',
        'site_location': siteLocation ?? 'N/A',
        'serial_no': serialNo ?? 'N/A',
        'year_of_mfg': yearOfMfg ?? 'N/A',
        'remarks': remarks ?? 'N/A',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve a specific tag data by tag_number
  Future<Map<String, dynamic>?> getTagData(String tagNumber) async {
    final db = await database;
    final result = await db.query(
      'offline_data',
      where: 'tag_number = ?',
      whereArgs: [tagNumber],
    );

    if (result.isNotEmpty) {
      final data = result.first;
      return {
        'tag_number': data['tag_number'],
        'type': data['type'],
        'capacity': data['capacity'],
        'checkin_checkout': data['checkin_checkout'],
        'company_name': data['company_name'],
        'site_name': data['site_name'],
        'site_location': data['site_location'],
        'serial_no': data['serial_no'],
        'year_of_mfg': data['year_of_mfg'],
        'remarks': data['remarks'],
      };
    } else {
      return null; // No data found
    }
  }

  /// Retrieve all data from the offline_data table
  Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await database;
    final result = await db.query('offline_data');
    print("All data in offline_data:");
    for (var row in result) {
      print(row);
    }
    return result;
  }

  /// Delete all records from the offline_data table
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('offline_data');
  }

  /// Delete a specific record by tag_number
  Future<void> deleteTagData(String tagNumber) async {
    final db = await database;
    await db.delete(
      'offline_data',
      where: 'tag_number = ?',
      whereArgs: [tagNumber],
    );
  }
  /// Print all data in the offline_data table for debugging
  Future<void> printAllData() async {
    final db = await database;
    final result = await db.query('offline_data');
    print("---------- All Data in offline_data ----------");
    for (var row in result) {
      print(row);
    }
    print("------------------------------------------------");
  }

  /// Update a specific record
  Future<void> updateTagData({
    required String tagNumber,
    String? type,
    double? capacity,
    int? checkinCheckout,
    String? companyName,
    String? siteName,
    String? siteLocation,
    String? serialNo,
    String? yearOfMfg,
    String? remarks,
  }) async {
    final db = await database;
    await db.update(
      'offline_data',
      {
        if (type != null) 'type': type,
        if (capacity != null) 'capacity': capacity,
        if (checkinCheckout != null) 'checkin_checkout': checkinCheckout,
        if (companyName != null) 'company_name': companyName,
        if (siteName != null) 'site_name': siteName,
        if (siteLocation != null) 'site_location': siteLocation,
        if (serialNo != null) 'serial_no': serialNo,
        if (yearOfMfg != null) 'year_of_mfg': yearOfMfg,
        if (remarks != null) 'remarks': remarks,
      },
      where: 'tag_number = ?',
      whereArgs: [tagNumber],
    );
  }
}
