import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/user_role.dart';
import '../services/mock_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required StorageService storage,
    required MockAuthService authService,
  })  : _storage = storage,
        _auth = authService;

  static const _tag = 'AuthProvider';

  final StorageService _storage;
  final MockAuthService _auth;

  AuthSession? _session;
  bool _ready = false;
  String? _lastError;

  AuthSession? get session => _session;
  UserRole? get role => _session?.role;
  String? get userLogin => _session?.login;
  String? get displayName => _session?.displayName;
  bool get isReady => _ready;
  bool get isLoggedIn => _session != null;
  String? get lastError => _lastError;

  Future<void> init() async {
    await _auth.ensureSeeded();
    _session = await _auth.readSession();
    _ready = true;
    notifyListeners();
  }

  Future<bool> login({
    required String login,
    required String password,
  }) async {
    _lastError = null;
    try {
      _session = await _auth.login(login: login, password: password);
      await _syncWorkerProfileFromSession();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      AppLogger.warn(_tag, 'login failed: ${e.message}');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _session = null;
    _lastError = null;
    await _auth.saveSession(null);
    notifyListeners();
  }

  Future<void> _syncWorkerProfileFromSession() async {
    // Профиль рабочего обновляется в WorkerProfileProvider.applyFromAuthSession.
  }
}
