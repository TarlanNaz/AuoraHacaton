# Внешние API в проекте «Структуратор»

По заданию хакатона используются **два разных внешних HTTP API** (разные провайдеры и назначение).

## 1. GigaChat API (Сбер)

**Назначение:** OAuth, загрузка фото, генерация структурированного отчёта из сырых заметок.

| Эндпоинт | URL |
|----------|-----|
| OAuth2 | `https://ngw.devices.sberbank.ru:9443/api/v2/oauth` |
| Chat Completions | `https://gigachat.devices.sberbank.ru/api/v1/chat/completions` |
| Files (фото) | `https://gigachat.devices.sberbank.ru/api/v1/files` |

**Код:** `lib/services/giga_chat_service.dart`  
**Конфиг:** `lib/config/api_config.dart`, секреты в `.env` (`GIGACHAT_*`).

---

## 2. OpenStreetMap Nominatim (геокодирование)

**Назначение:** уточнение места объекта по тексту (цех, узел, город) перед генерацией отчёта; координаты и адрес попадают в системный промпт GigaChat.

| Эндпоинт | URL |
|----------|-----|
| Search | `https://nominatim.openstreetmap.org/search` |

**Код:** `lib/services/location_service.dart`  
**UI:** поле «Место / объект» на экране создания отчёта, кнопка с иконкой карты.

**Правила использования:** обязателен заголовок `User-Agent` (задан в `ApiConfig.nominatimUserAgent`).

---

## Что не считается внешним API

| Компонент | Почему |
|-----------|--------|
| `MockReportApiService` | Локальная имитация корпоративного портала (`shared_preferences`), без HTTP |
| `LocalMockAuthService` | Локальные демо-учётки |
| `shared_preferences` / файлы фото | Хранилище на устройстве |

При появлении реального бэкенда отчётов его можно оформить как **третий** API (`CORPORATE_API_BASE_URL` в `.env` — зарезервировано в roadmap).
