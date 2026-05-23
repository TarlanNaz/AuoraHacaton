import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:structurator/models/auth_session.dart';
import 'package:structurator/models/report.dart';
import 'package:structurator/models/report_template.dart';
import 'package:structurator/models/stored_user.dart';
import 'package:structurator/models/user_role.dart';
import 'package:structurator/models/worker_profile.dart';
import 'package:structurator/services/giga_chat_service.dart';
import 'package:structurator/services/storage_service.dart';

/// In-memory реализация [StorageService] для acceptance/widget-тестов.
class FakeStorageService implements StorageService {
  FakeStorageService({List<Report>? seed})
      : _reports = List<Report>.of(seed ?? const <Report>[]);

  final List<Report> _reports;
  final List<Report> _inbox = [];
  final List<ReportTemplate> _templates = [];
  final List<String> _sendQueue = [];
  String? _token;
  UserRole? _role;
  bool _mockSeeded = false;
  WorkerProfile? _profile;
  List<StoredUser> _authUsers = [];
  AuthSession? _authSession;

  List<Report> get persisted => List.unmodifiable(_reports);

  @override
  Future<List<Report>> loadReports() async => List<Report>.of(_reports);

  @override
  Future<void> saveReports(List<Report> reports) async {
    _reports
      ..clear()
      ..addAll(reports);
  }

  @override
  Future<void> saveManualToken(String token) async {
    _token = token.trim().isEmpty ? null : token.trim();
  }

  @override
  Future<String?> readManualToken() async => _token;

  @override
  Future<void> clearReports() async => _reports.clear();

  @override
  Future<UserRole?> readRole() async => _role;

  @override
  Future<void> saveRole(UserRole? role) async => _role = role;

  @override
  Future<List<ReportTemplate>> loadTemplates() async =>
      List<ReportTemplate>.of(_templates);

  @override
  Future<void> saveTemplates(List<ReportTemplate> templates) async {
    _templates
      ..clear()
      ..addAll(templates);
  }

  @override
  Future<List<Report>> loadManagerInbox() async => List<Report>.of(_inbox);

  @override
  Future<void> saveManagerInbox(List<Report> reports) async {
    _inbox
      ..clear()
      ..addAll(reports);
  }

  @override
  Future<List<String>> loadSendQueue() async => List<String>.of(_sendQueue);

  @override
  Future<void> saveSendQueue(List<String> reportIds) async {
    _sendQueue
      ..clear()
      ..addAll(reportIds);
  }

  @override
  Future<bool> isMockInboxSeeded() async => _mockSeeded;

  @override
  Future<void> setMockInboxSeeded() async => _mockSeeded = true;

  bool _demoManagerSeeded = false;
  bool _demoWorkerSeeded = false;

  @override
  Future<bool> isDemoManagerSeeded() async => _demoManagerSeeded;

  @override
  Future<void> setDemoManagerSeeded() async => _demoManagerSeeded = true;

  @override
  Future<bool> isDemoWorkerSeeded() async => _demoWorkerSeeded;

  @override
  Future<void> setDemoWorkerSeeded() async => _demoWorkerSeeded = true;

  @override
  Future<WorkerProfile?> loadWorkerProfile() async => _profile;

  @override
  Future<void> saveWorkerProfile(WorkerProfile profile) async {
    _profile = profile;
  }

  @override
  Future<List<StoredUser>> loadAuthUsers() async =>
      List<StoredUser>.of(_authUsers);

  @override
  Future<void> saveAuthUsers(List<StoredUser> users) async {
    _authUsers = List<StoredUser>.of(users);
  }

  @override
  Future<AuthSession?> readAuthSession() async => _authSession;

  @override
  Future<void> saveAuthSession(AuthSession? session) async {
    _authSession = session;
    _role = session?.role;
  }
}

class FakeGigaChatService implements GigaChatService {
  FakeGigaChatService({
    String? response,
    GigaChatException? error,
    GigaChatToken? oauthToken,
  })  : nextResponse = response,
        nextError = error,
        nextOAuthToken = oauthToken;

  /// Алиас для старых тестов.
  FakeGigaChatService.withResponse(String response)
      : nextResponse = response,
        nextError = null,
        nextOAuthToken = null;

  String? nextResponse;
  GigaChatException? nextError;
  GigaChatToken? nextOAuthToken;

  int generateCalls = 0;
  int oauthCalls = 0;
  String? lastSentText;
  String? lastSentToken;

  @override
  Future<GigaChatToken> obtainAccessToken({
    required String authKey,
    String scope = 'GIGACHAT_API_PERS',
  }) async {
    oauthCalls++;
    if (nextError != null) throw nextError!;
    return nextOAuthToken ??
        GigaChatToken(
          accessToken: 'fake-token-$oauthCalls',
          expiresAt: DateTime.now().add(const Duration(minutes: 25)),
        );
  }

  @override
  Future<String> generateReport({
    required String token,
    required String rawText,
    String? model,
    List<File> imageFiles = const [],
    String? systemPrompt,
  }) async {
    generateCalls++;
    lastSentText = rawText;
    lastSentToken = token;
    if (nextError != null) throw nextError!;
    return nextResponse ?? '## Заголовок\nFake structured report';
  }
}

class MockGigaChatService extends Mock implements GigaChatService {}

class MockStorageService extends Mock implements StorageService {}
