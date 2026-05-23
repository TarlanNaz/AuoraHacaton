# Сборка production APK/AAB для «Структуратор»
# Требования: Flutter SDK, файл .env с GIGACHAT_AUTH_KEY

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path ".env")) {
    Write-Error "Создайте .env из .env.example и укажите GIGACHAT_AUTH_KEY"
    exit 1
}

# Китайское зеркало часто ломает release-сборку (storage.flutter-io.cn).
Remove-Item Env:FLUTTER_STORAGE_BASE_URL -ErrorAction SilentlyContinue
Remove-Item Env:PUB_HOSTED_URL -ErrorAction SilentlyContinue

Write-Host "==> flutter pub get"
flutter pub get

Write-Host "==> flutter test"
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter analyze lib/"
flutter analyze lib/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter build apk --release"
flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter build appbundle --release"
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = "build\app\outputs\flutter-apk\app-release.apk"
$aab = "build\app\outputs\bundle\release\app-release.aab"

Write-Host ""
Write-Host "Готово:"
Write-Host "  APK: $apk"
Write-Host "  AAB: $aab"
