import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../utils/app_logger.dart';

/// Локальное хранение фото полевого осмотра (без Firebase / облака).
abstract class ImageStorageService {
  Future<String> saveFromFile(File source);
  Future<File> resolveFile(String storedName);
  Future<void> delete(String storedName);
  Future<void> deleteAll(Iterable<String> storedNames);
}

class FileImageStorageService implements ImageStorageService {
  FileImageStorageService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const _tag = 'ImageStorageService';
  static const _subdir = 'report_images';

  final Uuid _uuid;
  Directory? _dir;

  Future<Directory> _imagesDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(base.path, _subdir));
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    return _dir!;
  }

  @override
  Future<String> saveFromFile(File source) async {
    final dir = await _imagesDir();
    final ext = p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final name = '${_uuid.v4()}$ext';
    final dest = File(p.join(dir.path, name));
    await source.copy(dest.path);
    AppLogger.info(_tag, 'image saved: $name');
    return name;
  }

  @override
  Future<File> resolveFile(String storedName) async {
    final dir = await _imagesDir();
    return File(p.join(dir.path, storedName));
  }

  @override
  Future<void> delete(String storedName) async {
    try {
      final file = await resolveFile(storedName);
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      AppLogger.warn(_tag, 'delete failed for $storedName', e);
      AppLogger.error(_tag, 'delete', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteAll(Iterable<String> storedNames) async {
    for (final name in storedNames) {
      await delete(name);
    }
  }

  /// Проверка лимита перед добавлением нового фото.
  static bool canAddMore(int currentCount) =>
      currentCount < ApiConfig.maxAttachedImages;
}
