import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/geo_place.dart';
import '../utils/app_logger.dart';
import '../utils/network_errors.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Геопозиция GPS + геокодирование (Nominatim; опционально Yandex — см. docs).
abstract class LocationService {
  Future<GeoPlace?> searchPlace(String query);
  Future<GeoPlace?> reverseGeocode(double latitude, double longitude);
  Future<GeoPlace> getCurrentPosition();
}

class HttpLocationService implements LocationService {
  HttpLocationService({http.Client? client}) : _client = client ?? http.Client();

  static const _tag = 'LocationService';
  final http.Client _client;

  @override
  Future<GeoPlace> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(
        'Геолокация на устройстве выключена. Включите GPS в настройках.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Нет доступа к геопозиции.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Доступ к геопозиции запрещён. Разрешите в настройках приложения.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final reversed = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      final place = reversed ??
          GeoPlace(
            displayName:
                'Координаты ${position.latitude.toStringAsFixed(5)}, '
                '${position.longitude.toStringAsFixed(5)}',
            latitude: position.latitude,
            longitude: position.longitude,
          );

      AppLogger.info(_tag, 'gps: ${place.displayName}');
      return place;
    } on LocationException {
      rethrow;
    } catch (e, st) {
      AppLogger.error(_tag, 'gps failed', error: e, stackTrace: st);
      throw LocationException('Не удалось определить геопозицию: $e');
    }
  }

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

    final list = await _getJsonList(uri);
    if (list == null || list.isEmpty) return null;
    return _parseNominatimItem(list.first);
  }

  @override
  Future<GeoPlace?> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse(ApiConfig.nominatimReverseUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'accept-language': 'ru',
      },
    );

    final map = await _getJsonMap(uri);
    if (map == null) return null;

    final name = map['display_name'] as String?;
    if (name == null || name.isEmpty) return null;

    return GeoPlace(
      displayName: name,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<dynamic>?> _getJsonList(Uri uri) async {
    final decoded = await _getJson(uri);
    return decoded is List ? decoded : null;
  }

  Future<Map<String, dynamic>?> _getJsonMap(Uri uri) async {
    final decoded = await _getJson(uri);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<dynamic> _getJson(Uri uri) async {
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

      return jsonDecode(response.body);
    } on LocationException {
      rethrow;
    } catch (e, st) {
      if (e is LocationException) rethrow;
      AppLogger.error(_tag, 'geocode http failed', error: e, stackTrace: st);
      throw LocationException(
        describeNetworkFailure(e, service: 'картами (Nominatim)'),
      );
    }
  }

  GeoPlace? _parseNominatimItem(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    final name = item['display_name'] as String?;
    if (lat == null || lon == null || name == null || name.isEmpty) {
      return null;
    }
    return GeoPlace(displayName: name, latitude: lat, longitude: lon);
  }
}
