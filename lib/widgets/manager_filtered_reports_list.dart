import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';
import '../screens/manager/report_review_screen.dart';
import '../utils/manager_report_filter.dart';
import '../widgets/app_ui.dart';
import '../widgets/profile_avatar.dart';
import 'manager_report_filters_bar.dart';

/// Список отчётов руководителя с панелью фильтров.
class ManagerFilteredReportsList extends StatefulWidget {
  const ManagerFilteredReportsList({
    super.key,
    required this.reports,
    this.emptyMessage = 'Нет отчётов по выбранным фильтрам',
  });

  final List<Report> reports;
  final String emptyMessage;

  @override
  State<ManagerFilteredReportsList> createState() =>
      _ManagerFilteredReportsListState();
}

class _ManagerFilteredReportsListState extends State<ManagerFilteredReportsList> {
  ManagerReportFilter _filter = ManagerReportFilter.empty;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.reports.applyFilter(_filter);
    final df = DateFormat('dd.MM.yyyy · HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManagerReportFiltersBar(
          filter: _filter,
          onChanged: (f) => setState(() => _filter = f),
          resultCount: filtered.length,
          totalCount: widget.reports.length,
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: widget.reports.isEmpty
                      ? 'Входящих пока нет'
                      : 'Ничего не найдено',
                  subtitle: widget.reports.isEmpty
                      ? 'Отчёты появятся после отправки с поля'
                      : widget.emptyMessage,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return AppReportTile(
                      report: r,
                      dateLabel: '${r.workerName} · ${r.sentAtLabel(df)}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportReviewScreen(report: r),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Список отчётов одного рабочего с фильтрами.
class ManagerWorkerReportsList extends StatefulWidget {
  const ManagerWorkerReportsList({
    super.key,
    required this.workerName,
    required this.reports,
  });

  final String workerName;
  final List<Report> reports;

  @override
  State<ManagerWorkerReportsList> createState() =>
      _ManagerWorkerReportsListState();
}

class _ManagerWorkerReportsListState extends State<ManagerWorkerReportsList> {
  ManagerReportFilter _filter = ManagerReportFilter.empty;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.reports.applyFilter(_filter);
    final df = DateFormat('dd.MM.yyyy · HH:mm');

    return Column(
      children: [
        ManagerReportFiltersBar(
          filter: _filter,
          onChanged: (f) => setState(() => _filter = f),
          resultCount: filtered.length,
          totalCount: widget.reports.length,
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  icon: Icons.description_outlined,
                  title: widget.reports.isEmpty
                      ? 'Нет отчётов'
                      : 'Ничего не найдено',
                  subtitle: widget.reports.isEmpty
                      ? null
                      : 'Нет отчётов по выбранным фильтрам',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return AppReportTile(
                      report: r,
                      dateLabel: r.sentAtLabel(df),
                      feedback: r.managerFeedback,
                      leading: ProfileAvatar(
                        name: widget.workerName,
                        radius: 22,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportReviewScreen(report: r),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
