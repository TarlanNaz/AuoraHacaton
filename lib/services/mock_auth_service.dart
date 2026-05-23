import 'package:uuid/uuid.dart';

import '../config/auth_stubs.dart';
import '../models/auth_session.dart';
import '../models/stored_user.dart';
import '../models/user_role.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Локальный вход без сети (заглушка). Учётные записи задаются администратором.
abstract class MockAuthService {
  Future<void> ensureSeeded();
  Future<AuthSession> login({
    required String login,
    required String password,
  });
  Future<AuthSession?> readSession();
  Future<void> saveSession(AuthSession? session);
}

class LocalMockAuthService implements MockAuthService {
  LocalMockAuthService(this._storage);

  static const _tag = 'MockAuthService';
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> ensureSeeded() async {
    var users = await _storage.loadAuthUsers();
    if (users.isNotEmpty) return;

    final now = DateTime.now();
    users = AuthStubs.seedAccounts
        .map(
          (a) => StoredUser(
            id: _uuid.v4(),
            login: a.login,
            password: a.password,
            role: a.role,
            displayName: a.name,
            createdAt: now,
          ),
        )
        .toList();
    await _storage.saveAuthUsers(users);
    AppLogger.info(_tag, 'seeded ${users.length} demo accounts');
  }

  @override
  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    await ensureSeeded();
    final normalized = _normalizeLogin(login);
    final users = await _storage.loadAuthUsers();
    final matches = users.where((u) => u.login == normalized).toList();
    if (matches.isEmpty) {
      throw AuthException('Пользователь «$login» не найден');
    }
    final user = matches.first;
    if (user.password != password) {
      throw AuthException('Неверный пароль');
    }
    final session = AuthSession(
      userId: user.id,
      login: user.login,
      role: user.role,
      displayName: user.displayName,
    );
    await saveSession(session);
    return session;
  }

  @override
  Future<AuthSession?> readSession() => _storage.readAuthSession();

  @override
  Future<void> saveSession(AuthSession? session) =>
      _storage.saveAuthSession(session);

  String _normalizeLogin(String login) => login.trim().toLowerCase();
}
