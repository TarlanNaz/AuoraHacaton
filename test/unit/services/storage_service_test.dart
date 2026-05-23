import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structurator/config/storage_keys.dart';
import 'package:structurator/models/report.dart';
import 'package:structurator/models/report_status.dart';
import 'package:structurator/models/report_type.dart';
import 'package:structurator/services/storage_service.dart';

void main() {
  group('SharedPrefsStorageService', () {
    late SharedPrefsStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPrefsStorageService();
    });

    test('returns empty list when no data persisted', () async {
      final reports = await storage.loadReports();
      expect(reports, isEmpty);
    });

    test('roundtrips reports through preferences', () async {
      final original = [
        Report(
          id: '1',
          rawText: null,
          finalText: '## Заголовок',
          type: ReportType.metrics,
          status: ReportStatus.synced,
          createdAt: DateTime.parse('2026-05-23T10:00:00Z'),
        ),
        Report(
          id: '2',
          rawText: 'черновик с данными',
          finalText: null,
          type: ReportType.incident,
          status: ReportStatus.draft,
          createdAt: DateTime.parse('2026-05-23T11:00:00Z'),
        ),
      ];

      await storage.saveReports(original);
      final loaded = await storage.loadReports();

      expect(loaded.map((r) => r.id), ['1', '2']);
      expect(loaded[0].rawText, isNull);
      expect(loaded[1].rawText, 'черновик с данными');
      expect(loaded[1].isDraft, isTrue);
    });

    test('handles corrupted JSON without throwing', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.reports: '{not valid json',
      });
      final storage = SharedPrefsStorageService();
      final reports = await storage.loadReports();
      expect(reports, isEmpty,
          reason: 'Битый кэш не должен ронять приложение, '
              'но ошибка должна залогироваться (см. AppLogger)');
    });

    test('manual token: save / read / clear', () async {
      expect(await storage.readManualToken(), isNull);

      await storage.saveManualToken('  bearer-xyz  ');
      expect(await storage.readManualToken(), 'bearer-xyz');

      await storage.saveManualToken('');
      expect(await storage.readManualToken(), isNull,
          reason: 'Пустая строка должна стирать ручной override');
    });
  });
}
