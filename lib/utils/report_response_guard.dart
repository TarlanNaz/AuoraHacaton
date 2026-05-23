import '../config/report_prompts.dart';
import '../services/giga_chat_service.dart';

/// Проверка ответа GigaChat: маркер «вход некорректен» → ошибка для UI.
class ReportResponseGuard {
  ReportResponseGuard._();

  static final RegExp _marker = RegExp(
    RegExp.escape(ReportPrompts.inputInvalidMarker),
  );

  static final RegExp _markerWithReason = RegExp(
    '${RegExp.escape(ReportPrompts.inputInvalidMarker)}\\s*:?\\s*(.*)',
    dotAll: true,
  );

  static bool isRejected(String response) => _marker.hasMatch(response.trim());

  static String userMessage(String response) {
    final trimmed = response.trim();
    final match = _markerWithReason.firstMatch(trimmed);
    final reason = match?.group(1)?.trim();
    if (reason != null && reason.isNotEmpty && reason.length <= 200) {
      return 'Заметки сформулированы некорректно: $reason. '
          'Дополните текст и попробуйте снова.';
    }
    return 'Заметки сформулированы некорректно: недостаточно данных для отчёта. '
        'Уточните факты, даты, контекст и тип события.';
  }

  /// Бросает [GigaChatException], если модель вернула маркер отказа.
  static void ensureValidReport(String response) {
    if (!isRejected(response)) return;
    throw GigaChatException(userMessage(response));
  }
}
