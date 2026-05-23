import 'package:flutter/material.dart';

import '../models/profile_change_draft.dart';
import '../models/report.dart';
import 'app_ui.dart';

/// Отдельное отображение запроса на изменение данных (B2G, без «полевого» отчёта).
class ProfileChangeReportView extends StatelessWidget {
  const ProfileChangeReportView({
    super.key,
    required this.report,
    this.managerFeedback,
  });

  final Report report;
  final String? managerFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ProfileChangeDraft.tryParseRaw(report.rawText);
    final body = report.finalText ?? report.rawText ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderColor: theme.colorScheme.primary.withValues(alpha: 0.25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.badge_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Запрос на изменение данных',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сотрудник: ${report.workerName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (draft != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Запрашиваемые изменения',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChangeRow(
                  label: 'ФИО',
                  value: draft.newFullName.trim().isEmpty
                      ? 'Без изменений'
                      : draft.newFullName.trim(),
                  changed: draft.newFullName.trim().isNotEmpty,
                ),
                const SizedBox(height: 8),
                _ChangeRow(
                  label: 'Место работы',
                  value: draft.newEmployer.trim().isEmpty
                      ? 'Без изменений'
                      : draft.newEmployer.trim(),
                  changed: draft.newEmployer.trim().isNotEmpty,
                ),
                if (report.hasImages) ...[
                  const SizedBox(height: 8),
                  _ChangeRow(
                    label: 'Фото',
                    value: 'Приложено новое фото',
                    changed: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Причина',
            child: Text(
              draft.reason.trim().isEmpty ? '—' : draft.reason.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          if (draft.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Дополнительно',
              child: Text(
                draft.notes.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Полный текст запроса', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              SelectableText(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
        if ((managerFeedback ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            borderColor: theme.colorScheme.error.withValues(alpha: 0.4),
            backgroundColor:
                theme.colorScheme.errorContainer.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.feedback_outlined,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Замечания руководителя',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(managerFeedback!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.value,
    required this.changed,
  });

  final String label;
  final String value;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = changed ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: changed ? FontWeight.w600 : FontWeight.normal,
              color: color,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
