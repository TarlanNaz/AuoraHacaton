import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/config/report_prompts.dart';
import 'package:structurator/models/report_status.dart';
import 'package:structurator/services/giga_chat_service.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'When network fails, then draft autosaves locally with raw data preserved',
    (tester) async {
      final harness = await pumpStructurator(
        tester,
        giga: FakeGigaChatService(
          error: GigaChatException('Нет интернета. Проверьте соединение.'),
        ),
        manualToken: 'tok-x',
      );

      await tester.tap(find.text('Новый отчёт'));
      await tester.pumpAndSettle();

      const rawNotes = 'обработано 45 метрик, нет сети сейчас';
      await tester.enterText(rawNotesTextField(), rawNotes);
      await tester.pump(ReportPrompts.draftAutosaveDebounce);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сгенерировать'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Нет интернета'), findsWidgets);

      await tester.enterText(rawNotesTextField(), '$rawNotes дополнение');
      await tester.pump(ReportPrompts.draftAutosaveDebounce);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Мои отчёты'), findsOneWidget);
      expect(find.text('Черновик'), findsOneWidget);

      expect(harness.storage.persisted, hasLength(1));
      final draft = harness.storage.persisted.single;
      expect(draft.status, ReportStatus.draft);
      expect(draft.rawText, contains('обработано 45 метрик'));
      expect(draft.finalText, isNull);
    },
  );
}
