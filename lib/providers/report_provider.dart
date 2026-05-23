import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/env.dart';
import '../models/report.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';
import '../models/worker_report_stats.dart';
import '../models/worker_summary.dart';
import '../services/giga_chat_service.dart';
import '../services/image_storage_service.dart';
import '../services/demo_data_seeder.dart';
import '../services/mock_report_api_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

/// Отчёты рабочего, входящие руководителя, токен GigaChat, отправка и проверка.
class ReportProvider extends ChangeNotifier {
  ReportProvider({
    required StorageService storage,
    required GigaChatService gigaChatService,
    required MockReportApiService mockApi,
    ImageStorageService? imageStorage,
  })  : _storage = storage,
        _giga = gigaChatService,
        _mockApi = mockApi,
        _images = imageStorage ?? FileImageStorageService();

  static const _tag = 'ReportProvider';

  final StorageService _storage;
  final GigaChatService _giga;
  final MockReportApiService _mockApi;
  final ImageStorageService _images;
  final Uuid _uuid = const Uuid();

  List<Report> _workerReports = [];
  List<Report> _managerInbox = [];
  bool _isInitializing = true;
  String? _initError;
  String? _manualToken;
  GigaChatToken? _cachedOAuthToken;

  List<Report> get workerReports => List.unmodifiable(_workerReports);
  List<Report> get managerInbox => List.unmodifiable(_managerInbox);
  List<Report> get drafts =>
      _workerReports.where((r) => r.status == ReportStatus.draft).toList();
  List<Report> get sentReports =>
      _workerReports.where((r) => r.status == ReportStatus.sent).toList();
  List<Report> get rejectedReports =>
      _workerReports.where((r) => r.status == ReportStatus.rejected).toList();

  WorkerReportStats get workerStats {
    final counts = <ReportStatus, int>{};
    for (final r in _workerReports) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return WorkerReportStats.fromCounts(counts);
  }

  List<WorkerSummary> get workerSummaries =>
      WorkerSummary.fromReports(_managerInbox);

  bool get isInitializing => _isInitializing;
  String? get initError => _initError;

  List<Report> get reports => workerReports;
  bool get isEmpty => _workerReports.isEmpty;

  bool get hasCredentials =>
      (_manualToken ?? '').isNotEmpty || Env.hasAuthKey;
  String? get manualToken => _manualToken;

  List<Report> reportsForWorker(String workerName) => _managerInbox
      .where((r) => r.workerName == workerName)
      .toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  Future<void> seedWorkerDemoIfNeeded() async {
    await DemoDataSeeder(_storage, _images).seedWorkerReportsIfNeeded();
    _workerReports = await _storage.loadReports();
    _workerReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    notifyListeners();
  }

  Future<void> init({bool seedManagerMock = false}) async {
    _isInitializing = true;
    _initError = null;
    notifyListeners();

    try {
      _workerReports = await _storage.loadReports();
      _workerReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _managerInbox = await _storage.loadManagerInbox();
      _managerInbox.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _manualToken = await _storage.readManualToken();

      if (seedManagerMock) {
        await DemoDataSeeder(_storage, _images).seedManagerInboxIfNeeded();
        _managerInbox = await _storage.loadManagerInbox();
      }

      await _mockApi.syncPending();
      await _refreshAfterSync();
    } catch (e, st) {
      AppLogger.error(_tag, 'init failed', error: e, stackTrace: st);
      _initError = 'Не удалось загрузить данные: $e';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAfterSync() async {
    _workerReports = await _storage.loadReports();
    _managerInbox = await _storage.loadManagerInbox();
      _workerReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _managerInbox.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<String> ensureToken() async {
    if ((_manualToken ?? '').trim().isNotEmpty) return _manualToken!.trim();

    final cached = _cachedOAuthToken;
    if (cached != null && !cached.isExpired) return cached.accessToken;

    if (!Env.hasAuthKey) {
      throw GigaChatException(
        'Нет токена. Заполните GIGACHAT_AUTH_KEY в .env.',
      );
    }

    final fresh = await _giga.obtainAccessToken(
      authKey: Env.gigaChatAuthKey,
      scope: Env.gigaChatScope,
    );
    _cachedOAuthToken = fresh;
    return fresh.accessToken;
  }

  /// Создаёт или обновляет черновик (для автосохранения и ручного сценария).
  /// Возвращает `null`, если сохранять нечего (пустой текст и нет фото).
  Future<Report?> upsertDraft({
    String? existingId,
    required String rawText,
    String? finalText,
    required ReportType type,
    required String workerName,
    List<String> imagePaths = const [],
    String? templateId,
    String? locationQuery,
    String? locationName,
    double? locationLat,
    double? locationLon,
  }) async {
    final trimmedRaw = rawText.trim();
    final trimmedFinal = (finalText ?? '').trim();
    final hasLocation = (locationQuery ?? '').trim().isNotEmpty ||
        (locationName ?? '').trim().isNotEmpty ||
        locationLat != null ||
        locationLon != null;
    final hasContent = trimmedRaw.isNotEmpty ||
        trimmedFinal.isNotEmpty ||
        imagePaths.isNotEmpty ||
        hasLocation;
    if (!hasContent) return null;

    final storedRaw = trimmedRaw.isEmpty && imagePaths.isNotEmpty
        ? 'Черновик с фото (см. приложения)'
        : trimmedRaw;

    final idx = existingId != null
        ? _workerReports.indexWhere((r) => r.id == existingId)
        : -1;

    final omitRaw = trimmedFinal.isNotEmpty;

    if (idx >= 0) {
      final prev = _workerReports[idx];
      if (prev.status != ReportStatus.draft &&
          prev.status != ReportStatus.rejected) {
        return prev;
      }
      _workerReports[idx] = prev.copyWith(
        rawText: omitRaw ? null : (storedRaw.isEmpty ? prev.rawText : storedRaw),
        finalText: trimmedFinal.isEmpty ? prev.finalText : trimmedFinal,
        type: type,
        imagePaths: imagePaths,
        workerName: workerName,
        status: ReportStatus.draft,
        templateId: templateId,
        locationQuery: locationQuery ?? prev.locationQuery,
        locationName: locationName ?? prev.locationName,
        locationLat: locationLat ?? prev.locationLat,
        locationLon: locationLon ?? prev.locationLon,
        clearManagerFeedback: true,
        clearRawText: omitRaw,
      );
    } else {
      _workerReports.insert(
        0,
        Report(
          id: _uuid.v4(),
          rawText: omitRaw ? null : (storedRaw.isEmpty ? null : storedRaw),
          finalText: trimmedFinal.isEmpty ? null : trimmedFinal,
          type: type,
          status: ReportStatus.draft,
          createdAt: DateTime.now(),
          imagePaths: List.from(imagePaths),
          workerName: workerName,
          templateId: templateId,
          locationQuery: (locationQuery ?? '').trim().isEmpty
              ? null
              : locationQuery!.trim(),
          locationName: locationName,
          locationLat: locationLat,
          locationLon: locationLon,
        ),
      );
    }

    await _storage.saveReports(_workerReports);
    notifyListeners();
    return idx >= 0 ? _workerReports[idx] : _workerReports.first;
  }

  Future<Report> saveDraft({
    required String rawText,
    required ReportType type,
    required String workerName,
    List<String> imagePaths = const [],
    String? templateId,
    String? existingId,
  }) async {
    final saved = await upsertDraft(
      existingId: existingId,
      rawText: rawText,
      type: type,
      workerName: workerName,
      imagePaths: imagePaths,
      templateId: templateId,
    );
    if (saved != null) return saved;
    return Report(
      id: _uuid.v4(),
      rawText: rawText,
      type: type,
      status: ReportStatus.draft,
      createdAt: DateTime.now(),
      imagePaths: List.from(imagePaths),
      workerName: workerName,
      templateId: templateId,
    );
  }

  Future<Report> saveGenerated({
    required String finalText,
    required ReportType type,
    required String workerName,
    List<String> imagePaths = const [],
    String? templateId,
    String? existingId,
  }) async {
    final idx = existingId != null
        ? _workerReports.indexWhere((r) => r.id == existingId)
        : -1;

    if (idx >= 0) {
      _workerReports[idx] = _workerReports[idx].copyWith(
        finalText: finalText,
        clearRawText: true,
        status: ReportStatus.draft,
        imagePaths: imagePaths,
        workerName: workerName,
        clearManagerFeedback: true,
      );
    } else {
      _workerReports.insert(
        0,
        Report(
          id: _uuid.v4(),
          finalText: finalText,
          type: type,
          status: ReportStatus.draft,
          createdAt: DateTime.now(),
          imagePaths: List.from(imagePaths),
          workerName: workerName,
          templateId: templateId,
        ),
      );
    }
    await _storage.saveReports(_workerReports);
    notifyListeners();
    return idx >= 0 ? _workerReports[idx] : _workerReports[0];
  }

  Future<bool> sendToManager(String reportId) async {
    final idx = _workerReports.indexWhere((r) => r.id == reportId);
    if (idx == -1) return false;

    final sentAt = DateTime.now();
    final report = _workerReports[idx].copyWith(
      status: ReportStatus.sent,
      sentAt: sentAt,
      clearRawText: true,
      clearManagerFeedback: true,
    );

    final delivered = await _mockApi.submitToManager(report);

    _workerReports[idx] = delivered
        ? report
        : report.copyWith(
            status: ReportStatus.draft,
            clearSentAt: true,
          );
    await _storage.saveReports(_workerReports);
    notifyListeners();
    return delivered;
  }

  Future<void> acceptReport(String reportId) async {
    await _setReviewStatus(
      reportId,
      ReportStatus.synced,
      feedback: null,
    );
  }

  Future<void> rejectReport(String reportId, String feedback) async {
    final trimmed = feedback.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Укажите, что нужно исправить');
    }
    await _setReviewStatus(
      reportId,
      ReportStatus.rejected,
      feedback: trimmed,
    );
  }

  /// Обратная совместимость.
  Future<void> markSynced(String reportId) => acceptReport(reportId);

  Future<void> _setReviewStatus(
    String reportId,
    ReportStatus status, {
    required String? feedback,
  }) async {
    final inboxIdx = _managerInbox.indexWhere((r) => r.id == reportId);
    if (inboxIdx >= 0) {
      _managerInbox[inboxIdx] = _managerInbox[inboxIdx].copyWith(
        status: status,
        managerFeedback: feedback,
        clearManagerFeedback: feedback == null,
      );
      await _storage.saveManagerInbox(_managerInbox);
    }

    final workerIdx = _workerReports.indexWhere((r) => r.id == reportId);
    if (workerIdx >= 0) {
      _workerReports[workerIdx] = _workerReports[workerIdx].copyWith(
        status: status,
        managerFeedback: feedback,
        clearManagerFeedback: feedback == null,
      );
      await _storage.saveReports(_workerReports);
    }

    notifyListeners();
  }

  Future<void> removeWorkerReport(String id, {bool preserveImages = false}) async {
    final idx = _workerReports.indexWhere((r) => r.id == id);
    if (idx >= 0 && !preserveImages) {
      await _images.deleteAll(_workerReports[idx].imagePaths);
    }
    _workerReports.removeWhere((r) => r.id == id);
    await _storage.saveReports(_workerReports);
    notifyListeners();
  }

  Future<void> setManualToken(String token) async {
    final trimmed = token.trim();
    _manualToken = trimmed.isEmpty ? null : trimmed;
    await _storage.saveManualToken(trimmed);
    _cachedOAuthToken = null;
    notifyListeners();
  }
}
