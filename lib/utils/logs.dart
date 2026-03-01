// PATH PROVIDER: https://pub.dev/packages/path_provider
// flutter pub add path_provider

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path_provider/path_provider.dart';

enum LogLevel { success, debug, info, warning, error, fatal }

class FastLogger {
  static final FastLogger _instance = FastLogger._internal();
  factory FastLogger() => _instance;

  FastLogger._internal() {
    _writeController.stream.listen(_processWriteQueue);
  }

  bool debugMode = kDebugMode;
  bool _saveToFile = false;
  File? _logFile;
  static const int _maxFileSize = 5 * 1024 * 1024;
  final List<String> _writeQueue = [];
  bool _isWriting = false;
  final _writeController = StreamController<String>.broadcast();

  static const _reset = '\x1B[0m';
  static const _orange = '\x1B[38;5;208m';
  static const _green = '\x1B[32m';
  static const _blue = '\x1B[34m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _magenta = '\x1B[35m';

  Future<void> init({bool saveToFile = false}) async {
    _saveToFile = saveToFile;
    if (_saveToFile) {
      await _initLogFile();
    }
  }

  Future<void> _initLogFile() async {
    try {
      final directory = await getExternalStorageDirectory();
      final logDir = Directory('${directory?.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final d = now.day.toString().padLeft(2, '0');
      final m = now.month.toString().padLeft(2, '0');
      final y = now.year;
      final h = now.hour.toString().padLeft(2, '0');

      final fileName = 'app_D${d}_${m}_${y}___H$h.log';
      _logFile = File('${logDir.path}/$fileName');

      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxFileSize) {
          final backupFile = File('${logDir.path}/$fileName.bak');
          await _logFile!.copy(backupFile.path);
          await _logFile!.writeAsString('');
        }
      }
    } catch (e) {
      // Silencioso
    }
  }

  void _log(
    LogLevel level,
    String message, [
    String? module,
    StackTrace? stack,
  ]) {
    final color = _getColor(level);
    final label = level.toString().split('.').last.toUpperCase();

    final timeStr = _getCurrentTime();
    final moduleStr = (module != null && module.isNotEmpty)
        ? '[$module]'
        : '[$label]';
    final logMessage = '$timeStr $moduleStr => $message';

    if (debugMode) {
      final buffer = StringBuffer();

      if (module != null && module.isNotEmpty) {
        buffer.write('$color[$module]$_reset');
      } else {
        buffer.write('$color[$label]$_reset');
      }

      buffer.write('$color => $message$_reset');
      print(buffer.toString());

      if (stack != null &&
          (level == LogLevel.error || level == LogLevel.fatal)) {
        print(
          '$color════════════════════════════════════════════════════════════════════════════════════════════════════$_reset',
        );

        final stackLines = stack.toString().split('\n').take(3);
        for (var line in stackLines) {
          print('$color  $line$_reset');
        }

        print(
          '$color════════════════════════════════════════════════════════════════════════════════════════════════════$_reset',
        );
      }
      print('');
    }

    if (_saveToFile && _logFile != null) {
      String fileMessage = logMessage;
      if (stack != null &&
          (level == LogLevel.error || level == LogLevel.fatal)) {
        final stackLines = stack.toString().split('\n').take(2).join(' | ');
        fileMessage += '\n  Stack: $stackLines';
      }

      _writeQueue.add(fileMessage);
      _writeController.add('');
    }
  }

  Future<void> _processWriteQueue(_) async {
    if (_isWriting || _writeQueue.isEmpty || _logFile == null) return;

    _isWriting = true;

    while (_writeQueue.isNotEmpty) {
      final line = _writeQueue.removeAt(0);
      try {
        await _logFile!.writeAsString('$line\n', mode: FileMode.append);
      } catch (e) {
        // Ignorar error
      }
    }

    _isWriting = false;
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  String _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.success:
        return _green;
      case LogLevel.debug:
        return _orange;
      case LogLevel.info:
        return _blue;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
      case LogLevel.fatal:
        return _magenta;
    }
  }

  void s({String? module, required String msg}) =>
      _log(LogLevel.success, msg, module);
  void d({String? module, required String msg}) =>
      _log(LogLevel.debug, msg, module);
  void i({String? module, required String msg}) =>
      _log(LogLevel.info, msg, module);
  void w({String? module, required String msg}) =>
      _log(LogLevel.warning, msg, module);

  void e({String? module, required String msg, StackTrace? stack}) =>
      _log(LogLevel.error, msg, module, stack);
  void f({String? module, required String msg, StackTrace? stack}) =>
      _log(LogLevel.fatal, msg, module, stack);
}

final lg = FastLogger();
