import 'dart:async';
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
  String _dbName = "app_database.db";
  int _version = 1;
  List<orm.Table> _tables = [];

  // --- Real-time Streams (Watchers) ---
  final _tableChangeController = StreamController<String>.broadcast();
  Stream<String> get onTableChange => _tableChangeController.stream;

  /// Notifica que una tabla ha sido modificada.
  void notify(String tableName) {
    _tableChangeController.add(tableName);
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  void setConfig({
    String? name,
    int? version,
    String? password,
    List<orm.Table>? tables,
  }) {
    if (name != null) _dbName = name;
    if (version != null) _version = version;
    if (password != null) _password = password;
    if (tables != null) _tables = tables;

    if (_db != null) {
      lg.w(
        msg:
            'Configuración de DB cambiada después de abrir. Reinicia la conexión.',
        module: 'DB_CORE',
      );
    }
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _version,
      password: _password,
      onCreate: (Database db, int version) async {
        await _syncSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await _syncSchema(db);
      },
    );
  }

  Future<void> _syncSchema(Database db) async {
    for (var table in _tables) {
      // 1. Verificar si la tabla existe
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${table.name}'",
      );

      if (tableCheck.isEmpty) {
        // Crear tabla si no existe
        await db.execute(table.toSql());
        lg.i(msg: 'Tabla creada: ${table.name}', module: 'DB_CORE');
      } else {
        // 2. Inspeccionar columnas existentes
        final columnInfo = await db.rawQuery(
          "PRAGMA table_info('${table.name}')",
        );
        final existingColumnsMap = {
          for (var c in columnInfo) c['name'] as String: c,
        };
        final modelColumnNames = table.columns.map((c) => c.name).toSet();

        bool needsRebuild = false;

        // Detectar si hay cambios o nuevas columnas
        for (var column in table.columns) {
          final existing = existingColumnsMap[column.name];
          if (existing == null) {
            // Nueva columna: Intentamos ALTER TABLE
            try {
              await db.execute(
                "ALTER TABLE ${table.name} ADD COLUMN ${column.toSql()}",
              );
              lg.w(
                msg: 'Columna añadida (ALTER): ${column.name}',
                module: 'DB_CORE',
              );
            } catch (e) {
              lg.e(
                msg: 'Fallo ALTER TABLE, se requiere rebuild: $e',
                module: 'DB_CORE',
              );
              needsRebuild = true;
              break;
            }
          } else {
            // Comparar atributos (Tipo, Nullable, PK)
            final dbType = (existing['type'] as String).toUpperCase();
            final modelSql = column.toSql();
            final modelType = modelSql.split(' ')[1].toUpperCase();

            final isDbNullable = existing['notnull'] == 0;
            final isModelNullable = column.isNullable == true;

            final isDbPK = existing['pk'] == 1;
            final isModelPK = column.isPrimaryKey == true;

            if (dbType != modelType ||
                isDbNullable != isModelNullable ||
                isDbPK != isModelPK) {
              lg.w(
                msg:
                    'Cambio detectado en columna ${column.name} (Tipo/Constraint). Reconstruyendo...',
                module: 'DB_CORE',
              );
              needsRebuild = true;
              break;
            }
          }
        }

        // Detectar si hay columnas en la DB que NO están en el modelo (Eliminar)
        if (!needsRebuild &&
            existingColumnsMap.keys.any((c) => !modelColumnNames.contains(c))) {
          lg.w(
            msg: 'Columnas eliminadas detectadas en modelo. Reconstruyendo...',
            module: 'DB_CORE',
          );
          needsRebuild = true;
        }

        if (needsRebuild) {
          await _rebuildTable(db, table);
        }
      }
    }
    lg.s(
      msg: 'Sincronización de esquema avanzada completada.',
      module: 'DB_CORE',
    );
  }

  /// Reconstruye una tabla para aplicar cambios complejos (drop column, change type)
  Future<void> _rebuildTable(Database db, orm.Table table) async {
    final tempName = "_temp_${table.name}";
    lg.i(
      msg: 'Reconstruyendo tabla ${table.name} (Safe Migration)...',
      module: 'DB_CORE',
    );

    await db.transaction((txn) async {
      // 1. Obtener columnas comunes para migrar datos
      final columnInfo = await txn.rawQuery(
        "PRAGMA table_info('${table.name}')",
      );
      final existingColumns = columnInfo
          .map((c) => c['name'] as String)
          .toSet();
      final modelColumns = table.columns.map((c) => c.name).toSet();
      final commonColumns = existingColumns.intersection(modelColumns).toList();

      // 2. Crear tabla temporal con el nuevo esquema
      final tempTableSql = table.toSql().replaceFirst(table.name, tempName);
      await txn.execute(tempTableSql);

      // 3. Copiar datos si hay columnas en común
      if (commonColumns.isNotEmpty) {
        final cols = commonColumns.join(', ');
        await txn.execute(
          "INSERT INTO $tempName ($cols) SELECT $cols FROM ${table.name}",
        );
      }

      // 4. Intercambiar tablas
      await txn.execute("DROP TABLE ${table.name}");
      await txn.execute("ALTER TABLE $tempName RENAME TO ${table.name}");
    });

    lg.s(
      msg: 'Tabla ${table.name} reconstruida exitosamente.',
      module: 'DB_CORE',
    );
  }

  /// Utilidad para renombrar tablas manualmente
  Future<void> renameTable(String oldName, String newName) async {
    final database = await db;
    await database.execute("ALTER TABLE $oldName RENAME TO $newName");
    lg.i(msg: 'Tabla renombrada: $oldName -> $newName', module: 'DB_CORE');
  }

  List<orm.Table> get tables => _tables;

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
