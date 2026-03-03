import 'package:orm/orm/tables/table.dart' as orm;
import 'package:orm/orm/tables/column.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/example/models/role.model.dart';

class UserRole {
  static const String tableName = 'user_roles';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(
        name: 'user_id',
        type: ColumnType.integer,
        isForeignKey: true,
        referenceTable: User.tableName,
        referenceColumn: 'id',
      ),
      Column(
        name: 'role_id',
        type: ColumnType.integer,
        isForeignKey: true,
        referenceTable: Role.tableName,
        referenceColumn: 'id',
      ),
    ],
  );

  final int userId;
  final int roleId;

  UserRole({required this.userId, required this.roleId});

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(userId: map['user_id'], roleId: map['role_id']);
  }

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'role_id': roleId};
  }
}
