import 'package:orm/example/models/role.model.dart';
import 'package:orm/example/models/user_role.model.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/orm/repository/base_repository.dart';

class RoleRepository extends BaseRepository<Role> {
  RoleRepository()
    : super(
        tableName: Role.tableName,
        fromMap: Role.fromMap,
        toMap: (role) => role.toMap(),
      );

  // --- Many to Many Assignments ---

  Future<int> assignToUser(int userId, int roleId) async {
    final client = await db;
    return await client.insert(UserRole.tableName, {
      'user_id': userId,
      'role_id': roleId,
    });
  }

  Future<int> removeFromUser(int userId, int roleId) async {
    final client = await db;
    return await client.delete(
      UserRole.tableName,
      where: 'user_id = ? AND role_id = ?',
      whereArgs: [userId, roleId],
    );
  }

  // --- Filtering ---

  Future<List<Role>> getRolesByUser(int userId) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''
      SELECT r.* FROM ${Role.tableName} r
      INNER JOIN ${UserRole.tableName} ur ON r.id = ur.role_id
      WHERE ur.user_id = ?
    ''',
      [userId],
    );
    return maps.map((m) => Role.fromMap(m)).toList();
  }

  Future<List<User>> getUsersByRole(int roleId) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      '''
      SELECT u.* FROM ${User.tableName} u
      INNER JOIN ${UserRole.tableName} ur ON u.id = ur.user_id
      WHERE ur.role_id = ?
    ''',
      [roleId],
    );
    return maps.map((m) => User.fromMap(m)).toList();
  }
}
