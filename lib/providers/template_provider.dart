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
    } else {
      await ensureOnePerReportType();
    }

    _loading = false;
    notifyListeners();
  }

  /// По одному шаблону на каждый [ReportType] (для руководителя и ИИ).
  Future<void> ensureOnePerReportType() async {
    var changed = false;
    for (final type in ReportType.values) {
      if (type.isProfileChange) continue;
      if (_templates.any((t) => t.reportType == type)) continue;
      _templates.add(_defaultTemplateFor(type));
      changed = true;
    }
    if (changed) {
      await _storage.saveTemplates(_templates);
      notifyListeners();
    }
  }

  List<ReportTemplate> _defaultTemplates() => ReportType.values
      .where((t) => !t.isProfileChange)
      .map(_defaultTemplateFor)
      .toList();

  ReportTemplate _defaultTemplateFor(ReportType type) {
    return switch (type) {
      ReportType.incident => ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон инцидента',
          reportType: ReportType.incident,
          instruction:
              'Обязательно указывать: время обнаружения, время устранения, '
              'причину (если известна), ответственного, влияние на пользователей. '
              'Не выдумывать цифры. Сырые обрывки — разложить по разделам.',
          isDefault: true,
        ),
      ReportType.metrics => ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон метрик',
          reportType: ReportType.metrics,
          instruction:
              'Только цифры из исходного текста и фото. Если метрика не названа — '
              '«не указано». Отдельно выделить аномалии. Таблица показателей обязательна.',
          isDefault: true,
        ),
      ReportType.clientVisit => ReportTemplate(
          id: _uuid.v4(),
          title: 'Шаблон визита',
          reportType: ReportType.clientVisit,
          instruction:
              'Указать компанию, контакт, договорённости, следующий шаг. '
              'Бюджет и сроки — только если есть в тексте или на фото.',
          isDefault: true,
        ),
      ReportType.profileChange => throw ArgumentError(
          'profileChange не использует шаблоны руководителя',
        ),
    };
  }

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
