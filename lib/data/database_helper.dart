import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), "nfc_scans.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveScan(String data) async {
    final db = await database;
    await db.insert("scans", {"data": data, "date": DateTime.now().toString()});
  }

  Future<List<Map<String, dynamic>>> getScans() async {
    final db = await database;
    return await db.query("scans", orderBy: "date DESC");
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete("scans", where: "id = ?", whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete("scans");
  }
}
