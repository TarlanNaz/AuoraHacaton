import 'report_status.dart' show ReportStatus;

/// Счётчики отчётов рабочего для профиля и дашборда.
class WorkerReportStats {
  const WorkerReportStats({
    required this.total,
    required this.drafts,
    required this.sent,
    required this.accepted,
    required this.rejected,
  });

  final int total;
  final int drafts;
  final int sent;
  final int accepted;
  final int rejected;

  static WorkerReportStats empty() => const WorkerReportStats(
        total: 0,
        drafts: 0,
        sent: 0,
        accepted: 0,
        rejected: 0,
      );

  factory WorkerReportStats.fromCounts(Map<ReportStatus, int> counts) {
    int c(ReportStatus s) => counts[s] ?? 0;
    final drafts = c(ReportStatus.draft);
    final sent = c(ReportStatus.sent);
    final accepted = c(ReportStatus.synced);
    final rejected = c(ReportStatus.rejected);
    return WorkerReportStats(
      total: drafts + sent + accepted + rejected,
      drafts: drafts,
      sent: sent,
      accepted: accepted,
      rejected: rejected,
    );
  }
}
