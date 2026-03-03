import 'package:orm/orm/database/db_helper.dart';
import 'package:orm/example/models/users.model.dart';
import 'package:orm/example/models/category.model.dart';
import 'package:orm/example/models/product.model.dart';
import 'package:orm/example/models/role.model.dart';
import 'package:orm/example/models/user_role.model.dart';
import 'package:orm/utils/logs.dart';

class ExampleDatabase {
  static final ExampleDatabase _instance = ExampleDatabase._internal();
  factory ExampleDatabase() => _instance;
  ExampleDatabase._internal();

  /// Inicializa la base de datos con todas las tablas del ejemplo
  static Future<void> init() async {
    final db = DbHelper();

    lg.i(
      msg: 'Inicializando base de datos de ejemplo...',
      module: 'EXAMPLE_DB',
    );

    // 1. Configurar todo desde el Example (fuera del core)
    db.setConfig(
      name: 'example_app.db',
      version: 7, // Incrementado para añadir columna email
      password: 'super_secret_password_123',
      tables: [
        User.table,
        Category.table,
        Product.table,
        Role.table,
        UserRole.table,
      ],
    );

    // 2. Abrir la conexión
    await db.db;

    lg.s(msg: 'Base de datos de ejemplo lista.', module: 'EXAMPLE_DB');
  }
}
