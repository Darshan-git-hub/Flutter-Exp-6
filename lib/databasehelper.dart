import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'dart:io';
import 'code_snippet.dart';

class DatabaseHelper {
  static Database? _database;
  static final _log = Logger('DatabaseHelper');

  static DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      // Initialize FFI for desktop/mobile
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Initialize logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      String path;
      if (kIsWeb) {
        // On the web we cannot access the local filesystem. Use a simple
        // filename so sqflite_common_ffi_web stores the DB in IndexedDB.
        path = 'code_snippets.db';
        _log.info('Running on web - using IndexedDB filename: $path');
      } else {
        path = 'D:/SQLiteDatabaseBrowserPortable/Data/code_snippets.db';
        _log.info('Initializing database at: $path');

        // Create directory if it doesn't exist (desktop/mobile only)
        try {
          var dir = Directory('D:/SQLiteDatabaseBrowserPortable/Data');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
            _log.info('Database directory created');
          } else {
            _log.info('Database directory already exists');
          }
          _log.info('Directory path: ${dir.absolute.path}');

          // List directory contents for debugging
          await for (var entity in dir.list()) {
            _log.info('Found in directory: ${entity.path}');
          }
        } catch (e) {
          _log.severe('Error accessing/creating database directory: $e');
          throw Exception('Cannot access/create database directory: $e');
        }
      }

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          _log.info('Creating new database...');
          String sql =
              "CREATE TABLE code_snippets(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, code TEXT, language TEXT, description TEXT, dateAdded TEXT)";
          await db.execute(sql);
        },
        onOpen: (db) async {
          _log.info('Database opened successfully!');
          var tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
          _log.info('Available tables: ${tables.map((t) => t['name']).toList()}');
        },
      );

      return _database!;
    } catch (e) {
      _log.severe('Database Error: $e');
      rethrow;
    }
  }

  Future<int> insertSnippet(CodeSnippet snippet) async {
    try {
      Database db = await instance.database;
      int id = await db.insert('code_snippets', snippet.toMap());
      _log.info('Inserted snippet with id: $id');
      return id;
    } catch (e) {
      _log.severe('Error inserting snippet: $e');
      rethrow;
    }
  }

  Future<List<CodeSnippet>> getAllSnippets() async {
    try {
      Database db = await instance.database;
      final records = await db.query("code_snippets", orderBy: "dateAdded DESC");
      _log.info('Retrieved ${records.length} snippets');
      return records.map((record) => CodeSnippet.fromRow(record)).toList();
    } catch (e) {
      _log.severe('Error getting all snippets: $e');
      return []; // Return empty list instead of throwing
    }
  }

  Future<List<CodeSnippet>> searchSnippets(String query) async {
    try {
      Database db = await instance.database;
      final records = await db.query(
        "code_snippets",
        where: "title LIKE ? OR description LIKE ? OR code LIKE ?",
        whereArgs: ["%$query%", "%$query%", "%$query%"],
        orderBy: "dateAdded DESC",
      );
      _log.info('Found ${records.length} snippets matching query: $query');
      return records.map((record) => CodeSnippet.fromRow(record)).toList();
    } catch (e) {
      _log.severe('Error searching snippets: $e');
      rethrow;
    }
  }

  Future<List<CodeSnippet>> getSnippetsByLanguage(String language) async {
    try {
      Database db = await instance.database;
      final records = await db.query(
        "code_snippets",
        where: "language = ?",
        whereArgs: [language],
        orderBy: "dateAdded DESC",
      );
      _log.info('Found ${records.length} snippets for language: $language');
      return records.map((record) => CodeSnippet.fromRow(record)).toList();
    } catch (e) {
      _log.severe('Error getting snippets by language: $e');
      rethrow;
    }
  }

  Future<bool> isDatabaseConnected() async {
    try {
      final db = await instance.database;
      await db.query('sqlite_master', columns: ['type']);
      _log.info('Database connection test: SUCCESS');
      return true;
    } catch (e) {
      _log.severe('Database connection test: FAILED - Error: $e');
      return false;
    }
  }

  Future<int> deleteSnippet(int id) async {
    try {
      final db = await instance.database;
      int result = await db.delete(
        'code_snippets',
        where: 'id = ?',
        whereArgs: [id],
      );
      _log.info('Deleted snippet with id: $id');
      return result;
    } catch (e) {
      _log.severe('Error deleting snippet: $e');
      rethrow;
    }
  }
}
