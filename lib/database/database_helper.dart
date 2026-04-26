import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/perfil.dart';
import '../models/retal.dart';

class ResultadoCorte {
  final bool exito;
  final String mensaje;
  final bool usadoRetal;
  final int? sobrante;

  const ResultadoCorte({
    required this.exito,
    required this.mensaje,
    this.usadoRetal = false,
    this.sobrante,
  });
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pvc_stock.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Configuración para WEB (iPhone Safari)
      var databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    } else {
      // Configuración para ANDROID
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color_principal TEXT NOT NULL,
        es_bicolor INTEGER NOT NULL DEFAULT 0,
        color_interior TEXT,
        color_exterior TEXT,
        longitud_inicial INTEGER NOT NULL,
        barras_enteras INTEGER NOT NULL DEFAULT 0,
        stock_minimo INTEGER NOT NULL DEFAULT 5
      )
    ''');
    await db.execute('''
      CREATE TABLE retales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        perfil_id INTEGER NOT NULL,
        longitud INTEGER NOT NULL,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (perfil_id) REFERENCES perfiles (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- El resto de tus métodos (insertPerfil, getAllPerfiles, registrarCorte, etc.) se mantienen igual ---
  // --- Cópialos debajo de aquí de tu código original ---

  Future<int> insertPerfil(Perfil perfil) async {
    final db = await database;
    return db.insert('perfiles', perfil.toMap());
  }

  Future<List<Perfil>> getAllPerfiles() async {
    final db = await database;
    final rows = await db.query('perfiles', orderBy: 'nombre ASC');
    return rows.map(Perfil.fromMap).toList();
  }

  Future<void> updatePerfil(Perfil perfil) async {
    final db = await database;
    await db.update('perfiles', perfil.toMap(), where: 'id = ?', whereArgs: [perfil.id]);
  }

  Future<void> deletePerfil(int id) async {
    final db = await database;
    await db.delete('perfiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRetal(Retal retal) async {
    final db = await database;
    return db.insert('retales', retal.toMap());
  }

  Future<List<Retal>> getRetalesByPerfil(int perfilId) async {
    final db = await database;
    final rows = await db.query(
      'retales',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      orderBy: 'longitud ASC',
    );
    return rows.map(Retal.fromMap).toList();
  }

  Future<void> deleteRetal(int id) async {
    final db = await database;
    await db.delete('retales', where: 'id = ?', whereArgs: [id]);
  }

  Future<ResultadoCorte> registrarCorte(int perfilId, int longitudCorte) async {
    final db = await database;
    return db.transaction<ResultadoCorte>((txn) async {
      final perfilRows = await txn.query('perfiles', where: 'id = ?', whereArgs: [perfilId]);
      if (perfilRows.isEmpty) return const ResultadoCorte(exito: false, mensaje: 'Perfil no encontrado');
      final perfil = Perfil.fromMap(perfilRows.first);

      if (longitudCorte > perfil.longitudInicial) {
        return ResultadoCorte(exito: false, mensaje: 'Corte excede longitud');
      }

      final retalesRows = await txn.query(
        'retales',
        where: 'perfil_id = ? AND longitud >= ?',
        whereArgs: [perfilId, longitudCorte],
        orderBy: 'longitud ASC',
        limit: 1,
      );

      if (retalesRows.isNotEmpty) {
        final retal = Retal.fromMap(retalesRows.first);
        final sobrante = retal.longitud - longitudCorte;
        if (sobrante == 0) {
          await txn.delete('retales', where: 'id = ?', whereArgs: [retal.id]);
        } else {
          await txn.update('retales', {'longitud': sobrante}, where: 'id = ?', whereArgs: [retal.id]);
        }
        return ResultadoCorte(exito: true, mensaje: 'Retal usado', usadoRetal: true, sobrante: sobrante);
      }

      if (perfil.barrasEnteras <= 0) return const ResultadoCorte(exito: false, mensaje: 'Sin stock');

      await txn.update('perfiles', {'barras_enteras': perfil.barrasEnteras - 1}, where: 'id = ?', whereArgs: [perfilId]);
      final sobrante = perfil.longitudInicial - longitudCorte;
      if (sobrante > 0) {
        await txn.insert('retales', {
          'perfil_id': perfilId,
          'longitud': sobrante,
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
      }
      return ResultadoCorte(exito: true, mensaje: 'Barra abierta', usadoRetal: false, sobrante: sobrante);
    });
  }
}