import 'package:flutter/material.dart';

import '../models/report_type.dart';

/// Пример с привязкой к типу отчёта. Тексты намеренно фрагментарные —
/// без фото и контекста отчёт собрать сложно (для демо на защите).
class SampleInput {
  final String id;
  final String title;
  final IconData icon;
  final ReportType reportType;
  final String body;
  final bool requiresPhoto;

  const SampleInput({
    required this.id,
    required this.title,
    required this.icon,
    required this.reportType,
    required this.body,
    this.requiresPhoto = true,
  });
}

class SampleInputs {
  SampleInputs._();

  static const List<SampleInput> all = [
    SampleInput(
      id: 'incident_sparse',
      title: 'Инцидент (фото!)',
      icon: Icons.warning_amber_rounded,
      reportType: ReportType.incident,
      body: 'Узел №4, цех Б. ~09:15 заметил лужу у насоса. '
          'На фото видно: мокрое пятно, ржавчина? шланг отошёл? '
          'Остановил насос, вывесил предупреждение. '
          'Ответственный за узел — не помню фамилию. '
          'Сколько простоя — не считал. См. фото 1 и фото 2.',
    ),
    SampleInput(
      id: 'metrics_photo',
      title: 'Метрики (фото!)',
      icon: Icons.bar_chart_rounded,
      reportType: ReportType.metrics,
      body: 'Смена 23.05, участок «Юг». Показания с табло на стене — '
          'см. фото 1 (цифры размыты, часть не читается). '
          'В блокноте записано: «было 78, стало ??». '
          'Аномалия на 3-й линии — подробности только на фото 2. '
          'Нужен отчёт для Гришиной В.Б., диаграммы не делал.',
    ),
    SampleInput(
      id: 'visit_card',
      title: 'Визит (фото!)',
      icon: Icons.handshake_outlined,
      reportType: ReportType.clientVisit,
      body: 'Встреча сегодня, адрес на визитке — фото 1. '
          'Обсуждали «поставки» и «сроки» — цифр в заметках нет. '
          'Контакт улыбался, договорились «созвониться». '
          'Бюджет не называли. На фото 2 — их склад, коробки без маркировки.',
    ),
  ];

  static List<SampleInput> forType(ReportType type) =>
      all.where((s) => s.reportType == type).toList();
}
