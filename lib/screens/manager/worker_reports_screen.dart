import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/report_provider.dart';
import '../../widgets/manager_filtered_reports_list.dart';

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
          if (rp.isInitializing) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = rp.reportsForWorker(workerName);
          return ManagerWorkerReportsList(
            workerName: workerName,
            reports: reports,
          );
        },
      ),
    );
  }
}
