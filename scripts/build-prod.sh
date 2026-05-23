#!/usr/bin/env bash
# Сборка production APK/AAB для «Структуратор»
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Создайте .env из .env.example и укажите GIGACHAT_AUTH_KEY" >&2
  exit 1
fi

unset FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL 2>/dev/null || true

flutter pub get
flutter test
flutter analyze lib/

flutter build apk --release
flutter build appbundle --release

echo ""
echo "Готово:"
echo "  APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  AAB: build/app/outputs/bundle/release/app-release.aab"
