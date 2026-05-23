import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/config/auth_stubs.dart';
import 'package:structurator/models/user_role.dart';
import 'package:structurator/services/mock_auth_service.dart';

import '../../helpers/fakes.dart';

void main() {
  group('LocalMockAuthService', () {
    late FakeStorageService storage;
    late LocalMockAuthService auth;

    setUp(() {
      storage = FakeStorageService();
      auth = LocalMockAuthService(storage);
    });

    test('seeds demo worker and manager', () async {
      await auth.ensureSeeded();
      final users = await storage.loadAuthUsers();
      expect(users.length, 2);
    });

    test('login with demo worker credentials', () async {
      final session = await auth.login(
        login: AuthStubs.workerLogin,
        password: AuthStubs.workerPassword,
      );
      expect(session.role, UserRole.worker);
    });

    test('login rejects wrong password', () async {
      await auth.ensureSeeded();
      expect(
        () => auth.login(
          login: AuthStubs.workerLogin,
          password: 'wrong-password',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
