import 'package:flutter/material.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/example/repository/user_repository.dart';
import 'package:orm/orm/database/db_helper.dart';
import 'package:orm/utils/alerts.dart';
import 'package:orm/utils/env.dart';
import 'package:orm/utils/event_bridge.dart';
import 'package:orm/utils/events.dart';
import 'package:orm/utils/logs.dart';
import 'package:orm/utils/queue.dart';
import 'package:orm/utils/isolated.dart';

/// ESTE ARCHIVO ES UN EJEMPLO MAESTRO QUE INTEGRA TODO EL ECOSISTEMA
/// Se puede usar como base para entender cómo interactúan los componentes.

void runMasterExample() async {
  // 1. Inicialización de Núcleo
  await lg.init(saveToFile: true);
  await Env.load();
  await Queue.init();
  EventBridge.initMainListener();

  lg.i(msg: 'Master Example Iniciado', module: 'MASTER');

  // 2. Configuración ORM con Cifrado
  final db = DbHelper();
  db.setConfig(password: Env.get('DB_PASSWORD'), tables: [User.table]);
  await db.db;

  // 3. Uso de Alertas Premium
  // Alerts.dark(context, 'Sistema Listo'); // Requiere BuildContext
}

class MasterExampleScreen extends StatefulWidget {
  const MasterExampleScreen({super.key});

  @override
  State<MasterExampleScreen> createState() => _MasterExampleScreenState();
}

class _MasterExampleScreenState extends State<MasterExampleScreen> {
  final _userRepo = UserRepository();
  String _status = 'Listo';

  @override
  void initState() {
    super.initState();

    // 4. Escuchar Eventos de Background
    EventBridge.listener('backgroundSync', (data) {
      if (!mounted) return;
      setState(() => _status = 'Sincronizado: ${data['count']}');
      Alerts.success(context, 'Sync desde Background completada');
    });
  }

  // 5. Ejemplo de Query Builder Avanzado
  Future<void> _performComplexQuery() async {
    lg.d(msg: 'Ejecutando consulta compleja...', module: 'UI');

    final results = await _userRepo
        .createBuilder()
        .select(['name', 'age'])
        .withRelations(['roles'])
        .orderBy('age', order: 'DESC')
        .where('age >= ?', [18])
        .orWhere('name LIKE ?', ['Yordi'])
        .limit(5)
        .toMapList();

    lg.s(msg: 'Resultados: ${results.toString()}', module: 'ORM');
    Alerts.info(context, 'Encontrados ${results.length} adultos');
  }

  // 6. Ejemplo de Colas Persistentes
  Future<void> _testQueue() async {
    await Queue.create(queueName: 'sync_tasks');
    await Queue.push(
      queueName: 'sync_tasks',
      data: {'action': 'upload', 'id': 99},
    );

    final count = await Queue.length(queueName: 'sync_tasks');
    Alerts.warning(context, 'Items en cola: $count');
  }

  // 7. Ejemplo de Background Task
  Future<void> _startBackgroundTask() async {
    await Task.one(
      taskId: 'manual_sync_${DateTime.now().microsecond}',
      taskName: 'simpleTask',
      data: {'user_id': 1},
    );
    Alerts.dark(context, 'Tarea de fondo enviada', title: 'WorkManager');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Integration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Estado: $_status',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 40),

              _ActionButton(
                label: 'Gestión de Usuarios (CRUD)',
                icon: Icons.people,
                color: Colors.teal,
                onPressed: () => Navigator.pushNamed(context, '/home'),
              ),

              _ActionButton(
                label: 'Categorías y Productos (Relaciones)',
                icon: Icons.category,
                color: Colors.indigo,
                onPressed: () => Navigator.pushNamed(context, '/categories'),
              ),

              _ActionButton(
                label: 'Gestión de Roles (Relación N:N)',
                icon: Icons.security,
                color: Colors.purple,
                onPressed: () => Navigator.pushNamed(context, '/roles'),
              ),

              _ActionButton(
                label: 'Query Avanzada (ORM)',
                icon: Icons.api,
                color: Colors.blue,
                onPressed: _performComplexQuery,
              ),

              _ActionButton(
                label: 'Probar Cola (Persistent)',
                icon: Icons.line_weight,
                color: Colors.orange,
                onPressed: _testQueue,
              ),

              _ActionButton(
                label: 'Ejecutar Background (Isolate)',
                icon: Icons.run_circle,
                color: Colors.purple,
                onPressed: _startBackgroundTask,
              ),

              _ActionButton(
                label: 'Emitir Evento Local',
                icon: Icons.send,
                color: Colors.green,
                onPressed: () {
                  Events.emit('localEvent', data: {'msg': 'Hola!'});
                  Alerts.success(context, 'Evento emitido localmente');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
