# Внешние API в проекте «Структуратор»

Для демо и хакатона используется **один внешний HTTP API** — GigaChat (Сбер).

## GigaChat API (Сбер)

**Назначение:** OAuth, загрузка фото, генерация структурированного отчёта из сырых заметок.

| Эндпоинт | URL |
|----------|-----|
| OAuth2 | `https://ngw.devices.sberbank.ru:9443/api/v2/oauth` |
| Chat Completions | `https://gigachat.devices.sberbank.ru/api/v1/chat/completions` |
| Files (фото) | `https://gigachat.devices.sberbank.ru/api/v1/files` |

**Код:** `lib/services/giga_chat_service.dart`  
**Конфиг:** `lib/config/api_config.dart`, секреты в `.env` (`GIGACHAT_*`).

---

## Место объекта

Указывается **текстом** в поле «Место / объект» и сохраняется в черновик (`locationQuery`, `locationName`). GPS и карты в демо-версии не используются.

---

## GigaChat: «нет интернета» при рабочей сети

Сообщение про отсутствие интернета часто означает не Wi‑Fi, а:

1. **Ошибка TLS** к `ngw.devices.sberbank.ru:9443` (на Aurora OS).
2. **Блокировка порта 9443** VPN/файрволом.
3. **Пустой** `GIGACHAT_AUTH_KEY` в `.env`.

**Обход для демо:** иконка ключа на дашборде рабочего → вставить **access_token** из личного кабинета GigaChat.

---

## Что не считается внешним API

| Компонент | Почему |
|-----------|--------|
| `MockReportApiService` | Локальная имитация корпоративного портала (`shared_preferences`) |
| `LocalMockAuthService` | Локальные демо-учётки |
| `DemoDataSeeder` | Примеры отчётов при первом входе |
| `shared_preferences` / файлы фото | Хранилище на устройстве |
