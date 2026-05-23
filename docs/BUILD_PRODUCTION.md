# Production-сборка «Структуратор»

## Отличия release от debug

| Поведение | Debug | Release (prod) |
|-----------|-------|----------------|
| Подсказка демо-логинов на входе | Да | Нет |
| Демо-входящие руководителя (3 отчёта) | При первом входе | Нет |
| SSL: ослабленная проверка сертификатов | Только в debug | Нет |
| Логи `AppLogger` | Да | Нет |
| Баннер `debug` | Скрыт | Скрыт |

Демо-учётки `worker` / `manager` в локальном хранилище **остаются** (MVP без корпоративного IdP).

## Подготовка

1. Скопируйте `.env.example` → `.env` и заполните `GIGACHAT_AUTH_KEY`.
2. Если сборка падает на `storage.flutter-io.cn`, отключите зеркало Flutter:
   ```powershell
   Remove-Item Env:FLUTTER_STORAGE_BASE_URL -ErrorAction SilentlyContinue
   Remove-Item Env:PUB_HOSTED_URL -ErrorAction SilentlyContinue
   ```
   Скрипт `build-prod` делает это автоматически.
2. Убедитесь, что `.env` **не** коммитится (уже в `.gitignore`).
3. Ключ попадёт в APK как asset — для публичного магазина позже перейдите на `--dart-define` или backend.

## Сборка

### Windows (PowerShell)

```powershell
.\scripts\build-prod.ps1
```

### Linux / macOS

```bash
chmod +x scripts/build-prod.sh
./scripts/build-prod.sh
```

### Вручную

```bash
flutter pub get
flutter test
flutter analyze lib/
flutter build apk --release
flutter build appbundle --release
```

## Артефакты

| Файл | Назначение |
|------|------------|
| `build/app/outputs/flutter-apk/app-release.apk` | Установка на устройство |
| `build/app/outputs/bundle/release/app-release.aab` | Google Play / RuStore |

## Подпись release

Сейчас APK подписывается debug-ключом (достаточно для хакатона и sideload).

Для магазина создайте keystore и настройте `android/key.properties` (см. [Flutter: signing](https://docs.flutter.dev/deployment/android#signing-the-app)).

## Версия

- `pubspec.yaml`: `version: 1.0.0+2` (`+2` — build number для Android).
- `applicationId`: `ru.pulsaurora.structurator`.

## Проверка на устройстве

```bash
flutter install --release
# или
adb install build/app/outputs/flutter-apk/app-release.apk
```
