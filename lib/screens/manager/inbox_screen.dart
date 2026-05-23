import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report_status.dart';
import '../../providers/report_provider.dart';
import '../../widgets/report_chips.dart';
import 'report_review_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, rp, _) {
        if (rp.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rp.managerInbox.isEmpty) {
          return const Center(child: Text('Входящих отчётов пока нет'));
        }
        final df = DateFormat('dd.MM.yyyy HH:mm');
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rp.managerInbox.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rp.managerInbox[i];
            return Card(
              child: ListTile(
                leading: Icon(r.type.icon, color: Theme.of(context).colorScheme.primary),
                title: Text(r.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${r.workerName} · ${df.format(r.createdAt)}'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        ReportTypeChip(type: r.type),
                        ReportStatusChip(status: r.status),
                      ],
                    ),
                  ],
                ),
                trailing: r.status == ReportStatus.sent
                    ? const Icon(Icons.rate_review_outlined)
                    : const Icon(Icons.chevron_right),
                isThreeLine: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportReviewScreen(report: r),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
