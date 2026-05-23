import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../services/image_storage_service.dart';
import '../../utils/ui_feedback.dart';

/// Панель прикреплённых фото: превью, добавление (камера/галерея), удаление.
class AttachedImagesPanel extends StatelessWidget {
  const AttachedImagesPanel({
    super.key,
    required this.imageNames,
    required this.imageStorage,
    required this.onChanged,
  });

  final List<String> imageNames;
  final ImageStorageService imageStorage;
  final ValueChanged<List<String>> onChanged;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (!FileImageStorageService.canAddMore(imageNames.length)) {
      UiFeedback.warning(
        context,
        'Максимум ${ApiConfig.maxAttachedImages} фото на отчёт',
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return;

      final stored = await imageStorage.saveFromFile(File(file.path));
      onChanged([...imageNames, stored]);
      if (context.mounted) {
        UiFeedback.info(context, 'Фото добавлено');
      }
    } catch (e) {
      if (context.mounted) {
        UiFeedback.warning(context, 'Не удалось добавить фото: $e');
      }
    }
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать снимок'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null && context.mounted) {
      await _pickImage(context, source);
    }
  }

  Future<void> _remove(BuildContext context, String name) async {
    await imageStorage.delete(name);
    onChanged(imageNames.where((n) => n != name).toList());
    if (context.mounted) UiFeedback.info(context, 'Фото удалено');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.photo_outlined,
                size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Фотографии (${imageNames.length}/${ApiConfig.maxAttachedImages})',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...imageNames.map((name) => _Thumb(
                    name: name,
                    imageStorage: imageStorage,
                    onRemove: () => _remove(context, name),
                  )),
              _AddPhotoTile(onTap: () => _showSourceSheet(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.name,
    required this.imageStorage,
    required this.onRemove,
  });

  final String name;
  final ImageStorageService imageStorage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FutureBuilder<File>(
            future: imageStorage.resolveFile(name),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.existsSync()) {
                return Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.broken_image_outlined),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  snap.data!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Theme.of(context).colorScheme.error,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: scheme.primary),
              const SizedBox(height: 4),
              Text(
                'Добавить',
                style: TextStyle(fontSize: 11, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
