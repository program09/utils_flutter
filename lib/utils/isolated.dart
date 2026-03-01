// lib/utils/isolated.dart
// flutter pub add workmanager
// flutter pub add http

import 'package:orm/utils/env.dart';
import 'package:orm/utils/event_bridge.dart';
import 'package:orm/utils/logs.dart';
import 'package:orm/utils/queue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    lg.i(msg: 'Iniciando tarea: $task', module: 'WORKER');
    await Env.load();
    final dir = await getApplicationDocumentsDirectory();
    await Queue.init(path: dir.path);

    try {
      if (task == 'simpleTask') {
        await Future.delayed(const Duration(seconds: 3));
        await EventBridge.emitToMain(
          'syncCompleted',
          data: {
            'task': task,
            'message': 'Sincronización completada',
            'items': 25,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        await processQueue('users');
      }

      lg.i(msg: 'Tarea completada: $task', module: 'WORKER');
      return Future.value(true);
    } catch (e, stack) {
      lg.e(msg: 'Error en background: $e', module: 'WORKER', stack: stack);
      return Future.value(false);
    }
  });
}

class Task {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> one({
    required String taskId,
    required String taskName,
    Map<String, dynamic>? data,
  }) async {
    await Workmanager().registerOneOffTask(taskId, taskName, inputData: data);
  }

  static Future<void> periodic({
    required String taskId,
    required String taskName,
    Map<String, dynamic>? data,
    Duration? frequency,
  }) async {
    await Workmanager().registerPeriodicTask(
      taskId,
      taskName,
      inputData: data,
      frequency: frequency ?? const Duration(minutes: 15),
    );
  }

  // periodic with constraints
  // taskId is unique
  // taskName is the name of the task
  // data is the data to be passed to the task
  // frequency is the frequency of the task
  // constraints is the constraints of the task
  // constraints: Constraints(
  //   networkType: NetworkType.connected,      // cualquier internet
  //   networkType: NetworkType.unmetered,       // solo WiFi
  //   requiresBatteryNotLow: true,              // batería > 15%
  //   requiresCharging: false,                  // no necesita cargar
  //   requiresStorageNotLow: true,              // espacio suficiente
  //   requiresDeviceIdle: false,                // no necesita estar inactivo
  // )
  static Future<void> periodicWithConstraints({
    required String taskId,
    required String taskName,
    Map<String, dynamic>? data,
    Duration? frequency,
    Constraints? constraints,
  }) async {
    await Workmanager().registerPeriodicTask(
      taskId,
      taskName,
      inputData: data,
      frequency: frequency ?? const Duration(minutes: 15),
      constraints:
          constraints ?? Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelTask(String taskId) async {
    await Workmanager().cancelByTag(taskId);
  }
}

Future<void> processQueue(String queueName) async {
  final total = await Queue.length(queueName: queueName);
  if (total == 0) {
    lg.i(msg: 'Cola vacía, nada que sincronizar', module: 'WORKER');
    return;
  }

  lg.i(msg: 'Sincronizando $total registros...', module: 'WORKER');

  // cantidad de datos
  final count = await Queue.length(queueName: queueName);
  lg.i(msg: 'Cantidad de datos: $count', module: 'WORKER');

  int processed = 0;
  int errors = 0;

  while (await Queue.length(queueName: queueName) > 0) {
    final item = await Queue.pop(queueName: queueName);
    if (item == null) break;

    try {
      // Simular envío al servidor (API call)
      await Future.delayed(const Duration(seconds: 3));

      processed++;
      lg.s(
        msg: 'Sincronizado [$processed/$total]: ${item.toString()}',
        module: 'WORKER',
      );
    } catch (e) {
      errors++;
      // Si falla, re-agregar al final de la cola para reintentar
      await Queue.push(queueName: queueName, data: item);
      lg.e(msg: 'Error sincronizando: $e', module: 'WORKER');
    }
  }

  lg.s(
    msg: 'Sincronización completada: $processed/$total (errores: $errors)',
    module: 'WORKER',
  );
}
