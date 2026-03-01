// .env   en la raiz del proyecto
// flutter pub add flutter_dotenv

// env on dev or prod
// flutter:
//   assets:
//     - .env.dev
//     - .env.prod

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logs.dart';

class Env {
  static Future<void> load() async {
    if (kDebugMode) {
      lg.i(msg: 'DEBUG: Entorno de desarrollo', module: 'SYSTEM');
      await dev();
    } else {
      lg.i(msg: 'DEBUG: Entorno de producción', module: 'SYSTEM');
      await prod();
    }
  }

  static Future<void> dev() async => await dotenv.load(fileName: ".env.dev");
  static Future<void> prod() async => await dotenv.load(fileName: ".env.prod");

  static String get(String key) => dotenv.env[key] ?? '';

  static int getInt(String key) => int.parse(dotenv.env[key] ?? '0');

  static double getDouble(String key) => double.parse(dotenv.env[key] ?? '0.0');

  static bool getBool(String key) => dotenv.env[key] == 'true';
}
