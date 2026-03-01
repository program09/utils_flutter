import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:orm/utils/logs.dart';
import 'package:orm/orm/tables/table.dart' as orm;

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _db;
  String? _password;
  List<orm.Table> _tables = [];

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  void setPassword(String password) => _password = password;
  void setTables(List<orm.Table> tables) => _tables = tables;

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "app_database.db");

    return await openDatabase(
      path,
      version: 1,
      password: _password,
      onCreate: (Database db, int version) async {
        for (var table in _tables) {
          await db.execute(table.toSql());
          lg.i(msg: 'Tabla creada: ${table.name}', module: 'DB_HELPER');
        }
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Manejar migraciones aquí si es necesario
      },
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
