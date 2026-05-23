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
import '../../config/app_theme.dart';
import '../../utils/app_navigation.dart';
import '../../utils/report_navigation.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/profile_avatar.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapProfile());
  }

  Future<void> _bootstrapProfile() async {
    final session = context.read<AuthProvider>().session;
    if (session != null) {
      await context.read<WorkerProfileProvider>().applyFromAuthSession(session);
    }
    await _loadAvatar();
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
      backgroundColor: AppTheme.scaffoldBackground,
      body: Column(
        children: [
          AuroraHeader(
            title: 'Мои отчёты',
            subtitle: profile.fullName,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderIconButton(
                  tooltip: 'Профиль',
                  icon: Icons.person_outline,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkerProfileScreen(),
                      ),
                    );
                    await _loadAvatar();
                  },
                  child: ProfileAvatar(
                    photoFile: _avatarFile,
                    name: profile.fullName,
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 4),
                HeaderIconButton(
                  tooltip: 'Токен',
                  icon: Icons.key_outlined,
                  onPressed: () => _tokenDialog(context),
                ),
                const SizedBox(width: 4),
                HeaderIconButton(
                  tooltip: 'Выйти',
                  icon: Icons.logout_rounded,
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
            bottom: AuroraSegmentedTabs(
              controller: _tabs,
              tabs: [
                Tab(
                  child: Consumer<ReportProvider>(
                    builder: (_, rp, __) {
                      final n = rp.submittedReports.length;
                      return Text(n > 0 ? 'Отчёты ($n)' : 'Отчёты');
                    },
                  ),
                ),
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
          ),
          Expanded(
            child: Consumer<ReportProvider>(
              builder: (context, provider, _) {
                if (provider.isInitializing) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabs,
                  children: [
                    provider.submittedReports.isEmpty
                        ? AppEmptyState(
                            icon: Icons.description_outlined,
                            title: 'Нет отправленных отчётов',
                            subtitle:
                                'Нажмите «Новый отчёт», заполните заметки и отправьте руководителю',
                            action: FilledButton.icon(
                              onPressed: () => _openCreate(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Новый отчёт'),
                            ),
                          )
                        : _ReportList(
                            reports: provider.submittedReports,
                            onOpen: (r) => _openReport(context, r),
                          ),
                    provider.drafts.isEmpty
                        ? AppEmptyState(
                            icon: Icons.edit_note_outlined,
                            title: 'Черновиков нет',
                            subtitle:
                                'Незавершённые отчёты сохраняются автоматически при создании',
                            action: OutlinedButton.icon(
                              onPressed: () => _openCreate(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Новый отчёт'),
                            ),
                          )
                        : _ReportList(
                            reports: provider.drafts,
                            onOpen: (r) => _openReport(context, r),
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FilledButton.icon(
              key: const Key('worker_new_report'),
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Новый отчёт'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
              ),
            ),
          ),
        ),
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
    if (r.type.isProfileChange) {
      ReportNavigation.openWorkerReport(context, r);
      return;
    }

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
    ReportNavigation.openWorkerReport(context, r);
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

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, required this.onOpen});

  final List<Report> reports;
  final void Function(Report) onOpen;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy · HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = reports[i];
        final feedback = r.managerFeedback;
        return AppReportTile(
          report: r,
          dateLabel: r.sentAtLabel(df),
          onTap: () => onOpen(r),
          feedback: feedback != null && feedback.isNotEmpty
              ? 'Замечания: $feedback'
              : null,
        );
      },
    );
  }
}
