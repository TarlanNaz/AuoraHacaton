# Claude Code instructions for Структуратор

> Полная версия инструкций — в корневом [`AGENTS.md`](../AGENTS.md). Этот файл
> только подчёркивает то, что важно именно Claude Code, и обходит подводные
> камни инструмента.

## Стиль ответов

- Отвечай по-русски, если пользователь пишет по-русски.
- Без эмодзи в коде и сообщениях, только если попросили.
- Перед серьёзными правками — короткий план (3-5 пунктов).

## Работа с кодом

- Читай файлы целиком перед правкой — модель `Report` и провайдеры
  взаимосвязаны, частичные изменения ломают тесты.
- Не дублируй код в каждом экране — общие утилиты в `lib/utils/`.
- Для нового сервиса всегда: `abstract class Foo` + реализация
  `HttpFoo` / `SharedPrefsFoo`. DI через `MultiProvider` в `main.dart`.

## Дисциплина TDD (DAE)

Перед фичей:

1. `test/acceptance/<feature>_acceptance_test.dart` — failing.
2. `test/unit/<layer>/...` — failing на публичные API.
3. Минимальная реализация.
4. Рефактор.

Запрещено мёрджить «зелёным» без acceptance-теста на новую фичу.

## Запреты (повтор из AGENTS.md)

- ✗ Firebase / Google services
- ✗ hardcoded URL/токены в `lib/services`, `lib/providers`
- ✗ `print()` (используй `AppLogger`)
- ✗ `catch (_) {}` (silent failures)
- ✗ `BuildContext` после `await` без `mounted`-проверки

## Команды для проверки результата

Перед тем как объявить задачу завершённой:

```bash
flutter analyze
flutter test
```

Оба должны быть зелёными. Если красный analyze — чини сразу.

## AST-индекс

Если репо разрослось и поиск по grep тормозит — собери AST-индекс:

```bash
./scripts/setup-ast-index.sh   # или setup-ast-index.ps1 на Windows
```

После сборки используй `ast-index search "<symbol>"` вместо `rg`/`grep`.
