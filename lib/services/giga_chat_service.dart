import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../config/report_prompts.dart';
import '../utils/app_logger.dart';
import '../utils/input_validator.dart';
import '../utils/network_errors.dart';

/// Типизированная ошибка сетевого слоя — UI ловит её для отображения
/// человекочитаемого сообщения и кнопки "Сохранить черновик локально".
///
/// Это намеренный антипод silent failures: каждая ветка ошибок
/// (нет сети / 401 / 500 / битый JSON / таймаут) превращается в
/// `GigaChatException` с понятным `message`, а не в брошенный наружу
/// `SocketException` или поглощённый `null`.
class GigaChatException implements Exception {
  final String message;
  GigaChatException(this.message);

  @override
  String toString() => message;
}

/// Результат OAuth-авторизации в GigaChat. Access-токен живёт ~30 минут,
/// поэтому храним [expiresAt] и обновляем по необходимости.
class GigaChatToken {
  final String accessToken;
  final DateTime expiresAt;

  GigaChatToken({required this.accessToken, required this.expiresAt});

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(ApiConfig.tokenExpiryGuard));
}

/// Контракт клиента GigaChat. Зависимости провайдеров типизированы
/// именно интерфейсом, что позволяет в тестах подменить его
/// `FakeGigaChatService` без правки UI.
abstract class GigaChatService {
  Future<GigaChatToken> obtainAccessToken({
    required String authKey,
    String scope,
  });

  Future<String> generateReport({
    required String token,
    required String rawText,
    String? model,
    List<File> imageFiles = const [],
    String? systemPrompt,
  });
}

/// HTTP-реализация поверх `package:http`. Все запросы идут только по
/// HTTPS на эндпоинты [ApiConfig.chatCompletionsUrl] и [ApiConfig.oauthUrl];
/// валидация TLS-сертификатов выполняется системным trust-store (на Aurora
/// и Android — стандартная цепочка). Для dev-сборки в `main.dart` есть
/// override (`_DevHttpOverrides`), активный только в `kDebugMode`.
class HttpGigaChatService implements GigaChatService {
  HttpGigaChatService({http.Client? client, Uuid? uuid})
      : _client = client ?? http.Client(),
        _uuid = uuid ?? const Uuid();

  static const _tag = 'GigaChatService';

  final http.Client _client;
  final Uuid _uuid;

  @override
  Future<GigaChatToken> obtainAccessToken({
    required String authKey,
    String scope = ApiConfig.defaultScope,
  }) async {
    if (authKey.trim().isEmpty) {
      throw GigaChatException(
          'GIGACHAT_AUTH_KEY не задан в .env. Заполните файл и перезапустите.');
    }

    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse(ApiConfig.oauthUrl),
        headers: {
          'Authorization': 'Basic ${authKey.trim()}',
          'RqUID': _uuid.v4(),
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {'scope': scope},
      ).timeout(ApiConfig.oauthTimeout);
    } on SocketException catch (e, st) {
      AppLogger.error(_tag, 'oauth socket error', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'OAuth GigaChat'),
      );
    } on HandshakeException catch (e, st) {
      AppLogger.error(_tag, 'oauth tls handshake', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'OAuth GigaChat'),
      );
    } on TlsException catch (e, st) {
      AppLogger.error(_tag, 'oauth tls', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'OAuth GigaChat'),
      );
    } on TimeoutException catch (e) {
      AppLogger.warn(_tag, 'oauth timeout', e);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'OAuth GigaChat'),
      );
    } on HttpException catch (e) {
      AppLogger.warn(_tag, 'oauth http error', e);
      throw GigaChatException('Сетевая ошибка при обращении к OAuth.');
    } catch (e, st) {
      AppLogger.error(_tag, 'oauth failed', error: e, stackTrace: st);
      throw GigaChatException(
        'Сбой OAuth GigaChat: ${describeNetworkFailure(e, service: 'OAuth GigaChat')}',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw GigaChatException(
          'GIGACHAT_AUTH_KEY отклонён сервером (HTTP ${response.statusCode}). '
          'Проверьте ключ и scope.');
    }
    if (response.statusCode != 200) {
      throw GigaChatException(
          'OAuth GigaChat вернул HTTP ${response.statusCode}.');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error(_tag, 'oauth: malformed JSON',
          error: e, stackTrace: st);
      throw GigaChatException('OAuth GigaChat вернул некорректный JSON.');
    }

    final accessToken = decoded['access_token'] as String?;
    final expiresRaw = decoded['expires_at'];
    if (accessToken == null || accessToken.isEmpty) {
      throw GigaChatException('OAuth GigaChat не вернул access_token.');
    }

    final expiresAt = expiresRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(expiresRaw)
        : DateTime.now().add(const Duration(minutes: 25));

    AppLogger.info(_tag, 'access token obtained, expires at $expiresAt');
    return GigaChatToken(accessToken: accessToken, expiresAt: expiresAt);
  }

  /// Загружает фото в GigaChat Files API, возвращает id вложений.
  Future<List<String>> _uploadImages({
    required String token,
    required List<File> files,
  }) async {
    final ids = <String>[];
    for (final file in files) {
      if (!await file.exists()) continue;
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.filesUploadUrl),
        );
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
        request.fields['purpose'] = 'general';
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path),
        );

        final streamed = await request.send().timeout(ApiConfig.fileUploadTimeout);
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode != 200) {
          AppLogger.warn(
            _tag,
            'file upload HTTP ${response.statusCode}: ${response.body}',
          );
          continue;
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final id = decoded['id'] as String?;
        if (id != null && id.isNotEmpty) ids.add(id);
      } catch (e, st) {
        AppLogger.error(_tag, 'file upload failed', error: e, stackTrace: st);
      }
    }
    return ids;
  }

  String _buildUserContent(String sanitizedText, int imageCount) {
    if (imageCount == 0) return sanitizedText;
    return sanitizedText + ReportPrompts.photoUserHint(imageCount);
  }

  @override
  Future<String> generateReport({
    required String token,
    required String rawText,
    String? model,
    List<File> imageFiles = const [],
    String? systemPrompt,
  }) async {
    if (token.trim().isEmpty) {
      throw GigaChatException(
          'Bearer-токен пустой. Получите его через OAuth или вставьте вручную.');
    }

    final hasImages = imageFiles.isNotEmpty;
    String sanitized;

    if (rawText.trim().isEmpty && hasImages) {
      sanitized =
          'Полевой сотрудник приложил фотографии с объекта. Составь '
          'формальный отчёт-осмотр по стандартной структуре. В тексте '
          'укажи, что визуальные детали взяты из приложенных снимков.';
    } else {
      final validation = InputValidator.validateRawNotes(rawText);
      if (!validation.isValid) {
        throw GigaChatException(validation.error ?? 'Некорректный ввод.');
      }
      sanitized = validation.sanitized;
      if (InputValidator.looksLikePromptInjection(sanitized)) {
        AppLogger.warn(_tag, 'possible prompt injection in user input');
      }
    }

    List<String> attachmentIds = [];
    if (hasImages) {
      attachmentIds = await _uploadImages(token: token, files: imageFiles);
      AppLogger.info(
        _tag,
        'uploaded ${attachmentIds.length}/${imageFiles.length} images',
      );
    }

    final userMessage = <String, dynamic>{
      'role': 'user',
      'content': _buildUserContent(sanitized, imageFiles.length),
    };
    if (attachmentIds.isNotEmpty) {
      userMessage['attachments'] = attachmentIds;
    }

    final body = jsonEncode({
      'model': model ?? ApiConfig.defaultModel,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt ?? ApiConfig.reportSystemPrompt,
        },
        userMessage,
      ],
      'temperature': ApiConfig.temperature,
      'top_p': ApiConfig.topP,
      'stream': false,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.chatCompletionsUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token.trim()}',
            },
            body: body,
          )
          .timeout(ApiConfig.chatTimeout);
    } on SocketException catch (e, st) {
      AppLogger.error(_tag, 'chat socket error', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'GigaChat'),
      );
    } on HandshakeException catch (e, st) {
      AppLogger.error(_tag, 'chat tls handshake', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'GigaChat'),
      );
    } on TimeoutException catch (e) {
      AppLogger.warn(_tag, 'chat timeout', e);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'GigaChat'),
      );
    } on HttpException catch (e) {
      AppLogger.warn(_tag, 'chat http error', e);
      throw GigaChatException('Сетевая ошибка при обращении к GigaChat.');
    } catch (e, st) {
      AppLogger.error(_tag, 'chat call failed', error: e, stackTrace: st);
      throw GigaChatException(
        describeNetworkFailure(e, service: 'GigaChat'),
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw GigaChatException(
          'Токен GigaChat недействителен (HTTP ${response.statusCode}).');
    }
    if (response.statusCode == 429) {
      throw GigaChatException('Слишком много запросов. Попробуйте позже.');
    }
    if (response.statusCode >= 500) {
      throw GigaChatException(
          'Сервер GigaChat недоступен (HTTP ${response.statusCode}).');
    }
    if (response.statusCode != 200) {
      throw GigaChatException(
          'Сервер вернул HTTP ${response.statusCode}.');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error(_tag, 'chat: malformed JSON',
          error: e, stackTrace: st);
      throw GigaChatException('Не удалось разобрать ответ сервера.');
    }

    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw GigaChatException('GigaChat вернул пустой ответ.');
    }
    final message = (choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw GigaChatException('GigaChat вернул пустой контент.');
    }

    return content.trim();
  }
}
