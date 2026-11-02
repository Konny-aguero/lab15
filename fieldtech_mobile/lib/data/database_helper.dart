import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fieldtech_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
     CREATE TABLE incidencias_locales ( 
       id INTEGER PRIMARY KEY AUTOINCREMENT, 
       titulo TEXT NOT NULL, 
       descripcion TEXT NOT NULL, 
       categoria TEXT NOT NULL, 
       latitud REAL NOT NULL, 
       longitud REAL NOT NULL, 
       foto_path TEXT, 
       is_synced INTEGER NOT NULL DEFAULT 0, 
       fecha_creacion TEXT NOT NULL 
     ) 
   ''');
  }

  Future<int> insertar(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('incidencias_locales', row);
  }

  Future<List<Map<String, dynamic>>> obtenerTodas({int? sincronizado}) async {
    final db = await instance.database;
    return await db.query(
      'incidencias_locales',
      where: sincronizado == null ? null : 'is_synced = ?',
      whereArgs: sincronizado == null ? null : [sincronizado],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    final db = await instance.database;
    return await db.query(
      'incidencias_locales',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<int> marcarSincronizado(int id) async {
    final db = await instance.database;
    return await db.update(
      'incidencias_locales',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
