import 'package:orm/example/models/role.model.dart';
import 'package:orm/orm/tables/relation.dart';
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
      Column(name: 'email', type: ColumnType.text, isNullable: true),
    ],
    relations: {
      'roles': Relation.manyToMany(
        'roles',
        pivotTable: 'user_roles',
        sourcePivotKey: 'user_id',
        targetPivotKey: 'role_id',
      ),
    },
  );

  final int id;
  final String name;
  final int age;
  final String? email;
  final List<Role>? roles;

  User({
    required this.id,
    required this.name,
    required this.age,
    this.email,
    this.roles,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      email: map['email'],
      roles: map['roles'] != null
          ? (map['roles'] as List).map((r) => Role.fromMap(r)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'age': age, 'email': email};
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, age: $age, roles: ${roles?.map((r) => r.name).toList()})';
  }
}
