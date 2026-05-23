import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:structurator/services/location_service.dart';

void main() {
  group('HttpLocationService', () {
    test('searchPlace parses Nominatim JSON', () async {
      final client = _FakeClient(
        200,
        r'[{"display_name":"Murmansk, Russia","lat":"68.9585","lon":"33.0827"}]',
      );
      final service = HttpLocationService(client: client);

      final place = await service.searchPlace('Мурманск');
      expect(place, isNotNull);
      expect(place!.displayName, contains('Murmansk'));
      expect(place.latitude, closeTo(68.9585, 0.001));
    });

    test('searchPlace returns null when list empty', () async {
      final client = _FakeClient(200, '[]');
      final service = HttpLocationService(client: client);
      expect(await service.searchPlace('xyznone123'), isNull);
    });
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.status, this.body);
  final int status;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(body.codeUnits),
      status,
      headers: {'content-type': 'application/json'},
    );
  }
}
