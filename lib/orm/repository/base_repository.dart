import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:orm/orm/database/db_helper.dart';
import 'package:orm/orm/query_builder/query_builder.dart';

abstract class BaseRepository<T> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  BaseRepository({
    required this.tableName,
    required this.fromMap,
    required this.toMap,
  });

  Future<Database> get db => DbHelper().db;

  QueryBuilder<T> createBuilder() {
    return QueryBuilder<T>(
      db: db,
      tableName: tableName,
      fromMap: fromMap,
      toMap: toMap,
    );
  }

  Future<int> insert(T item) async {
    final client = await db;
    final id = await client.insert(
      tableName,
      toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id > 0) DbHelper().notify(tableName);
    return id;
  }

  Future<List<T>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(tableName);
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Observa todos los cambios en la tabla y emite la lista completa de modelos.
  Stream<List<T>> watchAll() {
    return createBuilder().watch();
  }

  Future<T?> getById(dynamic id, {String idColumn = 'id'}) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(
    T item, {
    required dynamic id,
    String idColumn = 'id',
  }) async {
    final client = await db;
    final count = await client.update(
      tableName,
      toMap(item),
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (count > 0) DbHelper().notify(tableName);
    return count;
  }

  Future<int> delete(dynamic id, {String idColumn = 'id'}) async {
    final client = await db;
    final count = await client.delete(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (count > 0) DbHelper().notify(tableName);
    return count;
  }

  Future<int> deleteAll() async {
    final client = await db;
    final count = await client.delete(tableName);
    if (count > 0) DbHelper().notify(tableName);
    return count;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final client = await db;
    return await client.rawQuery(sql, arguments);
  }
}
