# Структуратор

Оффлайн-first Flutter-приложение для хакатона **«Пульс Авроры»**: полевой сотрудник фиксирует наблюдения (текст + фото), при появлении сети **GigaChat** оформляет формальный markdown-отчёт, руководитель принимает или отклоняет с замечаниями.

Без Firebase / Google Services — совместимость с **Aurora OS**. Данные на устройстве: `shared_preferences` + локальные файлы фото.

## Возможности

| Роль | Что умеет |
|------|-----------|
| **Рабочий** | Создание отчётов (3 типа), фото, автосохранение черновиков, геокодирование места, генерация ИИ, отправка руководителю |
| **Руководитель** | Список рабочих, входящие с **фильтрами** (дата, тип), просмотр **фото**, шаблоны промптов для ИИ, принять / отклонить |

**Профиль рабочего** — только просмотр (ФИО, фото). Изменение — через отчёт «Изменить данные».

**Регистрации нет** — учётные записи выдаёт администратор (в MVP — демо-логины ниже).

## Два внешних API

| API | Назначение |
|-----|------------|
| **[GigaChat](https://developers.sber.ru/portal/products/gigachat-api)** (Сбер) | OAuth, загрузка фото, структурирование заметок |
| **[OpenStreetMap Nominatim](https://nominatim.org/)** | Геокодирование места объекта перед генерацией |

Подробные эндпоинты и файлы кода — **[docs/APIS.md](docs/APIS.md)**.

Локально (без HTTP): mock-авторизация и mock-доставка отчётов руководителю.

## Быстрый старт

```bash
# 1. Секреты GigaChat
copy .env.example .env          # Windows
# cp .env.example .env          # Linux / macOS
# Заполните GIGACHAT_AUTH_KEY — см. https://developers.sber.ru/portal/products/gigachat-api

# 2. Запуск
flutter pub get
flutter run --dart-define=ENABLE_LOGGING=true
```

### Демо-вход

| Роль | Логин | Пароль |
|------|-------|--------|
| Рабочий | `worker` | `worker123` |
| Руководитель | `manager` | `manager123` |

У рабочего подставляются демо ФИО и фото. При первом входе руководителя загружаются **3 примера отчётов** (инцидент, метрики, визит) с фотографиями.

Опционально: ручной Bearer-токен GigaChat — иконка ключа на дашборде рабочего (если нет `GIGACHAT_AUTH_KEY` в `.env`).

## Архитектура (кратко)

```
lib/
├── config/      # api_config, env, report_prompts
├── models/      # Report, ReportType, AuthSession, …
├── services/    # GigaChat, Location (Nominatim), Storage, Mock API
├── providers/   # state + оркестрация (Provider)
├── screens/     # UI по ролям
└── main.dart    # composition root (MultiProvider)
```

Слои и дисциплина тестов — **[AGENTS.md](AGENTS.md)**.

## Документация

| Документ | Содержание |
|----------|------------|
| **[docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** | Полное руководство: экраны, провайдеры, хранилище, mock-данные |
| **[docs/APIS.md](docs/APIS.md)** | Два внешних HTTP API, эндпоинты |
| **[docs/TOOLS_ROADMAP.md](docs/TOOLS_ROADMAP.md)** | Идеи развития (голос, OCR, корпоративный бэкенд) |
| **[AGENTS.md](AGENTS.md)** | Контракт для AI-агентов, DAE/ATDD |

## Тесты и анализ

```bash
flutter test              # unit + acceptance
flutter test test/acceptance/
flutter analyze
```

## Стек

Flutter 3.19+ · Dart 3.3+ · Material 3 · **Provider** · **http** · **shared_preferences** · **flutter_dotenv** · **image_picker** · **mocktail** (тесты)

## Переменные окружения (`.env`)

| Переменная | Описание |
|------------|----------|
| `GIGACHAT_AUTH_KEY` | Base64 `client_id:client_secret` (без префикса `Basic `) |
| `GIGACHAT_SCOPE` | По умолчанию `GIGACHAT_API_PERS` |
| `GIGACHAT_MODEL` | По умолчанию `GigaChat` |

Шаблон — **[.env.example](.env.example)**.
