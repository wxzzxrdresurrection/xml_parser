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
    final Directory appDir = await getApplicationSupportDirectory();

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    final String dbPath = p.join(appDir.path, 'xml_parser.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN supplierName TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN invoiceDate TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN invoiceFolio TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN invoiceUuid TEXT');
        }
      },
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
        createdAt TEXT,
        supplierName TEXT,
        invoiceDate TEXT,
        invoiceFolio TEXT,
        invoiceUuid TEXT
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
      final invoiceDateRaw = maps[i]['invoiceDate'] as String?;
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
        supplierName: maps[i]['supplierName'] as String?,
        invoiceDate: invoiceDateRaw == null ? null : DateTime.tryParse(invoiceDateRaw),
        invoiceFolio: maps[i]['invoiceFolio'] as String?,
        invoiceUuid: maps[i]['invoiceUuid'] as String?,
      );
    });
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}