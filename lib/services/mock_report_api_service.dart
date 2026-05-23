import 'dart:math';

import '../config/auth_stubs.dart';
import '../models/report.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';
import '../utils/app_logger.dart';
import '../utils/demo_asset_importer.dart';
import 'image_storage_service.dart';
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

/// Демо-отчёты для руководителя: по одному на каждый тип, с фото.
class MockInboxSeeder {
  MockInboxSeeder(this._storage, this._images);

  static const _tag = 'MockInboxSeeder';
  static const _demoPhotoAsset = 'assets/images/demo_worker_avatar.png';

  final StorageService _storage;
  final ImageStorageService _images;

  Future<void> seedIfNeeded() async {
    if (await _storage.isMockInboxSeeded()) return;

    final importer = DemoAssetImporter(imageStorage: _images);
    final incidentPhoto = await importer.importAsset(_demoPhotoAsset);
    final metricsPhoto = await importer.importAsset(_demoPhotoAsset);
    final visitPhoto = await importer.importAsset(_demoPhotoAsset);

    final now = DateTime.now();
    final mocks = [
      Report(
        id: 'mock-incident',
        finalText: '## Инцидент на узле №4, цех Б\n\n'
            '## Хронология\n'
            '- 09:15 — обнаружена лужа у насоса (см. фото 1)\n'
            '- 09:20 — насос остановлен, вывешено предупреждение\n\n'
            '## Причина\n'
            'Предположительно отошёл шланг — требует подтверждения\n\n'
            '## Влияние\n'
            'Простой узла — не указано\n\n'
            '## Фотофиксация\n'
            '- фото 1 — мокрое пятно у основания насоса, следы ржавчины\n\n'
            '## Рекомендации\n'
            'Замена уплотнения — по данным осмотра',
        type: ReportType.incident,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(hours: 5)),
        sentAt: now.subtract(const Duration(hours: 5)),
        workerName: AuthStubs.workerDisplayName,
        imagePaths: [incidentPhoto],
      ),
      Report(
        id: 'mock-metrics',
        finalText: '## Показатели участка «Юг», смена 23.05\n\n'
            '## Сводка показателей\n'
            '- Линия 3: аномалия (см. фото 1)\n'
            '- Остальные показатели: не указано (цифры на табло нечитаемы)\n\n'
            '## Аномалии\n'
            '- 3-я линия — отклонение зафиксировано на снимке\n\n'
            '## Фотофиксация\n'
            '- фото 1 — табло с показаниями, часть цифр размыта\n\n'
            '## Выводы\n'
            '- Требуется повторный замер показателей',
        type: ReportType.metrics,
        status: ReportStatus.synced,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        sentAt: now.subtract(const Duration(days: 1, hours: 2)),
        workerName: 'Петрова М.К.',
        imagePaths: [metricsPhoto],
      ),
      Report(
        id: 'mock-visit',
        finalText: '## Визит к клиенту (адрес на визитке)\n\n'
            '## Участники\n'
            '- Представитель клиента — не указано\n'
            '- Полевой сотрудник — ${AuthStubs.workerDisplayName}\n\n'
            '## Обсуждённые вопросы\n'
            '- Поставки и сроки — без конкретных цифр\n\n'
            '## Договорённости\n'
            '- Созвониться для уточнения сроков\n\n'
            '## Фотофиксация\n'
            '- фото 1 — визитка с контактами\n'
            '- фото 2 — склад с коробками без маркировки (если приложено)\n\n'
            '## Следующие шаги\n'
            '- Повторный звонок — срок не указан',
        type: ReportType.clientVisit,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(days: 2)),
        sentAt: now.subtract(const Duration(days: 2)),
        workerName: 'Сидоров К.Н.',
        imagePaths: [visitPhoto],
      ),
    ];

    var inbox = await _storage.loadManagerInbox();
    inbox.removeWhere((r) => r.id.startsWith('mock-'));
    inbox.insertAll(0, mocks);
    inbox.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    await _storage.saveManagerInbox(inbox);
    await _storage.setMockInboxSeeded();
    AppLogger.info(_tag, 'seeded ${mocks.length} demo reports with photos');
  }
}
