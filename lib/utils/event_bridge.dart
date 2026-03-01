// lib/utils/event_bridge.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:orm/utils/logs.dart';

class EventBridge {
  static const String _portName = 'event_bridge_port';
  static ReceivePort? _receivePort;

  // Stream interno para que cualquier pantalla escuche
  static final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream público para suscripciones manuales
  static Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Enviar desde BACKGROUND (Isolate de WorkManager / Compute / etc)
  static Future<void> emitToMain(
    String event, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName);

      if (sendPort != null) {
        sendPort.send({
          'event': event,
          'data': data ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        });
        lg.i(msg: '📤 Evento enviado a Main: $event', module: 'EVENT_BRIDGE');
      } else {
        lg.w(
          msg: 'App cerrada o puerto no registrado: $event',
          module: 'EVENT_BRIDGE',
        );
      }
    } catch (e) {
      lg.e(msg: 'Error emitiendo evento: $e', module: 'EVENT_BRIDGE');
    }
  }

  /// Inicializar en Main (Solo llamar una vez en el main.dart)
  static void initMainListener() {
    dispose();
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);

    _receivePort!.listen((message) {
      if (message is Map) {
        final event = message['event'] as String? ?? 'unknown';
        final data = Map<String, dynamic>.from(message['data'] as Map? ?? {});

        lg.i(msg: '📥 Evento recibido en Main: $event', module: 'EVENT_BRIDGE');

        // Notificar a todos los listeners
        _controller.add({'event': event, 'data': data});
      }
    });

    lg.i(
      msg: '👂 EventBridge: Listener principal iniciado',
      module: 'EVENT_BRIDGE',
    );
  }

  /// Escuchar eventos desde cualquier pantalla (Igual que Events.listener)
  static StreamSubscription<Map<String, dynamic>> listener(
    String eventName,
    Function(Map<String, dynamic> data) callback,
  ) {
    return _controller.stream.listen((eventData) {
      if (eventData['event'] == eventName) {
        callback(Map<String, dynamic>.from(eventData['data'] ?? {}));
      }
    });
  }

  /// Cerrar y limpiar (Llamar al cerrar la app)
  static void dispose() {
    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping(_portName);
      _receivePort!.close();
      _receivePort = null;
      lg.i(msg: '🛑 EventBridge: Listener detenido', module: 'EVENT_BRIDGE');
    }
  }
}
