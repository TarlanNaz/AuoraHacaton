# Структуратор

Оффлайн-first Flutter-приложение для полевых сотрудников: сырые заметки и фото → структурированный отчёт через **GigaChat** → отправка руководителю с приёмом или отклонением.

Хакатон «Пульс Авроры». Без Firebase, данные на устройстве (`shared_preferences` + локальные файлы).

## Быстрый старт

```bash
copy .env.example .env   # Windows
# Заполните GIGACHAT_AUTH_KEY — https://developers.sber.ru/portal/products/gigachat-api

flutter pub get
flutter run --dart-define=ENABLE_LOGGING=true
```

## Документация

| Документ | Для кого |
|----------|----------|
| **[docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** | Второй разработчик: все функции, роли, архитектура, API провайдеров, хранилище |
| **[docs/TOOLS_ROADMAP.md](docs/TOOLS_ROADMAP.md)** | Идеи инструментов для улучшения генерации (голос, OCR, RAG, чек-листы) |
| **[AGENTS.md](AGENTS.md)** | AI-агенты и дисциплина тестов (DAE/ATDD) |

## Роли в приложении

- **Рабочий** — отчёты, черновики, профиль (ФИО, фото), генерация ИИ, отправка.
- **Руководитель** — список рабочих, входящие, шаблоны промптов, принять / отклонить с замечаниями.

## Тесты

```bash
flutter test
flutter analyze
```

## Стек

Flutter 3.19+, Dart 3.3+, Provider, http, shared_preferences, image_picker, flutter_dotenv.
