import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/storage_keys.dart';
import '../models/auth_session.dart';
import '../models/report.dart';
import '../models/report_template.dart';
import '../models/stored_user.dart';
import '../models/user_role.dart';
import '../models/worker_profile.dart';
import '../utils/app_logger.dart';

abstract class StorageService {
  Future<List<Report>> loadReports();
  Future<void> saveReports(List<Report> reports);
  Future<void> saveManualToken(String token);
  Future<String?> readManualToken();
  Future<void> clearReports();

  Future<UserRole?> readRole();
  Future<void> saveRole(UserRole? role);

  Future<List<ReportTemplate>> loadTemplates();
  Future<void> saveTemplates(List<ReportTemplate> templates);

  Future<List<Report>> loadManagerInbox();
  Future<void> saveManagerInbox(List<Report> reports);

  Future<List<String>> loadSendQueue();
  Future<void> saveSendQueue(List<String> reportIds);

  Future<bool> isMockInboxSeeded();
  Future<void> setMockInboxSeeded();

  Future<WorkerProfile?> loadWorkerProfile();
  Future<void> saveWorkerProfile(WorkerProfile profile);

  Future<List<StoredUser>> loadAuthUsers();
  Future<void> saveAuthUsers(List<StoredUser> users);
  Future<AuthSession?> readAuthSession();
  Future<void> saveAuthSession(AuthSession? session);
}

class SharedPrefsStorageService implements StorageService {
  static const _tag = 'StorageService';

  Future<List<T>> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return <T>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } catch (e, st) {
      AppLogger.error(_tag, 'load $key failed', error: e, stackTrace: st);
      return <T>[];
    }
  }

  Future<void> _saveList<T>(String key, List<T> items, Object? Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => toJson(e)).toList());
    await prefs.setString(key, encoded);
  }

  @override
  Future<List<Report>> loadReports() =>
      _loadList(StorageKeys.reports, Report.fromJson);

  @override
  Future<void> saveReports(List<Report> reports) =>
      _saveList(StorageKeys.reports, reports, (r) => r.toJson());

  @override
  Future<void> saveManualToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.trim().isEmpty) {
      await prefs.remove(StorageKeys.manualToken);
    } else {
      await prefs.setString(StorageKeys.manualToken, token.trim());
    }
  }

  @override
  Future<String?> readManualToken() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(StorageKeys.manualToken);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.reports);
  }

  @override
  Future<UserRole?> readRole() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRole.fromId(prefs.getString(StorageKeys.userRole));
  }

  @override
  Future<void> saveRole(UserRole? role) async {
    final prefs = await SharedPreferences.getInstance();
    if (role == null) {
      await prefs.remove(StorageKeys.userRole);
    } else {
      await prefs.setString(StorageKeys.userRole, role.id);
    }
  }

  @override
  Future<List<ReportTemplate>> loadTemplates() =>
      _loadList(StorageKeys.templates, ReportTemplate.fromJson);

  @override
  Future<void> saveTemplates(List<ReportTemplate> templates) =>
      _saveList(StorageKeys.templates, templates, (t) => t.toJson());

  @override
  Future<List<Report>> loadManagerInbox() =>
      _loadList(StorageKeys.managerInbox, Report.fromJson);

  @override
  Future<void> saveManagerInbox(List<Report> reports) =>
      _saveList(StorageKeys.managerInbox, reports, (r) => r.toJson());

  @override
  Future<List<String>> loadSendQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(StorageKeys.sendQueue) ?? [];
  }

  @override
  Future<void> saveSendQueue(List<String> reportIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(StorageKeys.sendQueue, reportIds);
  }

  @override
  Future<bool> isMockInboxSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.mockSeeded) ?? false;
  }

  @override
  Future<void> setMockInboxSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.mockSeeded, true);
  }

  @override
  Future<WorkerProfile?> loadWorkerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.workerProfile);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return WorkerProfile.fromJson(decoded);
    } catch (e, st) {
      AppLogger.error(_tag, 'load worker profile failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<void> saveWorkerProfile(WorkerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.workerProfile,
      jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<List<StoredUser>> loadAuthUsers() =>
      _loadList(StorageKeys.authUsers, StoredUser.fromJson);

  @override
  Future<void> saveAuthUsers(List<StoredUser> users) =>
      _saveList(StorageKeys.authUsers, users, (u) => u.toJson());

  @override
  Future<AuthSession?> readAuthSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.authSession);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(decoded);
    } catch (e, st) {
      AppLogger.error(_tag, 'load auth session failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<void> saveAuthSession(AuthSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(StorageKeys.authSession);
      await prefs.remove(StorageKeys.userRole);
    } else {
      await prefs.setString(
        StorageKeys.authSession,
        jsonEncode(session.toJson()),
      );
      await prefs.setString(StorageKeys.userRole, session.role.id);
    }
  }
}
