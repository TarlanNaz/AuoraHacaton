import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../providers/generation_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../utils/app_navigation.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_chips.dart';
import 'create_report_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  late final TextEditingController _nameController;
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    final profile = context.read<WorkerProfileProvider>().profile;
    _nameController = TextEditingController(text: profile.fullName);
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final file = await context.read<WorkerProfileProvider>().photoFile();
    if (mounted) setState(() => _photoFile = file);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 88,
      );
      if (picked == null) return;
      await context.read<WorkerProfileProvider>().setPhotoFromFile(File(picked.path));
      await _loadPhoto();
      if (mounted) UiFeedback.info(context, 'Фото профиля обновлено');
    } catch (e) {
      if (mounted) UiFeedback.warning(context, 'Не удалось загрузить фото: $e');
    }
  }

  void _photoMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Удалить фото'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<WorkerProfileProvider>().clearPhoto();
                  if (mounted) setState(() => _photoFile = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    await context.read<WorkerProfileProvider>().updateFullName(_nameController.text);
    if (mounted) UiFeedback.info(context, 'ФИО сохранено');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Consumer2<WorkerProfileProvider, ReportProvider>(
        builder: (context, profileProv, reports, _) {
          final stats = reports.workerStats;
          final drafts = reports.drafts;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        photoFile: _photoFile,
                        name: profileProv.profile.fullName,
                        radius: 48,
                        onTap: _photoMenu,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите на фото, чтобы изменить',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'ФИО',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saveName,
                        child: const Text('Сохранить ФИО'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Статистика', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: Icons.summarize_outlined,
                    label: 'Всего',
                    value: '${stats.total}',
                  ),
                  _StatChip(
                    icon: Icons.send_outlined,
                    label: 'Отправлено',
                    value: '${stats.sent}',
                    color: Colors.orange,
                  ),
                  _StatChip(
                    icon: Icons.edit_note_outlined,
                    label: 'Черновики',
                    value: '${stats.drafts}',
                    color: Colors.grey,
                  ),
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: 'Принято',
                    value: '${stats.accepted}',
                    color: Colors.green,
                  ),
                  _StatChip(
                    icon: Icons.cancel_outlined,
                    label: 'Отклонено',
                    value: '${stats.rejected}',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Черновики', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text('${drafts.length}', style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 8),
              if (drafts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Нет черновиков',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...drafts.map(
                  (r) => _DraftTile(
                    report: r,
                    dateLabel: df.format(r.createdAt),
                    onOpen: () => _openDraft(context, r),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openDraft(BuildContext context, Report r) {
    context.read<GenerationProvider>().reset();
    Navigator.of(context).push(
      AppNavigation.detailRoute(
        CreateReportScreen(
          initialText: r.rawText ?? r.finalText ?? '',
          initialImagePaths: r.imagePaths,
          initialType: r.type,
          reportId: r.id,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({
    required this.report,
    required this.dateLabel,
    required this.onOpen,
  });

  final Report report;
  final String dateLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(report.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                ReportTypeChip(type: report.type),
                const ReportStatusChip(status: ReportStatus.draft),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateLabel),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: onOpen,
      ),
    );
  }
}
