import 'package:orm/orm/tables/table.dart' as orm;
import 'package:orm/orm/tables/column.dart';

class User {
  static const String tableName = 'users';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      Column(name: 'name', type: ColumnType.text),
      Column(name: 'age', type: ColumnType.integer),
    ],
  );

  // definir campos de la tabla

  final int id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(id: map['id'], name: map['name'], age: map['age']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'age': age};
  }
}
