import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/auth_stubs.dart';
import '../models/auth_session.dart';
import '../models/worker_profile.dart';
import '../services/image_storage_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/demo_asset_importer.dart';

class WorkerProfileProvider extends ChangeNotifier {
  WorkerProfileProvider({
    required StorageService storage,
    ImageStorageService? imageStorage,
  })  : _storage = storage,
        _images = imageStorage ?? FileImageStorageService();

  static const _tag = 'WorkerProfileProvider';
  static const _demoAvatarAsset = 'assets/images/demo_worker_avatar.png';

  final StorageService _storage;
  final ImageStorageService _images;
  final Uuid _uuid = const Uuid();

  WorkerProfile? _profile;
  bool _ready = false;

  WorkerProfile get profile =>
      _profile ?? WorkerProfile.initial(id: _uuid.v4());

  bool get isReady => _ready;

  Future<void> init() async {
    _profile = await _storage.loadWorkerProfile();
    _profile ??= WorkerProfile.initial(id: _uuid.v4());
    _ready = true;
    notifyListeners();
  }

  /// Подставляет ФИО и демо-фото после входа (профиль только для просмотра).
  Future<void> applyFromAuthSession(AuthSession session) async {
    var current = await _storage.loadWorkerProfile();
    current ??= WorkerProfile.initial(id: session.userId);

    current = current.copyWith(
      id: session.userId,
      fullName: session.displayName,
    );

    final isDemoWorker = session.login == AuthStubs.workerLogin;
    if (isDemoWorker && current.photoPath == null) {
      try {
        final stored = await DemoAssetImporter(imageStorage: _images)
            .importAsset(_demoAvatarAsset);
        current = current.copyWith(photoPath: stored);
      } catch (e, st) {
        AppLogger.warn(_tag, 'demo avatar import failed', e);
        AppLogger.error(_tag, 'demo avatar', error: e, stackTrace: st);
      }
    }

    _profile = current;
    await _storage.saveWorkerProfile(_profile!);
    notifyListeners();
  }

  Future<File?> photoFile() async {
    final path = profile.photoPath;
    if (path == null) return null;
    final file = await _images.resolveFile(path);
    if (await file.exists()) return file;
    return null;
  }
}
