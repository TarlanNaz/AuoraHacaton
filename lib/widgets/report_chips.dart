import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';

/// Цветной индикатор статуса в списке отчётов (B2B: зелёный / оранжевый / красный).
class ReportStatusDot extends StatelessWidget {
  const ReportStatusDot({
    super.key,
    required this.status,
    this.size = 10,
  });

  final ReportStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: status.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportTypeChip extends StatelessWidget {
  const ReportTypeChip({super.key, required this.type});
  final ReportType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandBlueLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: status.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportStatusDot(status: status, size: 8),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
