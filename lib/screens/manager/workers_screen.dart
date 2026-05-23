import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/worker_summary.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_ui.dart';
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
          return const AppEmptyState(
            icon: Icons.groups_outlined,
            title: 'Рабочих пока нет',
            subtitle:
                'Список появится после того, как полевые сотрудники отправят отчёты',
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
    final scheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd.MM.yyyy');

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkerReportsScreen(workerName: summary.workerName),
          ),
        );
      },
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProfileAvatar(name: summary.workerName, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.workerName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Отчётов: ${summary.totalReports}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (summary.lastReportAt != null)
                  Text(
                    'Последний: ${df.format(summary.lastReportAt!)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),
          ),
          Column(
            children: [
              if (summary.pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '${summary.pendingCount} новых',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: scheme.outline),
              if (summary.rejectedCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Откл.: ${summary.rejectedCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
