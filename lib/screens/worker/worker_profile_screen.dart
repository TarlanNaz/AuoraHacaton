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
import '../../utils/report_navigation.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_chips.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapProfile());
  }

  Future<void> _bootstrapProfile() async {
    final session = context.read<AuthProvider>().session;
    if (session != null) {
      await context.read<WorkerProfileProvider>().applyFromAuthSession(session);
    }
    await _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final file = await context.read<WorkerProfileProvider>().photoFile();
    if (mounted) setState(() => _photoFile = file);
  }

  void _requestProfileChange(BuildContext context) {
    ReportNavigation.openProfileChangeForm(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final profileProv = context.watch<WorkerProfileProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Мой профиль'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AuroraGradient.header),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reports, _) {
          final stats = reports.workerStats;
          final drafts = reports.drafts
              .where((r) => !r.type.isProfileChange)
              .toList();
          final profileDrafts = reports.drafts
              .where((r) => r.type.isProfileChange)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          photoFile: _photoFile,
                          name: profileProv.profile.fullName,
                          radius: 52,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileProv.profile.fullName,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _ProfileMetaRow(
                        icon: Icons.business_outlined,
                        label: 'Место работы',
                        value: profileProv.profile.displayEmployer,
                      ),
                      if (context.watch<AuthProvider>().userLogin != null) ...[
                        const SizedBox(height: 6),
                        _ProfileMetaRow(
                          icon: Icons.badge_outlined,
                          label: 'Логин',
                          value: context.read<AuthProvider>().userLogin!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.demoPanelBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Данные профиля закреплены. Изменить их напрямую нельзя.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _requestProfileChange(context),
                        icon: const Icon(Icons.edit_document),
                        label: const Text('Изменить данные'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Отдельная форма: ФИО, место работы, фото и причина',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                    color: AppTheme.warningAmber,
                  ),
                  _StatChip(
                    icon: Icons.edit_note_outlined,
                    label: 'Черновики',
                    value: '${stats.drafts}',
                    color: AppTheme.warningOrange,
                  ),
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: 'Принято',
                    value: '${stats.accepted}',
                    color: AppTheme.successGreen,
                  ),
                  _StatChip(
                    icon: Icons.cancel_outlined,
                    label: 'Отклонено',
                    value: '${stats.rejected}',
                    color: AppTheme.errorMuted,
                  ),
                ],
              ),
              if (profileDrafts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Запросы на изменение данных',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${profileDrafts.length}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...profileDrafts.map(
                  (r) => _DraftTile(
                    report: r,
                    dateLabel: df.format(r.createdAt),
                    onOpen: () => ReportNavigation.openWorkerReport(context, r),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Черновики отчётов', style: theme.textTheme.titleMedium),
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
    ReportNavigation.openWorkerReport(context, r);
  }
}

class _ProfileMetaRow extends StatelessWidget {
  const _ProfileMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: $value',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
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
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onOpen,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
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
      ),
    );
  }
}
