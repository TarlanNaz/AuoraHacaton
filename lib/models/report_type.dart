import 'package:flutter/material.dart';

enum ReportType {
  incident('incident', 'Инцидент', Icons.warning_amber_rounded),
  metrics('metrics', 'Метрики', Icons.bar_chart_rounded),
  clientVisit('client_visit', 'Визит к клиенту', Icons.handshake_outlined);

  const ReportType(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;

  static ReportType fromId(String? id) {
    return ReportType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => ReportType.incident,
    );
  }
}
