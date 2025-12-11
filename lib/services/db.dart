import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import '../models/products.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cfdi_reader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

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