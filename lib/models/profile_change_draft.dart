import 'dart:convert';

/// Поля формы запроса на изменение данных профиля (хранятся в [Report.rawText]).
class ProfileChangeDraft {
  const ProfileChangeDraft({
    this.newFullName = '',
    this.newEmployer = '',
    required this.reason,
    this.notes = '',
  });

  final String newFullName;
  final String newEmployer;
  final String reason;
  final String notes;

  bool get hasAnyChange =>
      newFullName.trim().isNotEmpty ||
      newEmployer.trim().isNotEmpty ||
      notes.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'newFullName': newFullName,
        'newEmployer': newEmployer,
        'reason': reason,
        'notes': notes,
      };

  factory ProfileChangeDraft.fromJson(Map<String, dynamic> json) {
    return ProfileChangeDraft(
      newFullName: json['newFullName'] as String? ?? '',
      newEmployer: json['newEmployer'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  static ProfileChangeDraft? tryParseRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ProfileChangeDraft.fromJson(decoded);
      }
    } catch (_) {
      // Старые черновики — plain text в reason.
      return ProfileChangeDraft(reason: raw);
    }
    return null;
  }

  String encodeRaw() => jsonEncode(toJson());

  /// Формальный markdown для руководителя (без GigaChat).
  String buildMarkdown({
    required String currentFullName,
    required String login,
    required String currentEmployer,
    required bool hasNewPhoto,
  }) {
    final fioLine = newFullName.trim().isEmpty
        ? '— без изменений'
        : newFullName.trim();
    final employerLine = newEmployer.trim().isEmpty
        ? '— без изменений'
        : newEmployer.trim();
    final photoLine =
        hasNewPhoto ? 'Приложено новое фото' : '— без изменений';

    return '''
## Запрос на изменение персональных данных

## Текущие данные в системе
- **ФИО:** $currentFullName
- **Логин:** $login
- **Место работы:** $currentEmployer

## Запрашиваемые изменения
- **ФИО:** $fioLine
- **Место работы:** $employerLine
- **Фото профиля:** $photoLine

## Причина
${reason.trim().isEmpty ? 'не указано' : reason.trim()}

## Дополнительно
${notes.trim().isEmpty ? '—' : notes.trim()}
'''.trim();
  }
}
