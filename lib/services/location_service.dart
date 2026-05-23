import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/geo_place.dart';
import '../utils/app_logger.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Геокодирование места объекта (второй внешний HTTP API).
abstract class LocationService {
  Future<GeoPlace?> searchPlace(String query);
}

class HttpLocationService implements LocationService {
  HttpLocationService({http.Client? client}) : _client = client ?? http.Client();

  static const _tag = 'LocationService';
  final http.Client _client;

  @override
  Future<GeoPlace?> searchPlace(String query) async {
    final q = query.trim();
    if (q.length < 3) {
      throw LocationException('Укажите место не короче 3 символов');
    }

    final uri = Uri.parse(ApiConfig.nominatimSearchUrl).replace(
      queryParameters: {
        'q': q,
        'format': 'json',
        'limit': '1',
        'accept-language': 'ru',
      },
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {'User-Agent': ApiConfig.nominatimUserAgent},
          )
          .timeout(ApiConfig.geocodingTimeout);

      if (response.statusCode == 429) {
        throw LocationException(
          'Слишком много запросов к картам. Подождите минуту.',
        );
      }
      if (response.statusCode != 200) {
        throw LocationException(
          'Сервис геокодирования недоступен (HTTP ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        return null;
      }

      final first = decoded.first;
      if (first is! Map<String, dynamic>) return null;

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      final name = first['display_name'] as String?;
      if (lat == null || lon == null || name == null || name.isEmpty) {
        return null;
      }

      AppLogger.info(_tag, 'resolved: $name');
      return GeoPlace(
        displayName: name,
        latitude: lat,
        longitude: lon,
      );
    } on SocketException {
      throw LocationException(
        'Нет интернета: не удалось уточнить место на карте.',
      );
    } catch (e, st) {
      if (e is LocationException) rethrow;
      AppLogger.error(_tag, 'geocode failed', error: e, stackTrace: st);
      throw LocationException('Ошибка геокодирования: $e');
    }
  }
}
