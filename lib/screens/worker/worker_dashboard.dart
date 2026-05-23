import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/generation_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../utils/app_navigation.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_chips.dart';
import 'create_report_screen.dart';
import 'worker_profile_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final file = await context.read<WorkerProfileProvider>().photoFile();
    if (mounted) setState(() => _avatarFile = file);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<WorkerProfileProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отчёты'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Все'),
            Tab(
              child: Consumer<ReportProvider>(
                builder: (_, rp, __) {
                  final n = rp.drafts.length;
                  return Text(n > 0 ? 'Черновики ($n)' : 'Черновики');
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Профиль',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WorkerProfileScreen(),
                ),
              );
              await _loadAvatar();
            },
            icon: ProfileAvatar(
              photoFile: _avatarFile,
              name: profile.fullName,
              radius: 18,
            ),
          ),
          IconButton(
            tooltip: 'Токен GigaChat',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _tokenDialog(context),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isInitializing) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabs,
            children: [
              provider.workerReports.isEmpty
                  ? _Empty(onCreate: () => _openCreate(context))
                  : _ReportList(
                      reports: provider.workerReports,
                      onOpen: (r) => _openReport(context, r),
                    ),
              provider.drafts.isEmpty
                  ? const _EmptyDrafts()
                  : _ReportList(
                      reports: provider.drafts,
                      onOpen: (r) => _openReport(context, r),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Новый отчёт'),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    context.read<GenerationProvider>().reset();
    Navigator.of(context).push(
      AppNavigation.detailRoute(const CreateReportScreen()),
    );
  }

  void _openReport(BuildContext context, Report r) {
    final editable = r.status == ReportStatus.draft ||
        r.status == ReportStatus.rejected;

    if (!editable) {
      if (r.managerFeedback != null && r.managerFeedback!.isNotEmpty) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Статус отчёта'),
            content: Text(
              r.status == ReportStatus.sent
                  ? 'Отчёт на проверке у руководителя.'
                  : r.status == ReportStatus.synced
                      ? 'Отчёт принят руководителем.'
                      : r.managerFeedback!,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

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

  Future<void> _tokenDialog(BuildContext context) async {
    final rp = context.read<ReportProvider>();
    final c = TextEditingController(text: rp.manualToken ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bearer-токен'),
        content: TextField(controller: c, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
        ],
      ),
    );
    if (saved != null) {
      await rp.setManualToken(saved);
      if (context.mounted) UiFeedback.info(context, 'Токен сохранён');
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded, size: 80),
            const SizedBox(height: 16),
            const Text('Нет отчётов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Создайте отчёт с фото и сырыми заметками', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onCreate, child: const Text('Создать отчёт')),
          ],
        ),
      ),
    );
  }
}

class _EmptyDrafts extends StatelessWidget {
  const _EmptyDrafts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Черновиков нет.\nСохраните незавершённый отчёт при создании.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.onOpen});

  final List<Report> reports;
  final void Function(Report) onOpen;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = reports[i];
        final feedback = r.managerFeedback;
        return Card(
          child: ListTile(
            title: Text(r.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ReportTypeChip(type: r.type),
                    ReportStatusChip(status: r.status),
                    if (r.hasImages)
                      const Chip(
                        avatar: Icon(Icons.photo, size: 16),
                        label: Text('Фото'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(df.format(r.createdAt)),
                if (feedback != null && feedback.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Замечания: $feedback',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            isThreeLine: feedback != null && feedback.isNotEmpty,
            onTap: () => onOpen(r),
          ),
        );
      },
    );
  }
}
