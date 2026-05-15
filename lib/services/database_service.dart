import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'cotizaciones.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cotizaciones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT,
            telefono TEXT,
            iva REAL,
            fecha TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE productos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cotizacion_id INTEGER,
            descripcion TEXT,
            precio REAL,
            cantidad INTEGER,
            FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id)
          );
        ''');

        await db.execute('''
          CREATE TABLE empresa(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            email TEXT,
            telefono TEXT,
            logo_path TEXT
          );
        ''');

        await db.insert('empresa', {
          'nombre': 'AIR-CONTROL',
          'email': 'AIR-CONTROL@HOTMAIL.COM',
          'telefono': '',
          'logo_path': ''
        });
      },
    );
  }
}
