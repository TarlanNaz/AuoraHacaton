import 'report.dart';
import 'report_status.dart';

/// Агрегат по рабочему для экрана руководителя.
class WorkerSummary {
  const WorkerSummary({
    required this.workerName,
    required this.totalReports,
    required this.pendingCount,
    required this.rejectedCount,
    required this.acceptedCount,
    this.lastReportAt,
  });

  final String workerName;
  final int totalReports;
  final int pendingCount;
  final int rejectedCount;
  final int acceptedCount;
  final DateTime? lastReportAt;

  static List<WorkerSummary> fromReports(List<Report> inbox) {
    final byName = <String, List<Report>>{};
    for (final r in inbox) {
      byName.putIfAbsent(r.workerName, () => []).add(r);
    }

    return byName.entries.map((e) {
      final list = e.value;
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return WorkerSummary(
        workerName: e.key,
        totalReports: list.length,
        pendingCount: list.where((r) => r.status == ReportStatus.sent).length,
        rejectedCount: list.where((r) => r.status == ReportStatus.rejected).length,
        acceptedCount: list.where((r) => r.status == ReportStatus.synced).length,
        lastReportAt: list.isNotEmpty ? list.first.submittedAt : null,
      );
    }).toList()
      ..sort((a, b) {
        if (a.pendingCount != b.pendingCount) {
          return b.pendingCount.compareTo(a.pendingCount);
        }
        final at = a.lastReportAt;
        final bt = b.lastReportAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  }
}
