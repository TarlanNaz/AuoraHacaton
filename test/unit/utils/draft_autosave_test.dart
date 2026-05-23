import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/utils/draft_autosave.dart';

void main() {
  test('flush runs save immediately', () async {
    var count = 0;
    final autosave = DraftAutosave(
      debounce: const Duration(seconds: 10),
      onSave: () async => count++,
    );
    autosave.schedule();
    await autosave.flush();
    expect(count, 1);
    autosave.dispose();
  });
}
