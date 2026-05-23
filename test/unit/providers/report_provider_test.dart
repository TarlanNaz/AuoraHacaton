import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/models/report.dart';
import 'package:structurator/models/report_status.dart';
import 'package:structurator/models/report_type.dart';
import 'package:structurator/providers/report_provider.dart';
import 'package:structurator/services/mock_report_api_service.dart';

import '../../helpers/fakes.dart';

class _FakeMockApi implements MockReportApiService {
  bool submitted = false;

  @override
  Future<bool> submitToManager(Report report) async {
    submitted = true;
    return true;
  }

  @override
  Future<void> syncPending() async {}
}

void main() {
  group('ReportProvider', () {
    late FakeStorageService storage;
    late FakeGigaChatService giga;
    late _FakeMockApi mockApi;
    late ReportProvider provider;

    setUp(() async {
      storage = FakeStorageService();
      giga = FakeGigaChatService();
      mockApi = _FakeMockApi();
      provider = ReportProvider(
        storage: storage,
        gigaChatService: giga,
        mockApi: mockApi,
      );
      await provider.init();
    });

    test('saveGenerated clears rawText', () async {
      await provider.saveGenerated(
        finalText: '## OK',
        type: ReportType.metrics,
        workerName: 'Тестов Т.Т.',
      );
      expect(provider.workerReports.single.finalText, '## OK');
      expect(provider.workerReports.single.rawText, isNull);
    });

    test('rejectReport sets feedback on worker copy', () async {
      final r = await provider.saveGenerated(
        finalText: '## Bad',
        type: ReportType.incident,
        workerName: 'Иванов',
      );
      await provider.sendToManager(r.id);

      final inbox = List<Report>.from(await storage.loadManagerInbox());
      inbox.add(
        (await storage.loadReports()).first.copyWith(status: ReportStatus.sent),
      );
      await storage.saveManagerInbox(inbox);
      await provider.init();

      await provider.rejectReport(r.id, 'Нет фото узла');
      final worker = provider.workerReports.single;
      expect(worker.status, ReportStatus.rejected);
      expect(worker.managerFeedback, 'Нет фото узла');
    });

    test('sendToManager calls mock api', () async {
      final r = await provider.saveGenerated(
        finalText: '## Send me',
        type: ReportType.incident,
        workerName: 'Тестов Т.Т.',
      );
      final ok = await provider.sendToManager(r.id);
      expect(ok, isTrue);
      expect(mockApi.submitted, isTrue);
      expect(provider.workerReports.single.status, ReportStatus.sent);
    });
  });
}
