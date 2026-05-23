import 'package:flutter/foundation.dart';

/// Флаги release / debug для MVP «Структуратор».
class AppConfig {
  AppConfig._();

  /// `flutter build apk --release` / `flutter run --release`.
  static bool get isProduction => kReleaseMode;

  /// Подсказка с демо-логинами на экране входа.
  static bool get showDemoLoginHint => !isProduction;

  /// Автозаполнение входящих руководителя примерными отчётами (демо для жюри).
  static bool get seedManagerDemoInbox => true;

  /// Примеры отчётов у рабочего при первом входе.
  static bool get seedWorkerDemoReports => true;

  /// Версия из pubspec (для «О приложении»).
  static const String appVersion = '1.0.0';
  static const int buildNumber = 2;
}
