import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/worker_profile.dart';
import '../services/image_storage_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

class WorkerProfileProvider extends ChangeNotifier {
  WorkerProfileProvider({
    required StorageService storage,
    ImageStorageService? imageStorage,
  })  : _storage = storage,
        _images = imageStorage ?? FileImageStorageService();

  static const _tag = 'WorkerProfileProvider';

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

  Future<void> updateFullName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _profile = profile.copyWith(fullName: trimmed);
    await _storage.saveWorkerProfile(_profile!);
    notifyListeners();
  }

  Future<void> setPhotoFromFile(File source) async {
    try {
      final old = profile.photoPath;
      final stored = await _images.saveFromFile(source);
      _profile = profile.copyWith(photoPath: stored);
      await _storage.saveWorkerProfile(_profile!);
      if (old != null && old != stored) {
        await _images.delete(old);
      }
      notifyListeners();
    } catch (e, st) {
      AppLogger.error(_tag, 'setPhoto failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> clearPhoto() async {
    final old = profile.photoPath;
    _profile = profile.copyWith(clearPhoto: true);
    await _storage.saveWorkerProfile(_profile!);
    if (old != null) await _images.delete(old);
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
