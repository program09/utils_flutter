import 'package:orm/orm/tables/table.dart' as orm;
import 'package:orm/orm/tables/column.dart';

class Category {
  static const String tableName = 'categories';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      Column(name: 'name', type: ColumnType.text),
    ],
  );

  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
