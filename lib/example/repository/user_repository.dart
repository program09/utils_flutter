import 'package:orm/example/models/users.model.dart';
import 'package:orm/orm/repository/base_repository.dart';

class UserRepository extends BaseRepository<User> {
  UserRepository()
    : super(
        tableName: User.tableName,
        fromMap: User.fromMap,
        toMap: (user) => user.toMap(),
      );

  // Puedes añadir métodos específicos aquí
  Future<List<User>> getAdults() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'age >= ?',
      whereArgs: [18],
    );
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }
}
