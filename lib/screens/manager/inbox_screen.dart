import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/report_provider.dart';
import '../../widgets/manager_filtered_reports_list.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, rp, _) {
        if (rp.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }
        return ManagerFilteredReportsList(reports: rp.managerInbox);
      },
    );
  }
}
