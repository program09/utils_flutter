// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orm/home.dart';
import 'package:orm/example/controllers/database_helper.dart';
import 'package:orm/example/complete_example.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/example/screens/category_list_screen.dart';
import 'package:orm/example/screens/role_list_screen.dart';
import 'package:orm/utils/alerts.dart';
import 'package:orm/utils/env.dart';
import 'package:orm/utils/event_bridge.dart';
import 'package:orm/utils/events.dart';
import 'package:orm/utils/logs.dart';
import 'package:orm/utils/permissions.dart';
import 'package:orm/utils/queue.dart';
import 'package:orm/utils/isolated.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. WorkManager
  await Workmanager().initialize(callbackDispatcher);

  // 2. Inicializar logger
  await lg.init(saveToFile: true);

  // 3. Logs de prueba
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

  // 4. Permisos
  await Perm.getStorage();

  // 5. Variables de entorno
  await Env.load();

  // 6. Queue
  await Queue.init();

  // 7. Cargar datos
  await loadData();

  // 8. INICIALIZAR LISTENER PARA EVENTOS DEL BACKGROUND (IsolateNameServer)
  EventBridge.initMainListener();

  // 9. Inicializar base de datos ORM de Ejemplo
  await ExampleDatabase.init();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Para mostrar feedback en la UI
  String _lastEvent = 'Esperando eventos...';
  StreamSubscription? _bridgeSub;

  @override
  void initState() {
    super.initState();

    // Opcional: Escuchar de forma global para logs o feedback persistente
    _bridgeSub = EventBridge.listener('syncCompleted', (data) {
      lg.i(msg: 'Sincronización detectada en Root', module: 'MAIN');
      // Si necesitas enviarlo a un stream global manual:
      setState(() {
        _lastEvent = '📬 ${data['event']}: ${data['data']?['message'] ?? ''}';
      });

      // Mostrar SnackBar usando el contexto del scaffold
      _showSnackBar(context, data);
    });
  }

  @override
  void dispose() {
    _bridgeSub?.cancel(); // Limpiar suscripción
    EventBridge.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, Map eventData) {
    final isError = eventData['event'] == 'syncError';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(eventData['data']?['message'] ?? 'Evento recibido'),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(lastEvent: _lastEvent, onEvent: () => setState(() {})),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/categories': (context) => const CategoryListScreen(),
        '/master': (context) => const MasterExampleScreen(),
        '/roles': (context) => const RoleListScreen(),
      },
    );
  }
}

// Página principal
class HomePage extends StatelessWidget {
  final String lastEvent;
  final VoidCallback onEvent;

  const HomePage({super.key, required this.lastEvent, required this.onEvent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostrar último evento
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(lastEvent, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            const Text('Hello World!'),
            const SizedBox(height: 100),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/master'),

              child: const Text(
                'FULL APP FLOW (Master)',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                Navigator.pushNamed(context, '/home');
                await Future.delayed(const Duration(seconds: 3));
                Events.emit(
                  'syncCompleted',
                  data: {'message': 'Sincronización completada'},
                );
              },
              child: const Text('Event to Home'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Alerts.dark(context, 'Tarea registrada', title: 'Éxito');
                // // Registrar tarea
                Workmanager().registerOneOffTask(
                  "task-id",
                  "simpleTask",
                  inputData: User(id: 19999, name: 'Yordi', age: 25).toMap(),
                );

                lg.s(msg: '✅ Tarea registrada', module: 'UI');
              },
              child: const Text('Register Task workmanager'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Cancelar tarea
                await Workmanager().cancelByUniqueName('task-id');
                lg.s(msg: '🛑 Tarea cancelada', module: 'UI');

                // Mostrar SnackBar con el contexto
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarea cancelada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Task'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> loadData() async {
  await Queue.create(queueName: 'users');

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
    format: User.fromMap,
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
      format: User.fromMap,
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

  // clean queue
  await Queue.clean(queueName: 'users');
  lg.s(msg: 'Queue cleaned', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // close queue
  await Queue.close(queueName: 'users');
  lg.s(msg: 'Queue closed', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );

  // close all queues
  await Queue.closeAll();
  lg.s(msg: 'All queues closed', module: 'AUTH');
  lg.w(
    msg: 'Length of users: ${await Queue.length(queueName: 'users')}',
    module: 'AUTH',
  );
}
