import 'package:flutter/foundation.dart';

import '../models/user_role.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;
  UserRole? _role;
  bool _ready = false;

  UserRole? get role => _role;
  bool get isReady => _ready;
  bool get isLoggedIn => _role != null;

  Future<void> init() async {
    _role = await _storage.readRole();
    _ready = true;
    notifyListeners();
  }

  Future<void> login(UserRole role) async {
    _role = role;
    await _storage.saveRole(role);
    notifyListeners();
  }

  Future<void> logout() async {
    _role = null;
    await _storage.saveRole(null);
    notifyListeners();
  }
}
