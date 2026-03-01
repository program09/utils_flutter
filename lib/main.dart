import 'package:flutter/material.dart';
import 'package:orm/models/user.dart';
import 'package:orm/utils/env.dart';
import 'package:orm/utils/logs.dart';
import 'package:orm/utils/permissions.dart';
import 'package:orm/utils/queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar logger
  await lg.init(saveToFile: true);
  // Probar TODOS los niveles
  lg.s(msg: 'SUCCESS: Usuario registrado', module: 'AUTH');
  lg.d(msg: 'DEBUG: Variable x = 42', module: 'AUTH');
  lg.i(msg: 'INFO: App iniciada', module: 'SYSTEM');
  lg.w(msg: 'WARNING: API lenta', module: 'API');

  try {
    throw Exception('Error prueba');
  } catch (e, s) {
    lg.e(msg: 'ERROR: Error de prueba', module: 'AUTH', stack: s);
    lg.f(msg: 'FATAL: Error crítico', module: 'SYSTEM', stack: s);
  }

  await Perm.getStorage();
  // await Perm.getCamera();
  // await Perm.getLocation();
  // await Perm.getPhotos();
  // await Perm.getManageExternalStorage();

  await Env.load();

  await Queue.init();

  loadData();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}

void loadData() async {
  await Queue.createQueue(queueName: 'users');

  await Queue.push(
    queueName: 'users',
    data: {'id': 1, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 2, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 3, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 4, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 5, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 6, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 7, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 8, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 9, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 10, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 11, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 12, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 13, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 14, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 15, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 16, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 17, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 18, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 19, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 20, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 21, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 22, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 23, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 24, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 25, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 26, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 27, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 28, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 29, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 30, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 31, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 32, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 33, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 34, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 35, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 36, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 37, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 38, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 39, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 40, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 41, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 42, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 43, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 4467, 'name': 'Yordi', 'age': 25},
  );

  await Queue.push(
    queueName: 'users',
    data: {'id': 4556, 'name': 'Yordi', 'age': 25},
  );

  // get all users
  final users = await Queue.getAll(queueName: 'users');
  lg.s(msg: 'All users: ${users.toString()}', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // get all users as objects
  final allUsersAsObjects = await Queue.getAllAs<User>(
    queueName: 'users',
    fromJson: User.fromMap,
  );
  lg.s(
    msg: 'All users as objects: ${allUsersAsObjects.toString()}',
    module: 'AUTH',
  );

  // get user by id
  final user = await Queue.get(queueName: 'users', id: 4467);
  lg.s(msg: 'User by id 4467: ${user.toString()}', module: 'AUTH');

  try {
    // get user by id as object
    final userAsObject = await Queue.getAs<User>(
      queueName: 'users',
      id: 4467,
      fromJson: User.fromMap,
    );
    lg.s(
      msg: 'User by id 4467 as object: ${userAsObject.toString()}',
      module: 'AUTH',
    );
  } catch (e) {
    lg.e(
      msg: 'Error getting user by id as object: ${e.toString()}',
      module: 'AUTH',
    );
  }

  // update user
  await Queue.update(
    queueName: 'users',
    id: 1,
    data: {'name': 'Yordi', 'age': 26},
  );
  lg.s(
    msg: 'User updated: ${await Queue.get(queueName: 'users', id: 1)}',
    module: 'AUTH',
  );

  // delete user
  await Queue.delete(queueName: 'users', id: 1);
  lg.s(
    msg: 'User deleted: ${await Queue.get(queueName: 'users', id: 1)}',
    module: 'AUTH',
  );
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // pop user
  final poppedUser = await Queue.pop(queueName: 'users');
  lg.s(msg: 'User popped: ${poppedUser.toString()}', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // peek user
  final peekedUser = await Queue.peek(queueName: 'users');
  lg.s(msg: 'User peeked: ${peekedUser.toString()}', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // length of queue
  final length = await Queue.length(queueName: 'users');
  lg.s(msg: 'Length of queue: ${length.toString()}', module: 'AUTH');

  // exists user
  final exists = await Queue.exists(queueName: 'users', id: 1);
  lg.s(msg: 'User exists: ${exists.toString()}', module: 'AUTH');

  // get many users
  final manyUsers = await Queue.getMany(queueName: 'users', ids: [1, 2, 3]);
  lg.s(msg: 'Many users: ${manyUsers.toString()}', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // clear queue
  await Queue.clear(queueName: 'users');
  lg.s(
    msg: 'All users: ${await Queue.getAll(queueName: 'users')}',
    module: 'AUTH',
  );
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );
}
