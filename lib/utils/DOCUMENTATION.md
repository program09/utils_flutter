# Documentación Completa de Utilidades (ORM Project)

Este documento detalla el funcionamiento, configuración y ejemplos de uso de todas las utilidades del núcleo del proyecto.

---

## 1. Variables de Entorno (`env.dart`)
Maneja la carga y lectura de configuraciones desde archivos `.env`.

### Configuración
Asegúrate de tener los archivos `.env.dev` o `.env.prod` en la raíz y registrados en `pubspec.yaml`.

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env.dev
    - .env.prod
```



### Uso
```dart
import 'package:orm/utils/env.dart';

void main() async {
  // 1. Cargar variables (obligatorio al inicio)
  await Env.load();

  // 2. Leer un valor
  String api = Env.get('API'); 
  int port = Env.getInt('PORT');
  bool debug = Env.getBool('DEBUG');
  double timeout = Env.getDouble('TIMEOUT');
}
```

---

## 2. Sistema de Logs (`logs.dart`)
Sistema avanzado de registro con colores por consola y guardado automático en archivos `.log`.

### Niveles y Colores
*   **Success (`lg.s`)**: Verde - Para operaciones exitosas.
*   **Info (`lg.i`)**: Azul - Seguimiento general.
*   **Debug (`lg.d`)**: Gris - Detalles técnicos.
*   **Warning (`lg.w`)**: Amarillo - Alertas no críticas.
*   **Error (`lg.e`)**: Rojo - Fallos controlados.
*   **Fatal (`lg.f`)**: Fondo Rojo - Errores que detienen la app.

### Uso
```dart
import 'package:orm/utils/logs.dart';

// Inicializar (opcionalmente guardar en archivo)
await lg.init(saveToFile: true);

// msg: Mensaje a mostrar
// module: Módulo que genera el mensaje (opcional)
// stack: StackTrace del error (opcional)

lg.s(msg: 'Usuario autenticado', module: 'AUTH');
lg.e(msg: 'Error 404', module: 'API', stack: StackTrace.current);
```

---

## 3. Eventos Internos (`events.dart`)
Sistema de "Bus de Eventos" para comunicación dentro del mismo Isolate (UI).

### **⚠️ IMPORTANTE: Gestión de Memoria**
Para evitar "Memory Leaks", **siempre** guarda la suscripción y cancélala al destruir el Widget.

### Uso en Widgets
```dart
import 'dart:async';
import 'package:orm/utils/events.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // 1. Suscribirse
    _sub = Events.listener('update_ui', (data) {
      if (mounted) setState(() { /* ... */ });
    });
  }

  @override
  void dispose() {
    // 2. IMPORTANTE: Cancelar
    _sub?.cancel(); 
    super.dispose();
  }
}

// 3. Emitir desde cualquier parte de la app
Events.emit('update_ui', data: {'status': 'done'});
```

---

## 4. EventBridge (`event_bridge.dart`)
Comunicación directa entre el **Background Isolate** (WorkManager) y la **UI Principal** usando memoria compartida (`IsolateNameServer`).

### Uso
```dart
// --- EN main.dart ---
// 1. Registrar el puente (solo una vez)
EventBridge.initMainListener();

// --- EN CUALQUIER PANTALLA ---
StreamSubscription? _bridgeSub;
_bridgeSub = EventBridge.listener('syncCompleted', (data) {
  print('Llegó desde background: $data');
});

// --- EN isolated.dart (Background) ---
await EventBridge.emitToMain('syncCompleted', data: {'items': 50});
```

---

## 5. Background Tasks (`isolated.dart`)
Gestión de tareas asíncronas que se ejecutan incluso si la app está cerrada o en segundo plano. Basado en `WorkManager`.

### Registro de Tareas
```dart
import 'package:orm/utils/isolated.dart';

// Tarea única (Ej: Subir una foto ahora mismo)
await Task.one(
  taskId: 'upload_1',
  taskName: 'simpleTask',
  data: {'id': 123}
);

// Tarea periódica (Ej: Sincronizar cada 15 min)
await Task.periodic(
  taskId: 'sync_db',
  taskName: 'syncServer',
  frequency: 15 * 60 * 1000, // 15 minutos en milisegundos
  data: {'id': 123}
);

// Tarea periodica con constraints
await Task.periodicWithConstraints(
  taskId: 'sync_db',
  taskName: 'syncServer',
  frequency: 15 * 60 * 1000, // 15 minutos en milisegundos
  data: {'id': 123},
  constraints: {
    networkType: NetworkType.connected, // Solo cuando hay internet -> NetworkType.connected, NetworkType.unmetered, NetworkType.not_required
    requiresBatteryNotLow: true, // Solo cuando la batería no está baja -> true, false
    requiresStorageNotLow: true, // Solo cuando el almacenamiento no está bajo -> true, false
    requiresCharging: false, // No requiere que el dispositivo esté cargando -> true, false
    requiresDeviceIdle: false, // No requiere que el dispositivo esté inactivo -> true, false
  }
);
```

---

## 6. Colas Persistentes (`queue.dart`)
Almacenamiento seguro de datos en disco (Hive) para evitar pérdida de información si no hay internet.

### Uso
```dart
import 'package:orm/utils/queue.dart';

void main() async {
  // 1. Iniciar colas (obligatorio al inicio)
  await Queue.init();
}

// 1. Asegurar que la cola existe
await Queue.create(queueName: 'pending_sales');

// 2. Cerrar una cola
await Queue.close(queueName: 'pending_sales');

// 3. Cerrar todas las colas
await Queue.closeAll();

// 4. Guardar datos (Persistente)
await Queue.push(queueName: 'pending_sales', data: {'total': 150.0});

// 5. Procesar y eliminar (FIFO)
final item = await Queue.pop(queueName: 'pending_sales');

// 6. Ver el primero (sin borrar)
final next = await Queue.peek(queueName: 'pending_sales');

// 7. Update data in queue
await Queue.update(queueName: 'pending_sales', id: 1, data: {'id': 1, 'total': 200.0});

// 8. Get data by id
final item = await Queue.get(queueName: 'pending_sales', id: 1);

// 9. Get many data by id
final items = await Queue.getMany(queueName: 'pending_sales', ids: [1, 2, 3]);

// 10. Get data as object  
final userAsObject = await Queue.getAs<User>(
                              queueName: 'users',
                              id: 4467,
                              format: User.fromMap,
                            );

// 11. Get all data
final allItems = await Queue.getAll(queueName: 'pending_sales');

// 12. Get all data as objects
final allUsersAsObjects = await Queue.getAllAs<User>(
                                  queueName: 'users',
                                  format: User.fromMap,
                                );

// 13. Clean queue
await Queue.clean(queueName: 'pending_sales');

// 14. exists item by ID
await Queue.exists(queueName: 'pending_sales', id: 1);

// 15. Total de datos en espera
int pendientes = await Queue.length(queueName: 'pending_sales');

// 16. Eliminar item de la cola por ID 
await Queue.delete(queueName: 'pending_sales', id: 1);

// 17. Get cola instance
final cola = await Queue.getQueue(queueName: 'pending_sales');
```

---

## 7. Permisos (`permissions.dart`)
Gestión simplificada de permisos del sistema operativo.

### Uso
```dart
import 'package:orm/utils/permissions.dart';

// Solicitar Storage
if (await Perm.getStorage()) {
  print('Acceso concedido a archivos');
}

// Solicitar Ubicación
bool hasLocation = await Perm.getLocation();
```

---

### **Consejos de Rendimiento**
1.  **Eventos**: Usa `Events.once` si solo necesitas esperar el evento una sola vez (se auto-cancela).
2.  **Colas**: No guardes objetos pesados (imágenes en base64) en la cola; guarda la ruta del archivo.
3.  **Logs**: En producción, inicializa `lg.init(saveToFile: false)` para no llenar el disco del usuario innecesariamente.
