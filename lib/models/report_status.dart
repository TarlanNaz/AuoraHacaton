import 'package:flutter/material.dart';

enum ReportStatus {
  draft('draft', 'Черновик', Colors.grey),
  sent('sent', 'На проверке', Colors.orange),
  synced('synced', 'Принят', Colors.green),
  rejected('rejected', 'Отклонён', Colors.red);

  const ReportStatus(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;

  static ReportStatus fromId(String? id) {
    return ReportStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => ReportStatus.draft,
    );
  }
}
