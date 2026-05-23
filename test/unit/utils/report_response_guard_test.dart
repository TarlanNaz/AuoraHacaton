import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/config/report_prompts.dart';
import 'package:structurator/services/giga_chat_service.dart';
import 'package:structurator/utils/report_response_guard.dart';

void main() {
  group('ReportResponseGuard', () {
    test('detects reject marker', () {
      expect(
        ReportResponseGuard.isRejected(
          '${ReportPrompts.inputInvalidMarker}: мало фактов',
        ),
        isTrue,
      );
    });

    test('ensureValidReport throws user-friendly message', () {
      expect(
        () => ReportResponseGuard.ensureValidReport(
          '${ReportPrompts.inputInvalidMarker}: текст не по теме',
        ),
        throwsA(
          isA<GigaChatException>().having(
            (e) => e.message,
            'message',
            contains('некорректно'),
          ),
        ),
      );
    });

    test('valid markdown passes through', () {
      expect(
        () => ReportResponseGuard.ensureValidReport('## Заголовок\nФакт'),
        returnsNormally,
      );
    });
  });
}
