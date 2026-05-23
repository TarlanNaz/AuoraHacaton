/// Результат валидации пользовательского ввода.
///
/// Если [isValid] == false, в [error] лежит человекочитаемое сообщение,
/// которое можно показать в UI. В [sanitized] — очищенная строка,
/// безопасная для отправки во внешний API.
class ValidationResult {
  final bool isValid;
  final String sanitized;
  final String? error;

  const ValidationResult.ok(this.sanitized)
      : isValid = true,
        error = null;

  const ValidationResult.fail(this.error)
      : isValid = false,
        sanitized = '';
}

/// Простая, но достаточная для MVP валидация сырых заметок перед
/// отправкой в GigaChat. Решает три задачи:
///   1. Защита от случайных «вредоносных» данных (нулевые байты,
///      управляющие символы, бинарь, скопированный из других источников).
///   2. Защита от перерасхода токенов и DoS на бэкенд (лимит длины).
///   3. Базовый фильтр от prompt-injection (предупреждаем, если в тексте
///      есть подозрительные маркеры — финальная защита делается уже
///      в системном промпте `ApiConfig.reportSystemPrompt`).
class InputValidator {
  InputValidator._();

  /// Минимальная длина после trim. Меньше — вероятно опечатка, нет смысла
  /// тратить запрос к нейросети.
  static const int minLength = 10;

  /// Максимальная длина исходного текста. GigaChat имеет лимит на токены;
  /// 8000 символов с запасом помещаются в окно контекста.
  static const int maxLength = 8000;

  /// Регэксп управляющих символов (исключаем переводы строк и табы — они
  /// часть нормального текста).
  static final RegExp _controlChars =
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]');

  /// Маркеры известных prompt-injection атак. Не блокируем (false-positive
  /// дорог), но логируем — на проде сюда можно подключить телеметрию.
  static final RegExp _injectionMarkers = RegExp(
    r'(ignore (all |the )?previous|игнорируй (все |предыдущие)|system\s*:|<\|.*?\|>)',
    caseSensitive: false,
  );

  static ValidationResult validateRawNotes(String input) {
    if (input.isEmpty) {
      return const ValidationResult.fail('Пустой ввод. Введите текст.');
    }

    // Убираем управляющие символы и нормализуем пробелы.
    final cleaned = input
        .replaceAll(_controlChars, '')
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .trim();

    if (cleaned.length < minLength) {
      return const ValidationResult.fail(
        'Текст слишком короткий: минимум $minLength символов.',
      );
    }
    if (cleaned.length > maxLength) {
      return ValidationResult.fail(
        'Текст слишком длинный: максимум $maxLength символов '
        '(сейчас ${cleaned.length}).',
      );
    }
    return ValidationResult.ok(cleaned);
  }

  /// Возвращает true, если в очищенном вводе обнаружены попытки
  /// перехватить системный промпт. UI может показать предупреждение.
  static bool looksLikePromptInjection(String sanitized) =>
      _injectionMarkers.hasMatch(sanitized);
}
