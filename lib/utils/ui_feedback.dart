import 'package:flutter/material.dart';

/// Единая точка для SnackBar — любое действие пользователя получает отклик.
class UiFeedback {
  UiFeedback._();

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: scheme.onInverseSurface, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor ?? scheme.inverseSurface,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  /// Требование ТЗ: при сохранении оффлайн — именно этот текст.
  static void draftSavedLocally(BuildContext context) {
    show(
      context,
      message: 'Черновик сохранен локально',
      icon: Icons.save_outlined,
    );
  }

  static void reportSaved(BuildContext context) {
    show(
      context,
      message: 'Отчёт сохранён в локальный кэш',
      icon: Icons.check_circle_outline,
    );
  }

  static void copied(BuildContext context) {
    show(
      context,
      message: 'Скопировано в буфер обмена',
      icon: Icons.copy_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, icon: Icons.info_outline);
  }

  static void warning(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: scheme.errorContainer,
    );
  }
}
