import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/models/report.dart';
import 'package:structurator/models/report_status.dart';
import 'package:structurator/models/report_type.dart';

void main() {
  group('Report', () {
    test('roundtrips through JSON without loss', () {
      final original = Report(
        id: 'abc-1',
        rawText: 'raw notes',
        finalText: '## Title\nBody',
        type: ReportType.metrics,
        status: ReportStatus.synced,
        createdAt: DateTime.parse('2026-05-23T10:00:00Z'),
      );

      final json = original.toJson();
      final restored = Report.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.rawText, original.rawText);
      expect(restored.finalText, original.finalText);
      expect(restored.createdAt, original.createdAt);
      expect(restored.status, original.status);
    });

    test('handles null rawText (cleaned report)', () {
      final r = Report(
        id: 'abc-2',
        rawText: null,
        finalText: '## Title',
        type: ReportType.incident,
        status: ReportStatus.sent,
        createdAt: DateTime.now(),
      );
      final restored = Report.fromJson(r.toJson());
      expect(restored.rawText, isNull);
      expect(restored.hasRawData, isFalse);
      expect(restored.hasStructured, isTrue);
    });

    test('copyWith(clearRawText: true) wipes rawText', () {
      final r = Report(
        id: 'x',
        rawText: 'sensitive',
        finalText: '## ok',
        type: ReportType.incident,
        status: ReportStatus.synced,
        createdAt: DateTime.now(),
      );
      final cleaned = r.copyWith(clearRawText: true);
      expect(cleaned.rawText, isNull);
      expect(cleaned.finalText, '## ok');
    });

    test('title strips markdown markers and falls back gracefully', () {
      final empty = Report(
        id: '1',
        rawText: null,
        finalText: null,
        type: ReportType.metrics,
        status: ReportStatus.draft,
        createdAt: DateTime.now(),
      );
      expect(empty.title, ReportType.metrics.label);

      final structured = Report(
        id: '2',
        rawText: null,
        finalText: '## **Отчёт по Гришиной**\nТекст…',
        type: ReportType.clientVisit,
        status: ReportStatus.draft,
        createdAt: DateTime.now(),
      );
      expect(structured.title, 'Отчёт по Гришиной');
    });
  });
}
