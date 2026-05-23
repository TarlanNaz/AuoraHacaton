import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/report_template.dart';
import '../models/report_type.dart';
import '../services/storage_service.dart';

class TemplateProvider extends ChangeNotifier {
  TemplateProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<ReportTemplate> _templates = [];
  bool _loading = true;

  List<ReportTemplate> get templates => List.unmodifiable(_templates);
  bool get isLoading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    _templates = await _storage.loadTemplates();
    if (_templates.isEmpty) {
      _templates = _defaultTemplates();
      await _storage.saveTemplates(_templates);
    }

    _loading = false;
    notifyListeners();
  }

  List<ReportTemplate> _defaultTemplates() => [
        ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон инцидента',
          reportType: ReportType.incident,
          instruction:
              'Обязательно указывать: время обнаружения, время устранения, '
              'причину (если известна), ответственного, влияние на пользователей. '
              'Не выдумывать цифры.',
          isDefault: true,
        ),
        ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон метрик',
          reportType: ReportType.metrics,
          instruction:
              'Только цифры из исходного текста. Если метрика не названа — '
              '«не указано». Отдельно выделить аномалии.',
          isDefault: true,
        ),
        ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон визита',
          reportType: ReportType.clientVisit,
          instruction:
              'Указать компанию, контакт, договорённости, следующий шаг. '
              'Бюджет и сроки — только если есть в тексте.',
          isDefault: true,
        ),
      ];

  ReportTemplate? templateForType(ReportType type) {
    final typed =
        _templates.where((t) => t.reportType == type).toList();
    if (typed.isNotEmpty) return typed.first;
    return _templates.isNotEmpty ? _templates.first : null;
  }

  String instructionForType(ReportType type) =>
      templateForType(type)?.instruction ?? '';

  Future<void> upsert(ReportTemplate template) async {
    final idx = _templates.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      _templates[idx] = template;
    } else {
      _templates.insert(0, template);
    }
    await _storage.saveTemplates(_templates);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _storage.saveTemplates(_templates);
    notifyListeners();
  }
}
