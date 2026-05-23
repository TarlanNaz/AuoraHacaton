# AGENTS.md

Контракт для AI-агентов (Cursor, Claude Code, Windsurf, Codex CLI, Aider).
Если ты агент — читаешь это первым и следуешь дисциплине ниже. Если человек
— это твой быстрый ввод в проект.

## Что это за проект

**Структуратор** — Flutter-приложение для хакатона «Пульс Авроры». Полевой
сотрудник в оффлайне диктует/печатает сырые заметки; при появлении сети
GigaChat превращает их в формальный markdown-отчёт.

- Стек: Flutter 3.19+, Dart 3.3+, Material 3.
- Хранилище: `shared_preferences` (никаких Firebase / Google).
- Сеть: `package:http` + GigaChat REST.
- State: `provider` (DI через `MultiProvider`).
- Тесты: `flutter_test` + `mocktail` + `integration_test`.

## Архитектура (4 слоя, читать в этом порядке)

```
lib/
├── config/        ← const-конфиг + .env-фасад. ZERO бизнес-логики.
├── models/        ← чистые data-классы, JSON serde.
├── services/      ← I/O: GigaChatService (HTTP), StorageService (prefs).
│                    Объявлены как abstract class — реализации внизу файла.
├── providers/     ← state + оркестрация. Принимают сервисы через
│                    конструктор — НЕ создают их сами.
├── screens/       ← только UI. Никаких http/json/SharedPreferences.
└── utils/         ← input_validator, app_logger.
```

Composition root — `lib/main.dart`. Все зависимости связываются ровно там
через `MultiProvider`.

## Дисциплина (DAE/ATDD-style)

Перед добавлением фичи:

1. Пиши failing acceptance-тест в `test/acceptance/<feature>_acceptance_test.dart`
   на языке UX («When user … then …»).
2. Спускайся вниз: пиши failing unit-тесты в `test/unit/<layer>/...` на
   конкретные публичные методы.
3. Минимально проходящая реализация в `lib/`.
4. Рефактор. Зелёные тесты не должны позеленеть случайно.

Подробности слоёв — `test/README.md`.

## Жёсткие запреты

- **Нет Firebase / Google services / firebase_** (Aurora-совместимость).
- **Нет hardcoded URL / токенов / scope** в `lib/services` и `lib/providers`.
  Всё через `lib/config/api_config.dart` и `lib/config/env.dart`.
- **Нет `print()`** в production-коде. Только `AppLogger.info/warn/error`.
- **Нет `catch (_) {}`**. Любое исключение либо пробрасывается типизированно
  (`GigaChatException`), либо логируется со стек-трейсом.
- **Нет блокирующих UI операций**. Все I/O — через `Future` + `await`.
- **Нет `BuildContext` через async gap без `mounted`-проверки**.

## Безопасность

- Секреты — только в `.env` (gitignored). Шаблон — `.env.example`.
- HTTPS обязателен. `_DevHttpOverrides` отключает SSL-валидацию **только
  в `kDebugMode`** — в release это не работает.
- После успешной структуризации сырой текст **не персистится** в кэше
  (`Report.rawText == null` для не-черновиков).
- Все сетевые запросы проходят через `InputValidator.validateRawNotes`
  (длина, control-chars, prompt-injection маркеры).

## Команды

```bash
# Зависимости
flutter pub get

# Все тесты
flutter test

# Только acceptance (быстро увидеть, что фичи живы)
flutter test test/acceptance/

# Покрытие
flutter test --coverage

# Smoke-test на устройстве/симуляторе
flutter test integration_test/app_smoke_test.dart

# Анализ
flutter analyze

# Запуск
flutter run --dart-define=ENABLE_LOGGING=true
```

## AST-индекс (опционально, для агентов)

Для ускорения навигации по кодовой базе можно поднять локальный индекс
через [Claude-ast-index-search](https://github.com/defendend/Claude-ast-index-search):

```powershell
# Windows
.\scripts\setup-ast-index.ps1

# *nix
./scripts/setup-ast-index.sh
```

После индексации агент может искать символы через
`ast-index search "GigaChatService"` вместо grep по всему репо.

## Caveman mode (экономия токенов)

Если агенту тесно по контексту — переключайся в caveman-mode (см.
`.cursor/rules/40-caveman-mode.mdc` и `docs/caveman-system-prompt.md`).
Принцип: краткие телеграфные предложения, без воды, без лишних слов-связок.

## Куда смотреть в первую очередь

- Архитектура и паттерны: `lib/main.dart` (composition root), `lib/providers/`.
- Контракты сервисов: `lib/services/giga_chat_service.dart` (abstract в верху файла).
- Constants и URLs: `lib/config/api_config.dart`.
- Состояния UI: `lib/providers/generation_provider.dart` (FSM enum).
- Тестовая дисциплина: `test/README.md`.
