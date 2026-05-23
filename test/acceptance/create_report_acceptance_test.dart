import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/models/report_status.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'When user enters raw notes and taps generate, '
    'then a structured report is saved without raw text',
    (tester) async {
      final harness = await pumpStructurator(
        tester,
        giga: FakeGigaChatService(
          response: '## Заголовок\nСтруктурированный текст',
        ),
        manualToken: 'manual-bearer-test',
      );

      await tapNewReport(tester);
      await tester.pumpAndSettle();

      const rawNotes =
          'Данные для отчета Гришиной В.Б.: обработано 45 метрик, '
          'эффективность выросла, нужно добавить диаграммы';
      await tester.enterText(rawNotesTextField(), rawNotes);
      await tester.pump();

      await tapGenerateButton(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Структурированный текст'), findsWidgets);
      expect(find.textContaining('Структурированный текст'), findsWidgets);

      expect(harness.storage.persisted, hasLength(1));
      final saved = harness.storage.persisted.single;
      expect(saved.finalText, contains('Структурированный текст'));
      expect(saved.rawText, isNull);
      expect(saved.status, ReportStatus.draft);

      expect(harness.giga.generateCalls, 1);
      expect(harness.giga.lastSentToken, 'manual-bearer-test');
    },
  );
}
