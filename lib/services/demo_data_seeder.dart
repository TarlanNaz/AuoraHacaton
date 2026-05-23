import '../config/auth_stubs.dart';
import '../models/profile_change_draft.dart';
import '../models/report.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';
import '../utils/app_logger.dart';
import '../utils/demo_asset_importer.dart';
import 'image_storage_service.dart';
import 'storage_service.dart';

/// Демонстрационные отчёты для жюри и показа на Aurora.
class DemoDataSeeder {
  DemoDataSeeder(this._storage, this._images);

  static const _tag = 'DemoDataSeeder';
  static const _photoAsset = 'assets/images/demo_worker_avatar.png';

  final StorageService _storage;
  final ImageStorageService _images;

  Future<void> seedManagerInboxIfNeeded() async {
    if (await _storage.isDemoManagerSeeded()) return;

    final photo = await DemoAssetImporter(imageStorage: _images)
        .importAsset(_photoAsset);
    final now = DateTime.now();

    final mocks = [
      Report(
        id: 'demo-incident',
        finalText: '## Инцидент: протечка у насоса, цех Б, узел №4\n\n'
            '## Хронология\n'
            '- 09:15 — обнаружена лужа у насоса (фото 1)\n'
            '- 09:20 — насос остановлен, вывешено предупреждение\n\n'
            '## Причина\n'
            'Отошёл шланг высокого давления — требует подтверждения\n\n'
            '## Влияние\n'
            'Простой узла до устранения\n\n'
            '## Фотофиксация\n'
            '- фото 1 — мокрое пятно у основания насоса\n\n'
            '## Рекомендации\n'
            'Замена уплотнения и проверка креплений',
        type: ReportType.incident,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(hours: 3)),
        sentAt: now.subtract(const Duration(hours: 3)),
        workerName: AuthStubs.workerDisplayName,
        locationQuery: 'Цех Б, узел №4',
        locationName: 'Мурманск, промплощадка, цех Б',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-metrics',
        finalText: '## Показатели участка «Юг», смена ${now.day}.${now.month}\n\n'
            '## Сводка показателей\n'
            '- Линия 3: отклонение по давлению (фото 1)\n'
            '- Линии 1–2: в норме\n\n'
            '## Аномалии\n'
            '- Линия 3 — зафиксировано на снимке табло\n\n'
            '## Фотофиксация\n'
            '- фото 1 — показания на табло\n\n'
            '## Выводы\n'
            '- Назначен повторный замер через 2 часа',
        type: ReportType.metrics,
        status: ReportStatus.synced,
        createdAt: now.subtract(const Duration(days: 1)),
        sentAt: now.subtract(const Duration(days: 1)),
        workerName: 'Петрова М.К.',
        locationQuery: 'Участок «Юг», линия 3',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-visit',
        finalText: '## Визит: ООО «СеверТех», склад №2\n\n'
            '## Участники\n'
            '- Представитель заказчика — И.С. Козлов\n'
            '- ${AuthStubs.workerDisplayName}\n\n'
            '## Обсуждённые вопросы\n'
            '- Сроки поставки оборудования\n'
            '- Маркировка грузов на складе\n\n'
            '## Договорённости\n'
            '- Созвон 25.05 для уточнения отгрузки\n\n'
            '## Фотофиксация\n'
            '- фото 1 — визитка контакта\n\n'
            '## Следующие шаги\n'
            '- Подготовить сводку для руководителя',
        type: ReportType.clientVisit,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        sentAt: now.subtract(const Duration(days: 2, hours: 4)),
        workerName: 'Сидоров К.Н.',
        locationQuery: 'Склад №2, ООО «СеверТех»',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-profile',
        finalText: ProfileChangeDraft(
          newFullName: 'Иванов Алексей Петрович',
          reason: 'Исправление отчества в учётной записи',
        ).buildMarkdown(
          currentFullName: 'Иванов А.П.',
          login: AuthStubs.workerLogin,
          currentEmployer: AuthStubs.workerEmployer,
          hasNewPhoto: false,
        ),
        rawText: ProfileChangeDraft(
          newFullName: 'Иванов Алексей Петрович',
          reason: 'Исправление отчества в учётной записи',
        ).encodeRaw(),
        type: ReportType.profileChange,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(hours: 8)),
        sentAt: now.subtract(const Duration(hours: 8)),
        workerName: 'Кузнецов Д.В.',
        imagePaths: const [],
      ),
    ];

    var inbox = await _storage.loadManagerInbox();
    inbox.removeWhere((r) => r.id.startsWith('demo-') || r.id.startsWith('mock-'));
    inbox.insertAll(0, mocks);
    inbox.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    await _storage.saveManagerInbox(inbox);
    await _storage.setDemoManagerSeeded();
    AppLogger.info(_tag, 'manager inbox: ${mocks.length} demo reports');
  }

  Future<void> seedWorkerReportsIfNeeded() async {
    final existingCheck = await _storage.loadReports();
    if (existingCheck.any((r) => r.id == 'demo-worker-draft-2')) {
      await _storage.setDemoWorkerSeeded();
      return;
    }

    final photo = await DemoAssetImporter(imageStorage: _images)
        .importAsset(_photoAsset);
    final now = DateTime.now();
    final name = AuthStubs.workerDisplayName;

    final reports = [
      // ─── Черновики ───────────────────────────────────────────────────────
      Report(
        id: 'demo-worker-draft-1',
        rawText:
            'Насос №4 — шум при запуске. Нужно сфотографировать шильдик и замерить вибрацию.',
        type: ReportType.incident,
        status: ReportStatus.draft,
        createdAt: now.subtract(const Duration(hours: 2)),
        workerName: name,
        locationQuery: 'Цех Б, насос №4',
        locationName: 'Цех Б, насос №4',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-worker-draft-2',
        rawText:
            'Смена 14.05: линия 2 в норме, по линии 3 отклонение давления +0.3 бар. '
            'Табло снято на фото.',
        type: ReportType.metrics,
        status: ReportStatus.draft,
        createdAt: now.subtract(const Duration(hours: 5)),
        workerName: name,
        locationQuery: 'Участок «Юг»',
        imagePaths: const [],
      ),
      // ─── Отправленные / проверенные ──────────────────────────────────────
      Report(
        id: 'demo-worker-sent',
        finalText: '## Осмотр трансформаторной, п. Северный\n\n'
            '## Сводка\n'
            '- Визуальный осмотр без замечаний\n'
            '- Температура корпуса в норме\n\n'
            '## Фотофиксация\n'
            '- фото 1 — общий вид площадки\n\n'
            '## Выводы\n'
            '- Продолжить мониторинг по графику',
        type: ReportType.metrics,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        sentAt: now.subtract(const Duration(days: 1, hours: 6)),
        workerName: name,
        locationQuery: 'п. Северный, трансформаторная',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-worker-synced',
        finalText: '## Плановый обход кабельного канала\n\n'
            '## Сводка\n'
            '- Маркировка кабелей соответствует схеме\n'
            '- Посторонних предметов нет\n\n'
            '## Выводы\n'
            '- Следующий обход по графику',
        type: ReportType.incident,
        status: ReportStatus.synced,
        createdAt: now.subtract(const Duration(days: 3)),
        sentAt: now.subtract(const Duration(days: 3)),
        workerName: name,
        locationQuery: 'Кабельный канал, сектор 7',
        imagePaths: [photo],
      ),
      Report(
        id: 'demo-worker-rejected',
        finalText: '## Визит на объект «СеверМет»\n\n'
            '## Сводка\n'
            '- Встреча с техдиректором\n'
            '- Обсудили сроки поставки\n\n'
            '## Замечания\n'
            '- Не указаны конкретные даты в договорённостях',
        type: ReportType.clientVisit,
        status: ReportStatus.rejected,
        createdAt: now.subtract(const Duration(days: 4)),
        sentAt: now.subtract(const Duration(days: 4)),
        workerName: name,
        locationQuery: 'ООО «СеверМет», офис',
        managerFeedback:
            'Дополните раздел «Договорённости» конкретными датами и ответственными.',
        imagePaths: const [],
      ),
      Report(
        id: 'demo-worker-sent-2',
        finalText: '## Контроль давления на линии 1\n\n'
            '## Сводка\n'
            '- Давление 4.2 бар, в пределах нормы\n'
            '- Утечек не обнаружено\n\n'
            '## Фотофиксация\n'
            '- фото 1 — манометр',
        type: ReportType.metrics,
        status: ReportStatus.sent,
        createdAt: now.subtract(const Duration(hours: 20)),
        sentAt: now.subtract(const Duration(hours: 20)),
        workerName: name,
        locationQuery: 'Линия 1, пост №2',
        imagePaths: [photo],
      ),
    ];

    var existing = await _storage.loadReports();
    existing.removeWhere((r) => r.id.startsWith('demo-worker-'));
    existing.insertAll(0, reports);
    existing.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    await _storage.saveReports(existing);
    await _storage.setDemoWorkerSeeded();
    AppLogger.info(_tag, 'worker: ${reports.length} demo reports');
  }
}
