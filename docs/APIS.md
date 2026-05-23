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

## 2. Геопозиция и геокодирование

### GPS на устройстве (без API Яндекса)

**Назначение:** получить текущие координаты с GPS/сети (кнопка «Моё местоположение»).

| Компонент | Технология |
|-----------|------------|
| Координаты | `geolocator` (GPS / Fused Location) |
| Разрешения | `ACCESS_FINE_LOCATION` в AndroidManifest |

Яндекс API для GPS **не нужен** — координаты даёт сам телефон.

### OpenStreetMap Nominatim (адрес по тексту / по координатам)

**Назначение:** поиск адреса по вводу и обратное геокодирование после GPS; место **сохраняется в черновик** (`locationQuery`, `locationLat`, `locationLon`).

| Эндпоинт | URL |
|----------|-----|
| Search | `https://nominatim.openstreetmap.org/search` |
| Reverse | `https://nominatim.openstreetmap.org/reverse` |

**Код:** `lib/services/location_service.dart`  
**UI:** «Место / объект», «Моё местоположение», «Уточнить адрес».

**Правила:** заголовок `User-Agent` (`ApiConfig.nominatimUserAgent`).

### Какой API выбрать в кабинете Яндекса (если переходите с Nominatim)

| Задача | API в консоли Яндекса |
|--------|------------------------|
| Адрес по координатам (после GPS) | **API Геокодера** — то, что на вашем скриншоте |
| Подсказки при вводе адреса | **API Геосаджеста** |
| Позиция только по Wi‑Fi/сотам без GPS | API Яндекс Локатора (редко нужно в поле) |

Для «Структуратора» достаточно: **GPS + API Геокодера** (или Nominatim, как сейчас).

---

## GigaChat: «нет интернета» при рабочей сети

Сообщение `Нет интернета: невозможно получить access-токен` часто означает не отсутствие Wi‑Fi, а:

1. **Ошибка TLS** к `ngw.devices.sberbank.ru:9443` (на Aurora OS нет корневого сертификата Сбера).
2. **Блокировка порта 9443** корпоративным VPN/файрволом.
3. **Пустой или неверный** `GIGACHAT_AUTH_KEY` в `.env`.

**Обход для демо:** иконка ключа на дашборде рабочего → вставить **access_token** из личного кабинета GigaChat вручную (живёт ~30 мин).

Проверьте `.env`:

```env
GIGACHAT_AUTH_KEY=<base64 client_id:client_secret без префикса Basic>
GIGACHAT_SCOPE=GIGACHAT_API_PERS
```

---

## Что не считается внешним API

| Компонент | Почему |
|-----------|--------|
| `MockReportApiService` | Локальная имитация корпоративного портала (`shared_preferences`), без HTTP |
| `LocalMockAuthService` | Локальные демо-учётки |
| `shared_preferences` / файлы фото | Хранилище на устройстве |

При появлении реального бэкенда отчётов его можно оформить как **третий** API (`CORPORATE_API_BASE_URL` в `.env` — зарезервировано в roadmap).
