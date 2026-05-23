import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_storage_service.dart';

/// Галерея фото отчёта (только просмотр).
class ReportImagesGallery extends StatelessWidget {
  const ReportImagesGallery({
    super.key,
    required this.imagePaths,
    required this.imageStorage,
    this.title = 'Фотографии',
  });

  final List<String> imagePaths;
  final ImageStorageService imageStorage;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.photo_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(width: 6),
            Text(
              '(${imagePaths.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imagePaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _Thumb(
              name: imagePaths[i],
              index: i,
              imageStorage: imageStorage,
              onTap: () => _openFullScreen(context, i),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFullScreen(BuildContext context, int initialIndex) async {
    final files = <File>[];
    for (final name in imagePaths) {
      final file = await imageStorage.resolveFile(name);
      if (await file.exists()) files.add(file);
    }
    if (!context.mounted || files.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenGallery(
          files: files,
          initialIndex: initialIndex.clamp(0, files.length - 1),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.name,
    required this.index,
    required this.imageStorage,
    required this.onTap,
  });

  final String name;
  final int index;
  final ImageStorageService imageStorage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<File>(
        future: imageStorage.resolveFile(name),
        builder: (context, snap) {
          final scheme = Theme.of(context).colorScheme;
          if (!snap.hasData || !snap.data!.existsSync()) {
            return Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.broken_image_outlined),
            );
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  snap.data!,
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.files,
    required this.initialIndex,
  });

  final List<File> files;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _page;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _page = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Фото ${_index + 1} из ${widget.files.length}'),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.file(widget.files[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
