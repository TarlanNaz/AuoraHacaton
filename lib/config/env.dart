import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Типизированный фасад над flutter_dotenv.
///
/// Все обращения к переменным окружения идут только через этот класс —
/// так проще менять источник конфигурации (например, на --dart-define
/// для CI) и невозможно случайно опечататься в имени ключа.
class Env {
  Env._();

  static const _envFile = '.env';

  /// Загружает `.env` из ассетов. Если файл отсутствует или повреждён —
  /// приложение всё равно стартует, просто [hasAuthKey] вернёт false и
  /// пользователь сможет ввести Bearer-токен вручную.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: _envFile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Env] .env не загружен: $e');
      }
    }
  }

  /// Авторизационный ключ GigaChat (base64 от `client_id:client_secret`).
  /// На его основе сервис получает короткоживущий access_token.
  static String get gigaChatAuthKey => _read('GIGACHAT_AUTH_KEY');

  /// Скоуп API: `GIGACHAT_API_PERS`, `GIGACHAT_API_B2B` или `GIGACHAT_API_CORP`.
  static String get gigaChatScope =>
      _readOr('GIGACHAT_SCOPE', 'GIGACHAT_API_PERS');

  /// Модель по умолчанию: GigaChat / GigaChat-Pro / GigaChat-Max.
  static String get gigaChatModel => _readOr('GIGACHAT_MODEL', 'GigaChat');

  static bool get hasAuthKey => gigaChatAuthKey.isNotEmpty;

  static String _read(String key) {
    final value = dotenv.maybeGet(key);
    return value?.trim() ?? '';
  }

  static String _readOr(String key, String fallback) {
    final value = _read(key);
    return value.isEmpty ? fallback : value;
  }
}
