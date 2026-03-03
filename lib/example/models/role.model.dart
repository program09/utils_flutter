import 'package:orm/example/models/users.model.dart';
import 'package:orm/orm/tables/relation.dart';
import 'package:orm/orm/tables/table.dart' as orm;
import 'package:orm/orm/tables/column.dart';

class Role {
  static const String tableName = 'roles';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      Column(name: 'name', type: ColumnType.text),
    ],
    relations: {
      'users': Relation.manyToMany(
        'users',
        pivotTable: 'user_roles',
        sourcePivotKey: 'role_id',
        targetPivotKey: 'user_id',
      ),
    },
  );

  final int? id;
  final String name;
  final List<User>? users;

  Role({this.id, required this.name, this.users});

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'],
      name: map['name'],
      users: map['users'] != null
          ? (map['users'] as List).map((u) => User.fromMap(u)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  @override
  String toString() =>
      'Role(id: $id, name: $name, users_count: ${users?.length ?? 0})';
}
