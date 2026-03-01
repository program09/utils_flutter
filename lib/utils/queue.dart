// lib/core/queue.dart

// flutter pub add hive
// flutter pub add path_provider

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class Queue {
  // Cache de cajas abiertas para no abrir repetidamente
  static final Map<String, Box> _openBoxes = {};

  static Future<void> init() async {
    var path = await getApplicationDocumentsDirectory();
    Hive.init(path.path);
  }

  // Abrir caja (privado - maneja cache)
  static Future<Box> _getQueue(String queueName) async {
    if (_openBoxes.containsKey(queueName) && _openBoxes[queueName]!.isOpen) {
      return _openBoxes[queueName]!;
    }

    final box = await Hive.openBox(queueName);
    _openBoxes[queueName] = box;
    return box;
  }

  // Crear cola (abrir es suficiente)
  static Future<void> createQueue({required String queueName}) async {
    await _getQueue(queueName);
  }

  // Obtener caja (pública)
  static Future<Box> getQueue(String queueName) async {
    return await _getQueue(queueName);
  }

  // Cerrar caja específica
  static Future<void> closeQueue(String queueName) async {
    if (_openBoxes.containsKey(queueName)) {
      await _openBoxes[queueName]!.close();
      _openBoxes.remove(queueName);
    }
  }

  // Cerrar todas las cajas
  static Future<void> closeAllQueues() async {
    for (var entry in _openBoxes.entries) {
      await entry.value.close();
    }
    _openBoxes.clear();
  }

  // Agregar datos al final (si existe, lo elimina y agrega al final)
  static Future<void> push({
    required String queueName,
    required Map<String, dynamic> data,
    dynamic id,
  }) async {
    final box = await _getQueue(queueName);
    final key = id ?? data['id'];
    if (box.containsKey(key)) {
      await box.delete(key);
    }
    await box.put(key, data);
  }

  // Obtener el primero y eliminarlo (como cola FIFO)
  static Future<Map<String, dynamic>?> pop({required String queueName}) async {
    final box = await _getQueue(queueName);
    if (box.isEmpty) return null;

    final firstKey = box.keys.first;
    final item = Map<String, dynamic>.from(box.get(firstKey));
    await box.delete(firstKey);
    return item;
  }

  // Ver primero sin eliminar
  static Future<Map<String, dynamic>?> peek({required String queueName}) async {
    final box = await _getQueue(queueName);
    if (box.isEmpty) return null;

    final firstKey = box.keys.first;
    return Map<String, dynamic>.from(box.get(firstKey));
  }

  // Actualizar datos
  // si no existe, lo crea
  // si existe, lo actualiza
  // data = {id: 1, name: 'Yordi', age: 25}
  static Future<bool> update({
    required String queueName,
    required dynamic id,
    required Map<String, dynamic> data,
  }) async {
    final exist = await exists(queueName: queueName, id: id);
    if (exist) {
      final box = await _getQueue(queueName);
      data['id'] = id; // siempre mantener el id en el data
      await box.put(id, data);
      return true;
    }
    return false;
  }

  // Obtener por ID (retorna Map)
  static Future<Map<String, dynamic>> get({
    required String queueName,
    required dynamic id,
  }) async {
    final box = await _getQueue(queueName);
    final item = box.get(id);
    if (item == null) return {};
    return Map<String, dynamic>.from(item);
  }

  // Obtener por ID como objeto T
  // Ejemplo: final user = await Queue.getAs<User>(queueName: 'users', id: 1, fromJson: User.fromJson);
  static Future<T?> getAs<T>({
    required String queueName,
    required dynamic id,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final box = await _getQueue(queueName);
    final item = box.get(id);
    if (item == null) return null;
    return fromJson(Map<String, dynamic>.from(item));
  }

  // Eliminar por ID
  static Future<void> delete({
    required String queueName,
    required dynamic id,
  }) async {
    final box = await _getQueue(queueName);
    await box.delete(id);
  }

  // Obtener todos
  static Future<List<Map<String, dynamic>>> getAll({
    required String queueName,
  }) async {
    final box = await _getQueue(queueName);
    return box.values.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Obtener todos como objetos T
  static Future<List<T>> getAllAs<T>({
    required String queueName,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final box = await _getQueue(queueName);
    return box.values
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Limpiar cola
  static Future<bool> clear({required String queueName}) async {
    final box = await _getQueue(queueName);
    await box.clear();
    return true;
  }

  // Longitud de la cola
  static Future<int> length({required String queueName}) async {
    final box = await _getQueue(queueName);
    return box.length;
  }

  // Verificar si existe
  static Future<bool> exists({
    required String queueName,
    required dynamic id,
  }) async {
    final box = await _getQueue(queueName);
    return box.containsKey(id);
  }

  // Obtener múltiples por IDs
  static Future<List<Map<String, dynamic>>> getMany({
    required String queueName,
    required List<dynamic> ids,
  }) async {
    final box = await _getQueue(queueName);
    final results = <Map<String, dynamic>>[];

    for (var id in ids) {
      final item = box.get(id);
      if (item != null) {
        results.add(Map<String, dynamic>.from(item));
      }
    }

    return results;
  }
}
