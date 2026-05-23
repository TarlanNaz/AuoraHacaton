import 'package:flutter/material.dart';

import '../models/report_status.dart';
import '../models/report_type.dart';

class ReportTypeChip extends StatelessWidget {
  const ReportTypeChip({super.key, required this.type});
  final ReportType type;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(type.icon, size: 16),
      label: Text(type.label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label,
        style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
      ),
      side: BorderSide(color: status.color.withValues(alpha: 0.6)),
      backgroundColor: status.color.withValues(alpha: 0.12),
      visualDensity: VisualDensity.compact,
    );
  }
}
