import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Человекочитаемое описание сетевой ошибки (не всё — «нет интернета»).
String describeNetworkFailure(Object error, {String service = 'сервер'}) {
  if (error is TimeoutException) {
    return 'Превышено время ожидания ответа $service. Проверьте сеть и повторите.';
  }
  if (error is HandshakeException) {
    return 'Ошибка защищённого соединения (TLS) с $service. '
        'На Aurora OS проверьте сертификаты или используйте ручной access-токен GigaChat.';
  }
  if (error is TlsException) {
    return 'Ошибка TLS при подключении к $service: ${error.message}';
  }
  if (error is SocketException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('failed host lookup') || msg.contains('no address')) {
      return 'Не удалось найти $service (DNS). Проверьте интернет и DNS.';
    }
    if (msg.contains('connection refused') || msg.contains('connection reset')) {
      return 'Соединение с $service отклонено. Возможна блокировка порта или VPN.';
    }
    return 'Сетевая ошибка при обращении к $service: ${error.message}';
  }
  if (error is http.ClientException) {
    return 'HTTP-клиент: ${error.message}';
  }
  return error.toString();
}
