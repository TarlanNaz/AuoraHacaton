import 'dart:async';

/// Debounced автосохранение (пауза ввода → один вызов [onSave]).
class DraftAutosave {
  DraftAutosave({
    required Duration debounce,
    required Future<void> Function() onSave,
  })  : _debounce = debounce,
        _onSave = onSave;

  final Duration _debounce;
  final Future<void> Function() _onSave;

  Timer? _timer;
  bool _saveInFlight = false;
  bool _dirtyWhileSaving = false;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, _runSave);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    await _runSave();
  }

  Future<void> _runSave() async {
    if (_saveInFlight) {
      _dirtyWhileSaving = true;
      return;
    }
    _saveInFlight = true;
    try {
      await _onSave();
    } finally {
      _saveInFlight = false;
      if (_dirtyWhileSaving) {
        _dirtyWhileSaving = false;
        schedule();
      }
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
