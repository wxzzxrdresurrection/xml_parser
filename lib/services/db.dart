import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import '../models/products.dart';
import 'dart:io';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final baseDir = Platform.environment['LOCALAPPDATA'];
    if (baseDir == null) {
      throw Exception('LOCALAPPDATA not found');
    }

    final dbDir = Directory(p.join(baseDir, 'XMLParser'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    final path = p.join(dbDir.path, 'xml_parser.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        identificationNumber TEXT,
        unitCode TEXT,
        unitName TEXT,
        quantity REAL,
        unitPrice REAL,
        totalAmount REAL,
        createdAt TEXT
      )
    ''');
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<dynamic>> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (var product in products) {
      batch.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    final results = await batch.commit(noResult: false);

    return results;
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        description: maps[i]['description'],
        identificationNumber: maps[i]['identificationNumber'],
        unitCode: maps[i]['unitCode'],
        unitName: maps[i]['unitName'],
        quantity: maps[i]['quantity'],
        unitPrice: maps[i]['unitPrice'],
        totalAmount: maps[i]['totalAmount'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}