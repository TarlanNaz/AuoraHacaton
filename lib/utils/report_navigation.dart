import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/report_status.dart';
import '../screens/manager/report_review_screen.dart';
import '../screens/worker/create_report_screen.dart';
import '../screens/worker/profile_change_request_screen.dart';
import 'app_navigation.dart';

/// Открытие отчёта с учётом типа (полевой отчёт vs изменение данных).
class ReportNavigation {
  ReportNavigation._();

  static void openWorkerReport(BuildContext context, Report report) {
    if (report.type.isProfileChange) {
      final readOnly = report.status != ReportStatus.draft &&
          report.status != ReportStatus.rejected;
      Navigator.of(context).push(
        AppNavigation.detailRoute(
          ProfileChangeRequestScreen(
            reportId: report.id,
            readOnly: readOnly,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      AppNavigation.detailRoute(
        CreateReportScreen(
          initialText: report.rawText ?? report.finalText ?? '',
          initialImagePaths: report.imagePaths,
          initialType: report.type,
          reportId: report.id,
        ),
      ),
    );
  }

  static void openManagerReport(BuildContext context, Report report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportReviewScreen(report: report),
      ),
    );
  }

  static void openProfileChangeForm(BuildContext context) {
    Navigator.of(context).push(
      AppNavigation.detailRoute(const ProfileChangeRequestScreen()),
    );
  }
}
