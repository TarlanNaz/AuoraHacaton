import 'dart:math';

import '../models/report.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';
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
    final sent = report.copyWith(status: ReportStatus.sent);
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

/// Mock-отчёты для демо руководителя при первом входе.
class MockInboxSeeder {
  MockInboxSeeder(this._storage);

  final StorageService _storage;

  Future<void> seedIfNeeded() async {
    if (await _storage.isMockInboxSeeded()) return;

    final now = DateTime.now();
    final mocks = [
      Report(
        id: 'mock-1',
        finalText: '## Инцидент на узле №4\n\n'
            '## Хронология\nПротечка обнаружена в 09:15.\n\n'
            '## Фотофиксация\nСм. приложение: фото 1 (если было бы в системе).\n\n'
            '## Выводы\nТребуется замена уплотнения — по данным осмотра.',
        type: ReportType.incident,
        status: ReportStatus.synced,
        createdAt: now.subtract(const Duration(hours: 5)),
        workerName: 'Иванов А.П.',
      ),
      Report(
        id: 'mock-2',
        finalText: '## Визит к ООО «Север»\n\n'
            '## Обсуждённые вопросы\nСроки поставки — не согласованы в тексте.\n\n'
            '## Следующие шаги\nПовторный звонок — требует уточнения.',
        type: ReportType.clientVisit,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(days: 1)),
        workerName: 'Петрова М.К.',
      ),
    ];

    final inbox = await _storage.loadManagerInbox();
    inbox.addAll(mocks);
    await _storage.saveManagerInbox(inbox);
    await _storage.setMockInboxSeeded();
  }
}
