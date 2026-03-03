import 'dart:async';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:orm/orm/database/db_helper.dart';
import 'package:orm/orm/tables/relation.dart';

enum QueryType { select, update, delete, insert }

class QueryBuilder<T> {
  final Future<Database> db;
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  QueryType _type = QueryType.select;
  List<String> _selectColumns = ['*'];
  Map<String, dynamic> _updateValues = {};
  final List<String> _whereClauses = [];
  final List<dynamic> _whereArgs = [];
  final List<String> _joins = [];
  final List<String> _groupBy = [];
  final List<String> _havingClauses = [];
  final List<dynamic> _havingArgs = [];
  final List<String> _orderBy = [];
  final List<String> _relations = [];
  int? _limit;
  int? _offset;
  ConflictAlgorithm? _conflictAlgorithm;

  QueryBuilder({
    required this.db,
    required this.tableName,
    required this.fromMap,
    required this.toMap,
  });

  // --- Core Methods ---

  QueryBuilder<T> select([List<String> columns = const ['*']]) {
    _type = QueryType.select;
    _selectColumns = columns;
    return this;
  }

  QueryBuilder<T> andSelect(String columnSql) {
    if (_selectColumns.length == 1 && _selectColumns[0] == '*') {
      _selectColumns = [columnSql];
    } else {
      _selectColumns.add(columnSql);
    }
    return this;
  }

  QueryBuilder<T> delete() {
    _type = QueryType.delete;
    return this;
  }

  QueryBuilder<T> update() {
    _type = QueryType.update;
    return this;
  }

  QueryBuilder<T> insert() {
    _type = QueryType.insert;
    return this;
  }

  QueryBuilder<T> set(Map<String, dynamic> values) {
    _updateValues = values; // Used for insert and update
    return this;
  }

  QueryBuilder<T> withRelations(List<String> relations) {
    _relations.addAll(relations);
    return this;
  }

  // --- Filtering ---

  QueryBuilder<T> where(String condition, [List<dynamic>? args]) {
    _whereClauses.add(condition);
    if (args != null) _whereArgs.addAll(args);
    return this;
  }

  QueryBuilder<T> andWhere(String condition, [List<dynamic>? args]) {
    if (_whereClauses.isNotEmpty) {
      _whereClauses.add('AND ($condition)');
    } else {
      _whereClauses.add(condition);
    }
    if (args != null) _whereArgs.addAll(args);
    return this;
  }

  QueryBuilder<T> orWhere(String condition, [List<dynamic>? args]) {
    if (_whereClauses.isNotEmpty) {
      _whereClauses.add('OR ($condition)');
    } else {
      _whereClauses.add(condition);
    }
    if (args != null) _whereArgs.addAll(args);
    return this;
  }

  // --- Complex Clauses ---

  QueryBuilder<T> join(
    String table,
    String condition, {
    String type = 'INNER',
  }) {
    _joins.add('$type JOIN $table ON $condition');
    return this;
  }

  QueryBuilder<T> groupBy(String column) {
    _groupBy.add(column);
    return this;
  }

  QueryBuilder<T> having(String condition, [List<dynamic>? args]) {
    _havingClauses.add(condition);
    if (args != null) _havingArgs.addAll(args);
    return this;
  }

  QueryBuilder<T> orderBy(String column, {String order = 'ASC'}) {
    _orderBy.add('$column $order');
    return this;
  }

  QueryBuilder<T> limit(int limit) {
    _limit = limit;
    return this;
  }

  QueryBuilder<T> offset(int offset) {
    _offset = offset;
    return this;
  }

  QueryBuilder<T> onConflict(ConflictAlgorithm algorithm) {
    _conflictAlgorithm = algorithm;
    return this;
  }

  // --- Execution ---

  Future<List<T>> toList() async {
    final client = await db;
    final sql = _buildQuery();
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      sql,
      _whereArgs,
    );

    if (maps.isEmpty) return [];

    if (_relations.isEmpty) {
      return List.generate(maps.length, (i) => fromMap(maps[i]));
    }

    final mutableMaps = await _fetchMutableMaps(maps);
    return mutableMaps.map((m) => fromMap(m)).toList();
  }

  /// Ejecuta la consulta y devuelve los resultados como una lista de Maps originales,
  /// respetando las columnas seleccionadas (útil para proyecciones parciales).
  Future<List<Map<String, dynamic>>> toMapList() async {
    final client = await db;
    final sql = _buildQuery();
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      sql,
      _whereArgs,
    );

    if (_relations.isEmpty || maps.isEmpty) {
      return maps;
    }

    final mutableMaps = await _fetchMutableMaps(maps);

    // Si el usuario pidió columnas específicas y no usó '*',
    // filtramos para devolver solo lo que pidió + las relaciones cargadas
    if (!_selectColumns.contains('*')) {
      for (var map in mutableMaps) {
        final keysToRemove = map.keys
            .where(
              (k) => !_selectColumns.contains(k) && !_relations.contains(k),
            )
            .toList();
        for (var key in keysToRemove) {
          map.remove(key);
        }
      }
    }

    return mutableMaps;
  }

  Future<List<Map<String, dynamic>>> _fetchMutableMaps(
    List<Map<String, dynamic>> maps,
  ) async {
    final client = await db;
    final List<Map<String, dynamic>> mutableMaps = maps
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final allTables = DbHelper().tables;
    final tableDef = allTables.firstWhere((t) => t.name == tableName);

    // Reutilizamos la lógica de PK obtenida en el contexto de la relación
    final pkName = tableDef.columns
        .firstWhere(
          (c) => c.isPrimaryKey == true,
          orElse: () => tableDef.columns.first,
        )
        .name;

    for (var relationName in _relations) {
      final relation = tableDef.relations[relationName];
      if (relation == null) continue;

      final targetTableDef = allTables.firstWhere(
        (t) => t.name == relation.targetTable,
      );
      final targetPkName = targetTableDef.columns
          .firstWhere(
            (c) => c.isPrimaryKey == true,
            orElse: () => targetTableDef.columns.first,
          )
          .name;

      if (relation.type == RelationType.belongsTo) {
        final foreignKeys = mutableMaps
            .map((m) => m[relation.foreignKey])
            .where((k) => k != null)
            .toSet()
            .toList();
        if (foreignKeys.isEmpty) continue;
        final placeholders = List.filled(foreignKeys.length, '?').join(', ');
        final relatedMaps = await client.rawQuery(
          "SELECT * FROM ${relation.targetTable} WHERE $targetPkName IN ($placeholders)",
          foreignKeys,
        );
        final relatedById = {for (var m in relatedMaps) m[targetPkName]: m};
        for (var map in mutableMaps) {
          final fk = map[relation.foreignKey];
          if (fk != null) map[relationName] = relatedById[fk];
        }
      } else if (relation.type == RelationType.hasMany) {
        final primaryKeys = mutableMaps.map((m) => m[pkName]).toList();
        final placeholders = List.filled(primaryKeys.length, '?').join(', ');
        final relatedMaps = await client.rawQuery(
          "SELECT * FROM ${relation.targetTable} WHERE ${relation.foreignKey} IN ($placeholders)",
          primaryKeys,
        );
        final groupedByFk = <dynamic, List<Map<String, dynamic>>>{};
        for (var rm in relatedMaps) {
          groupedByFk.putIfAbsent(rm[relation.foreignKey], () => []).add(rm);
        }
        for (var map in mutableMaps) {
          map[relationName] = groupedByFk[map[pkName]] ?? [];
        }
      } else if (relation.type == RelationType.manyToMany) {
        final primaryKeys = mutableMaps.map((m) => m[pkName]).toList();
        final placeholders = List.filled(primaryKeys.length, '?').join(', ');
        final sql =
            '''
          SELECT pt.${relation.sourcePivotKey} as _pivot_key, tt.* 
          FROM ${relation.targetTable} tt
          INNER JOIN ${relation.pivotTable} pt ON tt.$targetPkName = pt.${relation.targetPivotKey}
          WHERE pt.${relation.sourcePivotKey} IN ($placeholders)
        ''';
        final pivotResults = await client.rawQuery(sql, primaryKeys);
        final groupedByPivot = <dynamic, List<Map<String, dynamic>>>{};
        for (var pr in pivotResults) {
          final sourceKey = pr['_pivot_key'];
          final entityMap = Map<String, dynamic>.from(pr)..remove('_pivot_key');
          groupedByPivot.putIfAbsent(sourceKey, () => []).add(entityMap);
        }
        for (var map in mutableMaps) {
          map[relationName] = groupedByPivot[map[pkName]] ?? [];
        }
      }
    }
    return mutableMaps;
  }

  Future<T?> getOne() async {
    _limit = 1;
    final results = await toList();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> execute() async {
    final client = await db;
    final whereStr = _whereClauses.isNotEmpty ? _whereClauses.join(' ') : null;

    int result = 0;
    if (_type == QueryType.delete) {
      result = await client.delete(
        tableName,
        where: whereStr,
        whereArgs: _whereArgs,
      );
    } else if (_type == QueryType.update) {
      result = await client.update(
        tableName,
        _updateValues,
        where: whereStr,
        whereArgs: _whereArgs,
        conflictAlgorithm: _conflictAlgorithm,
      );
    } else if (_type == QueryType.insert) {
      result = await client.insert(
        tableName,
        _updateValues,
        conflictAlgorithm: _conflictAlgorithm,
      );
    }

    // Notificar cambios si hubo filas afectadas o fue un insert
    if (result > 0 || _type == QueryType.insert) {
      DbHelper().notify(tableName);
    }

    return result;
  }

  /// Observa cambios en la tabla y emite la lista de modelos actualizada.
  Stream<List<T>> watch() {
    // 1. Emitir primer valor inmediatamente
    final controller = StreamController<List<T>>();

    Future<void> refresh() async {
      try {
        final data = await toList();
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    refresh(); // Carga inicial

    // 2. Escuchar cambios en la tabla
    final subscription = DbHelper().onTableChange.listen((changedTable) {
      if (changedTable == tableName) {
        refresh();
      }
    });

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  /// Observa cambios en la tabla y emite la lista de mapas actualizada.
  Stream<List<Map<String, dynamic>>> watchMapList() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    Future<void> refresh() async {
      try {
        final data = await toMapList();
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    refresh(); // Carga inicial

    final subscription = DbHelper().onTableChange.listen((changedTable) {
      if (changedTable == tableName) {
        refresh();
      }
    });

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  // --- SQL Building ---

  String _buildQuery() {
    if (_type == QueryType.select) {
      List<String> columnsToSelect = List.from(_selectColumns);

      // Si hay relaciones, asegurarnos de que la PK esté presente para poder vincularlas
      if (_relations.isNotEmpty && !columnsToSelect.contains('*')) {
        final allTables = DbHelper().tables;
        final tableDef = allTables.firstWhere((t) => t.name == tableName);
        final pkName = tableDef.columns
            .firstWhere(
              (c) => c.isPrimaryKey == true,
              orElse: () => tableDef.columns.first,
            )
            .name;

        if (!columnsToSelect.contains(pkName)) {
          columnsToSelect.add(pkName);
        }
      }

      final columns = columnsToSelect.join(', ');
      var sql = 'SELECT $columns FROM $tableName';

      if (_joins.isNotEmpty) sql += ' ${_joins.join(' ')}';
      if (_whereClauses.isNotEmpty) sql += ' WHERE ${_whereClauses.join(' ')}';
      if (_groupBy.isNotEmpty) sql += ' GROUP BY ${_groupBy.join(', ')}';
      if (_havingClauses.isNotEmpty) {
        sql += ' HAVING ${_havingClauses.join(' ')}';
      }
      if (_orderBy.isNotEmpty) sql += ' ORDER BY ${_orderBy.join(', ')}';
      if (_limit != null) sql += ' LIMIT $_limit';
      if (_offset != null) sql += ' OFFSET $_offset';

      return sql;
    }
    return '';
  }
}
