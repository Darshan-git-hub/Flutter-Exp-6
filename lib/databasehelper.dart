import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'product.dart';
class DatabaseHelper {
  static Database? _database;

  static DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor() {
    if (kIsWeb) {
      // Initialize for web
      databaseFactory = databaseFactoryFfiWeb;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      // For web platform, use a different approach
      String path = 'products.db';
      print('\n\nINFO: Running in web mode - using in-memory database\n\n');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print('Creating new database...');
          String sql =
              "CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,quantity INTEGER,price REAL)";
          await db.execute(sql);
        },
      );

      print('Database Path: $path'); // Print the database path

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print('Creating new database...'); // Print when creating new database
          String sql =
              "CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,quantity INTEGER,price REAL)";
          await db.execute(sql);
        },
        onOpen: (db) async {
          print('Database opened successfully!'); // Print when database is opened
          // Verify the products table exists
          var tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
          print('Available tables: ${tables.map((t) => t['name']).toList()}');
        },
      );

      return _database!;
    } catch (e) {
      print('Database Error: $e'); // Print any errors that occur
      throw e;
    }
  }

  Future<int> insertProduct(Product product) async {
    Database db = await instance.database;
    return await db.insert('products', {
      'name': product.name,
      'quantity': product.quantity,
      'price': product.price
    });
  }

  Future<List<Product>> readAllProducts() async {
    Database db = await instance.database;

    final records = await db.query("products");

    return records.map((record) => Product.fromRow(record)).toList();
  }

  Future<bool> isDatabaseConnected() async {
    try {
      final db = await instance.database;
      // Try to perform a simple query
      await db.query('sqlite_master', columns: ['type']);
      print('Database connection test: SUCCESS');
      return true;
    } catch (e) {
      print('Database connection test: FAILED');
      print('Error: $e');
      return false;
    }
  }

  Future<int> resetProducts() async {
    final db = await instance.database;

    return await db.delete("products");
  }
}
