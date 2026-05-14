import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('store_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        item TEXT NOT NULL,
        unit TEXT,
        quantity REAL,
        unit_price REAL,
        total REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        item TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT
      )
    ''');
  }

  // ===== PURCHASES =====
  Future<int> insertPurchase(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('purchases', row);
  }

  Future<List<Map<String, dynamic>>> getPurchases({String? month}) async {
    final db = await database;
    if (month != null) {
      return await db.query('purchases',
          where: "strftime('%Y-%m', date) = ?",
          whereArgs: [month],
          orderBy: 'date DESC');
    }
    return await db.query('purchases', orderBy: 'date DESC');
  }

  Future<int> updatePurchase(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('purchases', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return await db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  // ===== EXPENSES =====
  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> getExpenses({String? month}) async {
    final db = await database;
    if (month != null) {
      return await db.query('expenses',
          where: "strftime('%Y-%m', date) = ?",
          whereArgs: [month],
          orderBy: 'date DESC');
    }
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<int> updateExpense(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('expenses', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ===== SUMMARY =====
  Future<Map<String, double>> getPurchaseSummaryByCategory({String? month}) async {
    final db = await database;
    String whereClause = month != null ? "WHERE strftime('%Y-%m', date) = '$month'" : '';
    final result = await db.rawQuery('''
      SELECT category, SUM(total) as total
      FROM purchases $whereClause
      GROUP BY category
      ORDER BY total DESC
    ''');
    return {for (var r in result) r['category'] as String: (r['total'] as num).toDouble()};
  }

  Future<Map<String, double>> getExpenseSummaryByCategory({String? month}) async {
    final db = await database;
    String whereClause = month != null ? "WHERE strftime('%Y-%m', date) = '$month'" : '';
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses $whereClause
      GROUP BY category
      ORDER BY total DESC
    ''');
    return {for (var r in result) r['category'] as String: (r['total'] as num).toDouble()};
  }

  Future<double> getTotalPurchases({String? month}) async {
    final db = await database;
    String whereClause = month != null ? "WHERE strftime('%Y-%m', date) = '$month'" : '';
    final result = await db.rawQuery('SELECT SUM(total) as t FROM purchases $whereClause');
    return (result.first['t'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpenses({String? month}) async {
    final db = await database;
    String whereClause = month != null ? "WHERE strftime('%Y-%m', date) = '$month'" : '';
    final result = await db.rawQuery('SELECT SUM(amount) as t FROM expenses $whereClause');
    return (result.first['t'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAvailableMonths() async {
    final db = await database;
    final p = await db.rawQuery("SELECT DISTINCT strftime('%Y-%m', date) as m FROM purchases ORDER BY m DESC");
    final e = await db.rawQuery("SELECT DISTINCT strftime('%Y-%m', date) as m FROM expenses ORDER BY m DESC");
    final months = <String>{};
    for (var r in p) months.add(r['m'] as String);
    for (var r in e) months.add(r['m'] as String);
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted.map((m) => {'month': m}).toList();
  }
}
