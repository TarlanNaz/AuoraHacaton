import '../models/report.dart';
import '../models/report_type.dart';

/// Фильтры списка отчётов у руководителя.
class ManagerReportFilter {
  const ManagerReportFilter({
    this.type,
    this.dateFrom,
    this.dateTo,
  });

  final ReportType? type;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  static const ManagerReportFilter empty = ManagerReportFilter();

  bool get hasActiveFilters =>
      type != null || dateFrom != null || dateTo != null;

  ManagerReportFilter copyWith({
    ReportType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearType = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return ManagerReportFilter(
      type: clearType ? null : (type ?? this.type),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }
}

extension ManagerReportFilterX on List<Report> {
  List<Report> applyFilter(ManagerReportFilter filter) {
    if (!filter.hasActiveFilters) return List<Report>.from(this);

    return where((r) {
      if (filter.type != null && r.type != filter.type) return false;

      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      if (filter.dateFrom != null) {
        final from = DateTime(
          filter.dateFrom!.year,
          filter.dateFrom!.month,
          filter.dateFrom!.day,
        );
        if (day.isBefore(from)) return false;
      }
      if (filter.dateTo != null) {
        final to = DateTime(
          filter.dateTo!.year,
          filter.dateTo!.month,
          filter.dateTo!.day,
        );
        if (day.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }
}
