import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info, dark }

class Alerts {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AlertType type = AlertType.dark,
    Duration duration = const Duration(seconds: 3),
    bool isFloating = true,
  }) {
    if (!context.mounted) return;

    final color = _getColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (type != AlertType.dark) ...[
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 15),
            ],

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: isFloating
            ? SnackBarBehavior.floating
            : SnackBarBehavior.fixed,
        elevation: 0,
        shape: isFloating
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            : null,
        margin: isFloating ? const EdgeInsets.all(15) : null,
      ),
    );
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: AlertType.success);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: AlertType.error);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: AlertType.warning);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: AlertType.info);

  static void dark(BuildContext context, String message, {String? title}) =>
      show(
        context,
        message: message,
        title: title,
        type: AlertType.dark,
        isFloating: false,
      );

  static Color _getColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return const Color.fromARGB(183, 75, 199, 81);
      case AlertType.error:
        return const Color.fromARGB(202, 228, 88, 88);
      case AlertType.warning:
        return const Color.fromARGB(217, 248, 150, 70);
      case AlertType.info:
        return const Color.fromARGB(178, 62, 140, 230);
      case AlertType.dark:
        return const Color.fromARGB(153, 0, 0, 0);
    }
  }

  static IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.info:
        return Icons.info_rounded;
      case AlertType.dark:
        return Icons.dark_mode_rounded;
    }
  }
}
