import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../services/image_storage_service.dart';

/// Импорт файла из assets в локальное хранилище фото отчётов.
class DemoAssetImporter {
  DemoAssetImporter({
    required ImageStorageService imageStorage,
    Uuid? uuid,
  })  : _images = imageStorage,
        _uuid = uuid ?? const Uuid();

  final ImageStorageService _images;
  final Uuid _uuid;

  Future<String> importAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final ext = p.extension(assetPath).isEmpty ? '.png' : p.extension(assetPath);
    final temp = File(p.join(dir.path, 'asset_${_uuid.v4()}$ext'));
    await temp.writeAsBytes(data.buffer.asUint8List());
    return _images.saveFromFile(temp);
  }
}
