import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/config/report_prompts.dart';
import 'package:structurator/providers/generation_provider.dart';
import 'package:structurator/services/giga_chat_service.dart';

import '../../helpers/fakes.dart';

void main() {
  group('GenerationProvider FSM', () {
    test('starts in empty state', () {
      final p = GenerationProvider(service: FakeGigaChatService());
      expect(p.status, GenerationStatus.empty);
      expect(p.result, isNull);
      expect(p.error, isNull);
    });

    test('happy path: empty → loading → success', () async {
      final fake = FakeGigaChatService(response: '## Готовый отчёт\nДетали');
      final p = GenerationProvider(service: fake);

      final transitions = <GenerationStatus>[];
      p.addListener(() => transitions.add(p.status));

      await p.generate(
        rawText: 'данные для отчета — обработано 45 метрик, всё ок',
        tokenResolver: () async => 'bearer-xxx',
      );

      expect(transitions, contains(GenerationStatus.loading));
      expect(p.status, GenerationStatus.success);
      expect(p.result, contains('Готовый отчёт'));
      expect(fake.generateCalls, 1);
      expect(fake.lastSentToken, 'bearer-xxx');
    });

    test('validation failure is reported, no network call', () async {
      final fake = FakeGigaChatService();
      final p = GenerationProvider(service: fake);

      await p.generate(rawText: '', tokenResolver: () async => 'tok');

      expect(p.status, GenerationStatus.error);
      expect(p.error, isNotNull);
      expect(fake.generateCalls, 0);
    });

    test('reject marker from model shows incorrect formulation error', () async {
      final fake = FakeGigaChatService(
        response: '${ReportPrompts.inputInvalidMarker}: только тест',
      );
      final p = GenerationProvider(service: fake);

      await p.generate(
        rawText: 'обработано 45 метрик, всё хорошо',
        tokenResolver: () async => 'tok',
      );

      expect(p.status, GenerationStatus.error);
      expect(p.error, contains('некорректно'));
      expect(p.result, isNull);
    });

    test('GigaChatException propagates as readable error', () async {
      final fake = FakeGigaChatService(
        error: GigaChatException('Нет интернета'),
      );
      final p = GenerationProvider(service: fake);

      await p.generate(
        rawText: 'обработано 45 метрик, всё хорошо',
        tokenResolver: () async => 'tok',
      );

      expect(p.status, GenerationStatus.error);
      expect(p.error, 'Нет интернета');
      expect(p.result, isNull);
    });

    test('reset clears all state back to empty', () async {
      final fake = FakeGigaChatService(response: '## ok');
      final p = GenerationProvider(service: fake);

      await p.generate(
        rawText: 'обработано 45 метрик корректно',
        tokenResolver: () async => 't',
      );
      expect(p.status, GenerationStatus.success);

      p.reset();
      expect(p.status, GenerationStatus.empty);
      expect(p.result, isNull);
      expect(p.error, isNull);
    });
  });
}
