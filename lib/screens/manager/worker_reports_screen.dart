import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../providers/report_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_chips.dart';
import 'report_review_screen.dart';

class WorkerReportsScreen extends StatelessWidget {
  const WorkerReportsScreen({super.key, required this.workerName});

  final String workerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workerName),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, rp, _) {
          final reports = rp.reportsForWorker(workerName);
          if (reports.isEmpty) {
            return const Center(child: Text('Нет отчётов'));
          }

          final df = DateFormat('dd.MM.yyyy HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = reports[i];
              return _ReportCard(
                report: r,
                dateLabel: df.format(r.createdAt),
                onTap: () => _openReview(context, r),
              );
            },
          );
        },
      ),
    );
  }

  void _openReview(BuildContext context, Report report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportReviewScreen(report: report),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.dateLabel,
    required this.onTap,
  });

  final Report report;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canReview = report.status == ReportStatus.sent;

    return Card(
      child: ListTile(
        leading: ProfileAvatar(name: report.workerName, radius: 20),
        title: Text(report.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                ReportTypeChip(type: report.type),
                ReportStatusChip(status: report.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateLabel),
            if ((report.managerFeedback ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                report.managerFeedback!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: canReview
            ? const Icon(Icons.rate_review_outlined)
            : const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}
