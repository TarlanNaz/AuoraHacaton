import 'dart:math';

import '../models/report.dart';
import '../models/report_status.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';

/// Имитация бэкенда: отправка отчётов руководителю и оффлайн-очередь.
abstract class MockReportApiService {
  Future<bool> submitToManager(Report report);
  Future<void> syncPending();
}

class HttpMockReportApiService implements MockReportApiService {
  HttpMockReportApiService(this._storage);

  static const _tag = 'MockReportApi';
  final StorageService _storage;
  final _random = Random();

  @override
  Future<bool> submitToManager(Report report) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final simulateOffline = _random.nextDouble() < 0.15;
    if (simulateOffline) {
      final queue = await _storage.loadSendQueue();
      if (!queue.contains(report.id)) {
        queue.add(report.id);
        await _storage.saveSendQueue(queue);
      }
      AppLogger.warn(_tag, 'offline: queued ${report.id}');
      return false;
    }

    final inbox = await _storage.loadManagerInbox();
    final sent = report.copyWith(
      status: ReportStatus.sent,
      sentAt: report.sentAt ?? DateTime.now(),
    );
    inbox.insert(0, sent);
    await _storage.saveManagerInbox(inbox);

    final queue = await _storage.loadSendQueue();
    queue.remove(report.id);
    await _storage.saveSendQueue(queue);

    AppLogger.info(_tag, 'report ${report.id} delivered to manager inbox');
    return true;
  }

  @override
  Future<void> syncPending() async {
    final queue = await _storage.loadSendQueue();
    if (queue.isEmpty) return;

    final reports = await _storage.loadReports();
    final remaining = <String>[];

    for (final id in queue) {
      final idx = reports.indexWhere((r) => r.id == id);
      if (idx == -1) continue;
      final ok = await submitToManager(reports[idx]);
      if (!ok) remaining.add(id);
    }

    await _storage.saveSendQueue(remaining);
  }
}
