import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/profile_change_draft.dart';
import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../models/report_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../services/image_storage_service.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/profile_change_report_view.dart';
import '../../widgets/report_images_gallery.dart';
import '../widgets/attached_images_panel.dart';

/// Отдельная форма запроса на изменение данных профиля (не экран полевого отчёта).
class ProfileChangeRequestScreen extends StatefulWidget {
  const ProfileChangeRequestScreen({
    super.key,
    this.reportId,
    this.readOnly = false,
  });

  final String? reportId;
  final bool readOnly;

  @override
  State<ProfileChangeRequestScreen> createState() =>
      _ProfileChangeRequestScreenState();
}

class _ProfileChangeRequestScreenState extends State<ProfileChangeRequestScreen> {
  final _newNameController = TextEditingController();
  final _newEmployerController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String? _savedReportId;
  List<String> _imageNames = [];
  String? _previewMarkdown;
  bool _sending = false;
  Report? _loadedReport;

  @override
  void initState() {
    super.initState();
    _savedReportId = widget.reportId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newEmployerController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final id = _savedReportId;
    if (id == null) return;

    final rp = context.read<ReportProvider>();
    final matches = rp.workerReports.where((r) => r.id == id);
    if (matches.isEmpty || !mounted) return;
    final report = matches.first;

    setState(() {
      _loadedReport = report;
      _imageNames = List.from(report.imagePaths);
      _previewMarkdown = report.finalText;
    });

    final draft = ProfileChangeDraft.tryParseRaw(report.rawText);
    if (draft != null) {
      _newNameController.text = draft.newFullName;
      _newEmployerController.text = draft.newEmployer;
      _reasonController.text = draft.reason;
      _notesController.text = draft.notes;
    }
  }

  ProfileChangeDraft _collectDraft() => ProfileChangeDraft(
        newFullName: _newNameController.text,
        newEmployer: _newEmployerController.text,
        reason: _reasonController.text,
        notes: _notesController.text,
      );

  bool _validateForm() {
    final draft = _collectDraft();
    if (draft.reason.trim().length < 5) {
      UiFeedback.warning(context, 'Укажите причину изменения (не короче 5 символов)');
      return false;
    }
    if (!draft.hasAnyChange && _imageNames.isEmpty) {
      UiFeedback.warning(
        context,
        'Укажите хотя бы одно изменение: ФИО, место работы, фото или комментарий',
      );
      return false;
    }
    return true;
  }

  Future<void> _buildPreview() async {
    if (!_validateForm()) return;

    final profile = context.read<WorkerProfileProvider>().profile;
    final login = context.read<AuthProvider>().userLogin ?? '—';
    final draft = _collectDraft();
    final markdown = draft.buildMarkdown(
      currentFullName: profile.fullName,
      login: login,
      currentEmployer: profile.displayEmployer,
      hasNewPhoto: _imageNames.isNotEmpty,
    );

    final rp = context.read<ReportProvider>();
    final saved = await rp.upsertDraft(
      existingId: _savedReportId,
      rawText: draft.encodeRaw(),
      finalText: markdown,
      type: ReportType.profileChange,
      workerName: profile.fullName,
      imagePaths: _imageNames,
    );

    if (!mounted) return;
    if (saved != null) {
      _savedReportId = saved.id;
      setState(() => _previewMarkdown = markdown);
      UiFeedback.info(context, 'Запрос сохранён — проверьте текст');
    }
  }

  Future<void> _send() async {
    if (_previewMarkdown == null || _previewMarkdown!.trim().isEmpty) {
      await _buildPreview();
      if (_previewMarkdown == null) return;
    }

    final id = _savedReportId;
    if (id == null) {
      UiFeedback.warning(context, 'Сначала сформируйте запрос');
      return;
    }

    setState(() => _sending = true);
    final ok = await context.read<ReportProvider>().sendToManager(id);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      UiFeedback.info(context, 'Запрос отправлен руководителю');
      Navigator.of(context).pop();
    } else {
      UiFeedback.warning(
        context,
        'Нет сети — запрос в очереди, отправится при синхронизации',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<WorkerProfileProvider>().profile;
    final login = context.watch<AuthProvider>().userLogin;
    final readOnly = widget.readOnly ||
        (_loadedReport != null &&
            _loadedReport!.status != ReportStatus.draft &&
            _loadedReport!.status != ReportStatus.rejected);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(readOnly ? 'Запрос на изменение данных' : 'Изменить данные'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AuroraGradient.header),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Данные в системе',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'ФИО',
                            value: profile.fullName,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.business_outlined,
                            label: 'Место работы',
                            value: profile.displayEmployer,
                          ),
                          if (login != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Логин',
                              value: login,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (readOnly && _loadedReport != null) ...[
                      const SizedBox(height: 16),
                      ProfileChangeReportView(
                        report: _loadedReport!,
                        managerFeedback: _loadedReport!.managerFeedback,
                      ),
                      if (_loadedReport!.hasImages) ...[
                        const SizedBox(height: 12),
                        AppCard(
                          child: ReportImagesGallery(
                            imagePaths: _loadedReport!.imagePaths,
                            imageStorage: context.read<ImageStorageService>(),
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(
                        'Что изменить',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Заполните только те поля, которые нужно исправить. '
                        'Пустые поля останутся без изменений.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newNameController,
                        enabled: !readOnly,
                        decoration: const InputDecoration(
                          labelText: 'Новое ФИО',
                          hintText: 'Если ФИО верное — оставьте пустым',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newEmployerController,
                        enabled: !readOnly,
                        decoration: const InputDecoration(
                          labelText: 'Новое место работы',
                          hintText: 'Организация, филиал, подразделение',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        enabled: !readOnly,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Причина изменения *',
                          hintText: 'Например: опечатка при заведении учётки',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        enabled: !readOnly,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Дополнительно',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AttachedImagesPanel(
                        imageNames: _imageNames,
                        imageStorage: context.read<ImageStorageService>(),
                        onChanged: readOnly
                            ? (_) {}
                            : (names) => setState(() => _imageNames = names),
                      ),
                      if (_previewMarkdown != null) ...[
                        const SizedBox(height: 16),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Предпросмотр',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _previewMarkdown!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (!readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _buildPreview,
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('Сформировать запрос'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Отправить руководителю'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
