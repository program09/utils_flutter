// lib/utils/event.dart

import 'dart:async';

/// Sistema de eventos simple y fácil de usar
class Events {
  // Singleton
  static final Events _instance = Events._internal();
  factory Events() => _instance;
  Events._internal();

  // Mapa de streams
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  // Mapa de suscripciones
  final Map<String, List<StreamSubscription>> _subscriptions = {};

  // ======================================================
  // EMITIR EVENTO
  // ======================================================

  /// Emitir un evento
  static void emit(String event, {Map<String, dynamic>? data}) {
    _instance._emit(event, data: data);
  }

  void _emit(String event, {Map<String, dynamic>? data}) {
    final controller = _controllers.putIfAbsent(
      event,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );

    controller.add({
      'event': event,
      'data': data ?? {},
      'time': DateTime.now().toIso8601String(),
    });
  }

  // ======================================================
  // ESCUCHAR EVENTO
  // ======================================================

  /// Escuchar un evento
  static StreamSubscription<Map<String, dynamic>> listener(
    String event,
    Function(Map<String, dynamic>) callback,
  ) {
    return _instance._listener(event, callback);
  }

  StreamSubscription<Map<String, dynamic>> _listener(
    String event,
    Function(Map<String, dynamic>) callback,
  ) {
    final controller = _controllers.putIfAbsent(
      event,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );

    final subscription = controller.stream.listen((eventData) {
      callback(eventData);
    });

    _subscriptions.putIfAbsent(event, () => []).add(subscription);
    return subscription;
  }

  // ======================================================
  // ESCUCHAR UNA SOLA VEZ
  // ======================================================

  /// Escuchar un evento una sola vez
  static StreamSubscription<Map<String, dynamic>> once(
    String event,
    Function(Map<String, dynamic>) callback,
  ) {
    return _instance._once(event, callback);
  }

  StreamSubscription<Map<String, dynamic>> _once(
    String event,
    Function(Map<String, dynamic>) callback,
  ) {
    final controller = _controllers.putIfAbsent(
      event,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );

    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = controller.stream.listen((eventData) {
      callback(eventData);
      subscription.cancel();
      _removeSubscription(event, subscription);
    });

    _subscriptions.putIfAbsent(event, () => []).add(subscription);
    return subscription;
  }

  // ======================================================
  // ELIMINAR LISTENERS
  // ======================================================

  /// Eliminar todos los listeners de un evento
  static void off(String event) {
    _instance._off(event);
  }

  void _off(String event) {
    if (_subscriptions.containsKey(event)) {
      for (var sub in _subscriptions[event]!) {
        sub.cancel();
      }
      _subscriptions.remove(event);
    }

    if (_controllers.containsKey(event)) {
      _controllers[event]!.close();
      _controllers.remove(event);
    }
  }

  /// Eliminar todos los eventos y listeners
  static void clear() {
    _instance._clear();
  }

  void _clear() {
    for (var subs in _subscriptions.values) {
      for (var sub in subs) {
        sub.cancel();
      }
    }

    for (var controller in _controllers.values) {
      controller.close();
    }

    _subscriptions.clear();
    _controllers.clear();
  }

  void _removeSubscription(String event, StreamSubscription subscription) {
    if (_subscriptions.containsKey(event)) {
      _subscriptions[event]!.remove(subscription);
    }
  }
}

// Instancia global para fácil acceso
final event = Events();
