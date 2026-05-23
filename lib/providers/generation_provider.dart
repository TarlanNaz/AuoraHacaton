import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/giga_chat_service.dart';
import '../utils/app_logger.dart';
import '../utils/input_validator.dart';

enum GenerationStatus { empty, loading, error, success }

typedef TokenResolver = Future<String> Function();

class GenerationProvider extends ChangeNotifier {
  GenerationProvider({required GigaChatService service}) : _service = service;

  static const _tag = 'GenerationProvider';

  final GigaChatService _service;

  GenerationStatus _status = GenerationStatus.empty;
  String? _result;
  String? _error;
  String _lastSanitizedInput = '';

  GenerationStatus get status => _status;
  String? get result => _result;
  String? get error => _error;
  String get lastSanitizedInput => _lastSanitizedInput;
  bool get isLoading => _status == GenerationStatus.loading;

  Future<void> generate({
    required String rawText,
    required TokenResolver tokenResolver,
    List<File> imageFiles = const [],
    String? systemPrompt,
  }) async {
    final hasImages = imageFiles.isNotEmpty;
    final trimmed = rawText.trim();

    if (!hasImages && trimmed.isEmpty) {
      _status = GenerationStatus.error;
      _error = 'Введите текст или прикрепите фото';
      _result = null;
      notifyListeners();
      return;
    }

    if (trimmed.isNotEmpty) {
      final validation = InputValidator.validateRawNotes(rawText);
      if (!validation.isValid) {
        _status = GenerationStatus.error;
        _error = validation.error;
        _result = null;
        notifyListeners();
        return;
      }
      _lastSanitizedInput = validation.sanitized;
    } else {
      _lastSanitizedInput = '';
    }

    _status = GenerationStatus.loading;
    _result = null;
    _error = null;
    notifyListeners();

    try {
      final token = await tokenResolver();
      final answer = await _service.generateReport(
        token: token,
        rawText: _lastSanitizedInput,
        imageFiles: imageFiles,
        systemPrompt: systemPrompt,
      );
      _result = answer;
      _status = GenerationStatus.success;
    } on GigaChatException catch (e) {
      AppLogger.warn(_tag, 'generation failed: ${e.message}');
      _error = e.message;
      _status = GenerationStatus.error;
    } catch (e, st) {
      AppLogger.error(_tag, 'unexpected', error: e, stackTrace: st);
      _error = 'Неизвестная ошибка. Подробности в логах.';
      _status = GenerationStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = GenerationStatus.empty;
    _result = null;
    _error = null;
    _lastSanitizedInput = '';
    notifyListeners();
  }
}
