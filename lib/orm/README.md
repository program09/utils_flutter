# 🚀 ORM Core Documentation

Bienvenido al núcleo del **Antigravity ORM**. Este es un motor ligero, desacoplado y potente para manejar SQLite (con soporte nativo para cifrado SQLCipher) en Flutter.

## 📌 Filosofía
- **Desacoplamiento Total**: El núcleo no conoce tu lógica de negocio.
- **Configuración Inyectable**: Tú decides nombres de DB, versiones y esquemas desde tu implementación.
- **Migraciones Indoloras**: Soporte avanzado para añadir, eliminar o modificar columnas sin perder datos.

---

## 🛠 1. Configuración Inicial

El ORM se configura a través del `DbHelper`. No se requiere configuración global pesada.

### `DbHelper.setConfig`
Debes configurar el ORM antes de realizar cualquier consulta. Se recomienda hacerlo en un controlador de base de datos en tu capa de aplicación.

```dart
final db = DbHelper();
db.setConfig(
  name: 'mi_app.db',           // Nombre del archivo
  version: 1,                  // Versión para disparar migraciones
  password: 'clave_segura',    // Opcional: Activa SQLCipher
  tables: [                    // Registro de modelos
    User.table,
    Post.table,
  ],
);
```

---

## 📐 2. Definición de Modelos

Cada modelo debe definir su estructura de tabla usando las clases `Table` y `Column`.

### Ejemplo de Modelo
```dart
class User {
  static const String tableName = 'users';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      Column(name: 'name', type: ColumnType.text),
      Column(name: 'email', type: ColumnType.text, isNullable: true),
    ],
  );
  
  // Tu clase Dart estándar...
}
```

### Tipos de Columnas Soportados
- `ColumnType.integer`
- `ColumnType.text`
- `ColumnType.real` (double)
- `ColumnType.blob`
- `ColumnType.bool` (se guarda como 0/1)
- `ColumnType.dateTime` (se guarda como timestamp)

---

## 🏗 3. Repositorios

Usa `BaseRepository<T>` para obtener operaciones CRUD automáticas.

```dart
class UserRepository extends BaseRepository<User> {
  UserRepository() : super(
    tableName: User.tableName,
    fromMap: User.fromMap,
  );
}
```

### Métodos Disponibles:
- `getAll()`: Lista completa.
- `getById(id)`: Registro único.
- `insert(entity)`: Creación.
- `update(entity, id)`: Actualización.
- `delete(id)`: Eliminación.

---

## 🔍 4. Query Builder (Relaciones & Eager Loading)

Para consultas complejas y carga automática de relaciones, usa el `QueryBuilder`.

```dart
final repo = UserRepository();
final users = await repo.createBuilder()
    .select(['id', 'name', 'email'])
    .withRelations(['role']) // Carga automática de la relación 'role'
    .where('age > ?', [18])
    .toList();

print(users.first.role?.name); // ¡Datos cargados!
```

### Tipos de Relaciones Soportadas:
- **`belongsTo`**: Muchos a uno (ej: Usuario pertenece a un Rol).
- **`hasMany`**: Uno a muchos (ej: Categoría tiene muchos Productos).
- **`manyToMany`**: Muchos a muchos (ej: Estudiantes y Cursos) usando tablas pivote.

El motor utiliza cláusulas `IN` para evitar el problema de N+1, realizando solo una consulta adicional por cada tipo de relación solicitada.

---

## 🔄 5. Migraciones Avanzadas (Sin pérdida de datos)

Esta es la funcionalidad estrella. El ORM gestiona los cambios de esquema automáticamente cuando incrementas la `version`.

### Comportamiento Automático:
- **Añadir Columna**: Se usa `ALTER TABLE`.
- **Eliminar Columna**: El ORM detecta que ya no está en el modelo y reconstruye la tabla.
- **Cambiar Tipo/Restricción**: Si cambias un tipo o PK, el ORM realiza una **Safe Migration** (Tabla temporal -> Copia de datos -> Renombrado).

> [!IMPORTANT]
> Nunca pierdas tus datos. El motor de sincronización de Antigravity asegura que los datos existentes se muevan al nuevo esquema automáticamente.

---

## 🔐 6. Seguridad (SQLCipher)

Si proporcionas un `password` en `setConfig`, el ORM automáticamente:
1. Usa `sqflite_sqlcipher`.
2. Encripta el archivo de base de datos a nivel de disco.
3. Si el archivo ya existe y la clave es incorrecta, la conexión fallará (protección de datos).

---

## ⚡ 7. Observar Cambios (Watchers)

Usa `.watch()` o `.watchMapList()` para obtener un **Stream** que se actualiza en tiempo real cuando los datos cambian.

```dart
// En tu Repositorio
repository.watchAll().listen((users) {
  print("¡La base de datos cambió!");
});

// Con QueryBuilder para filtros específicos
userRepo.createBuilder()
  .where('age > ?', [18])
  .watch()
  .listen((adults) => updateUI(adults));
```

---

## 📂 Estructura del Core
- `lib/orm/database/`: Motor de conexión y migraciones.
- `lib/orm/query_builder/`: Generador de SQL dinámico.
- `lib/orm/repository/`: Abstracción CRUD.
- `lib/orm/tables/`: Definición de esquemas.

---

## 💡 Mejores Prácticas
1. **Modelos Limpios**: Mantén la definición `Table` dentro del modelo para que el esquema viva con los datos.
2. **Controlador de Ejemplo**: Mira `lib/example/controllers/database_helper.dart` para ver cómo centralizar la configuración.
3. **Versiones**: Incrementa la versión de la DB cada vez que modifiques una columna para que el `onUpgrade` dispare la sincronización.
