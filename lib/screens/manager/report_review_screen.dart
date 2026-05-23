import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../providers/report_provider.dart';
import '../../services/image_storage_service.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/report_chips.dart';
import '../../widgets/profile_change_report_view.dart';
import '../../widgets/report_images_gallery.dart';

class ReportReviewScreen extends StatelessWidget {
  const ReportReviewScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd.MM.yyyy · HH:mm');
    final isProfileChange = report.type.isProfileChange;
    final canReview = report.status == ReportStatus.sent;
    final imageStorage = context.read<ImageStorageService>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          isProfileChange ? 'Изменение данных' : report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AuroraGradient.header),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, rp, _) {
          final idx = rp.managerInbox.indexWhere((r) => r.id == report.id);
          final current = idx >= 0 ? rp.managerInbox[idx] : report;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!isProfileChange)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ReportTypeChip(type: current.type),
                          ReportStatusChip(status: current.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              current.workerName,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            current.sentAtLabel(df),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (isProfileChange) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ReportTypeChip(type: current.type),
                    ReportStatusChip(status: current.status),
                  ],
                ),
                const SizedBox(height: 12),
                ProfileChangeReportView(
                  report: current,
                  managerFeedback: canReview ? null : current.managerFeedback,
                ),
                if (current.hasImages) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: ReportImagesGallery(
                      imagePaths: current.imagePaths,
                      imageStorage: imageStorage,
                    ),
                  ),
                ],
              ] else ...[
                if (current.hasImages) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: ReportImagesGallery(
                      imagePaths: current.imagePaths,
                      imageStorage: imageStorage,
                    ),
                  ),
                ],
                if (current.hasLocationData) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Место объекта', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          current.locationName ??
                              current.locationQuery ??
                              '—',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (current.hasLocationCoords) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Координаты: ${current.locationLat!.toStringAsFixed(5)}, '
                            '${current.locationLon!.toStringAsFixed(5)}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Текст отчёта', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SelectableText(
                        current.finalText ?? current.rawText ?? '—',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
              ],
              if (canReview) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _accept(context, current.id),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isProfileChange ? 'Одобрить изменения' : 'Принять отчёт',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _reject(context, current.id),
                  icon: const Icon(Icons.cancel_outlined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  label: Text(
                    isProfileChange
                        ? 'Отклонить запрос'
                        : 'Отклонить с замечаниями',
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _accept(BuildContext context, String id) async {
    await context.read<ReportProvider>().acceptReport(id);
    if (!context.mounted) return;
    UiFeedback.info(context, 'Отчёт принят');
    Navigator.of(context).pop();
  }

  Future<void> _reject(BuildContext context, String id) async {
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectDialog(),
    );
    if (feedback == null || feedback.trim().isEmpty) return;
    if (!context.mounted) return;

    try {
      await context.read<ReportProvider>().rejectReport(id, feedback);
      if (!context.mounted) return;
      UiFeedback.info(context, 'Отчёт отклонён, рабочий увидит замечания');
      Navigator.of(context).pop();
    } on ArgumentError catch (e) {
      if (context.mounted) {
        UiFeedback.warning(context, e.message?.toString() ?? 'Ошибка');
      }
    }
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Отклонить отчёт'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Что исправить',
          hintText: 'Укажите ошибки, нехватку данных, неверные формулировки…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Отклонить'),
        ),
      ],
    );
  }
}
