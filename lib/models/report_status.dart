import 'package:flutter/material.dart';

import '../config/app_theme.dart';

enum ReportStatus {
  draft('draft', 'Черновик', AppTheme.warningOrange),
  sent('sent', 'На проверке', AppTheme.warningAmber),
  synced('synced', 'Принят', AppTheme.successGreen),
  rejected('rejected', 'Отклонён', AppTheme.errorMuted);

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
