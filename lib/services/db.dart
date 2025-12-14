import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
     print('| GET APP SUPPORT DIR');

    final Directory appDir = await getApplicationSupportDirectory();
    print('| APP DIR: ${appDir.path}');

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    final String dbPath = p.join(appDir.path, 'xml_parser.db');
    print('| DB PATH: $dbPath');

    return await openDatabase(
      dbPath,
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