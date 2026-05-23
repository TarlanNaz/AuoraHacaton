import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/worker_summary.dart';
import '../../providers/report_provider.dart';
import '../../widgets/profile_avatar.dart';
import 'worker_reports_screen.dart';

class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, rp, _) {
        if (rp.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }

        final workers = rp.workerSummaries;
        if (workers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Пока нет отчётов от рабочих.\nОни появятся после отправки с поля.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _WorkerCard(summary: workers[i]),
        );
      },
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.summary});

  final WorkerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy');

    return Card(
      child: ListTile(
        leading: ProfileAvatar(name: summary.workerName, radius: 24),
        title: Text(summary.workerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Отчётов: ${summary.totalReports}'),
            if (summary.lastReportAt != null)
              Text('Последний: ${df.format(summary.lastReportAt!)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (summary.pendingCount > 0)
              Badge(
                label: Text('${summary.pendingCount}'),
                child: const Icon(Icons.inbox_outlined),
              )
            else
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            if (summary.rejectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Откл.: ${summary.rejectedCount}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.red),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkerReportsScreen(workerName: summary.workerName),
            ),
          );
        },
      ),
    );
  }
}
