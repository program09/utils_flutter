import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:orm/orm/database/db_helper.dart';

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

  Future<int> insert(T item) async {
    final client = await db;
    return await client.insert(
      tableName,
      toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<T>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(tableName);
    return List.generate(maps.length, (i) => fromMap(maps[i]));
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
    return await client.update(
      tableName,
      toMap(item),
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(dynamic id, {String idColumn = 'id'}) async {
    final client = await db;
    return await client.delete(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final client = await db;
    return await client.delete(tableName);
  }

  // RAW query support if needed (though the goal is to avoid it)
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final client = await db;
    return await client.rawQuery(sql, arguments);
  }

  /// quiero mas acciones por ejemplo
  // formato

  //buscar
  //_repository.createBuilder().select(["name", "age"]).where("age >= ?", [18]).andWhere("name = ?", ["Yordi"]).orWhere("name = ?", ["Yordi"]).toList()

  //delete
  //_repository.createBuilder().delete().where("age >= ?", [18]).toList()

  //update
  //_repository.createBuilder().update(["name", "age"]).set({"name": "Yordi", "age": 25}).where("age >= ?", [18]).toList()

  //_repository.createBuilder().select(["name", "age"]).andSelect('query').where("age >= ?", [18]).toList()
  //_repository.createBuilder().select(["name", "age"]).withRelations(['posts']).where("age >= ?", [18]).toList()
  // manejar where dinamico
  // manejar join
  // manejar group by
  // manejar order by
  // manejar limit
  // manejar offset
  // manejar having
  // manejar union
  // manejar intersect
  // manejar except
  // manejar on conflict
  // manejar on conflict
}
