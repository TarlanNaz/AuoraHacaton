import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:structurator/services/giga_chat_service.dart';

void main() {
  group('HttpGigaChatService.generateReport', () {
    test('parses GigaChat success response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '## Готовый отчёт\nДетали',
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpGigaChatService(client: mockClient);
      final answer = await service.generateReport(
        token: 'bearer-x',
        rawText: 'обработано 45 метрик, эффективность выросла',
      );

      expect(answer, contains('Готовый отчёт'));
    });

    test('maps 401 to readable GigaChatException', () async {
      final mockClient = MockClient((req) async {
        return http.Response('Unauthorized', 401);
      });
      final service = HttpGigaChatService(client: mockClient);

      expect(
        () => service.generateReport(
          token: 'bad',
          rawText: 'обработано 45 метрик, всё ок',
        ),
        throwsA(
          isA<GigaChatException>().having(
            (e) => e.message,
            'message',
            contains('недействителен'),
          ),
        ),
      );
    });

    test('maps 429 to "слишком много запросов"', () async {
      final mockClient = MockClient((req) async {
        return http.Response('Too Many Requests', 429);
      });
      final service = HttpGigaChatService(client: mockClient);

      expect(
        () => service.generateReport(
          token: 't',
          rawText: 'обработано 45 метрик, эффективность выросла',
        ),
        throwsA(isA<GigaChatException>().having(
          (e) => e.message,
          'message',
          contains('Слишком много запросов'),
        )),
      );
    });

    test('maps SocketException to "нет интернета"', () async {
      final mockClient = MockClient((req) async {
        throw const SocketException('offline');
      });
      final service = HttpGigaChatService(client: mockClient);

      expect(
        () => service.generateReport(
          token: 't',
          rawText: 'обработано 45 метрик, эффективность выросла',
        ),
        throwsA(isA<GigaChatException>().having(
          (e) => e.message,
          'message',
          contains('Нет интернета'),
        )),
      );
    });

    test('rejects invalid input before sending request', () async {
      var called = false;
      final mockClient = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = HttpGigaChatService(client: mockClient);

      expect(
        () => service.generateReport(token: 't', rawText: ''),
        throwsA(isA<GigaChatException>()),
      );
      expect(called, isFalse,
          reason: 'Невалидный ввод не должен отправляться в API');
    });
  });

  group('HttpGigaChatService.obtainAccessToken', () {
    test('parses access_token and expires_at', () async {
      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'access_token': 'fresh-token',
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          }),
          200,
        );
      });
      final service = HttpGigaChatService(client: mockClient);
      final token = await service.obtainAccessToken(authKey: 'base64-key');

      expect(token.accessToken, 'fresh-token');
      expect(token.isExpired, isFalse);
    });

    test('throws on empty authKey without making a network call', () async {
      var called = false;
      final mockClient = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = HttpGigaChatService(client: mockClient);

      expect(
        () => service.obtainAccessToken(authKey: '   '),
        throwsA(isA<GigaChatException>()),
      );
      expect(called, isFalse);
    });
  });
}
