import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/models/profile_change_draft.dart';

void main() {
  group('ProfileChangeDraft', () {
    test('buildMarkdown lists current and requested fields', () {
      const draft = ProfileChangeDraft(
        newFullName: 'Петров И.И.',
        reason: 'Опечатка при заведении',
      );
      final md = draft.buildMarkdown(
        currentFullName: 'Иванов А.П.',
        login: 'worker',
        currentEmployer: 'АО Тест',
        hasNewPhoto: true,
      );
      expect(md, contains('Иванов А.П.'));
      expect(md, contains('Петров И.И.'));
      expect(md, contains('Приложено новое фото'));
      expect(md, contains('Опечатка'));
    });

    test('roundtrips through JSON in rawText', () {
      const draft = ProfileChangeDraft(
        newEmployer: 'Филиал Север',
        reason: 'Перевод',
      );
      final restored = ProfileChangeDraft.tryParseRaw(draft.encodeRaw());
      expect(restored?.newEmployer, 'Филиал Север');
      expect(restored?.reason, 'Перевод');
    });
  });
}
