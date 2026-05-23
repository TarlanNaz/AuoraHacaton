import 'dart:io';

import 'package:flutter/material.dart';

/// Круглый аватар: фото или инициалы.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoFile,
    required this.name,
    this.radius = 28,
    this.onTap,
  });

  final File? photoFile;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String ch(String s) => s.isNotEmpty ? s[0].toUpperCase() : '';
    if (parts.length == 1) return ch(parts.first);
    return '${ch(parts.first)}${ch(parts[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (photoFile != null) {
      child = CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(photoFile!),
      );
    } else {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Text(
          _initials,
          style: TextStyle(fontSize: radius * 0.55, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: child,
    );
  }
}
