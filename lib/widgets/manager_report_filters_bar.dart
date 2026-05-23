import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/report_type.dart';
import '../utils/manager_report_filter.dart';
import 'app_ui.dart';

/// Панель фильтров: тип отчёта и период отправки.
class ManagerReportFiltersBar extends StatelessWidget {
  const ManagerReportFiltersBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.resultCount,
    required this.totalCount,
  });

  final ManagerReportFilter filter;
  final ValueChanged<ManagerReportFilter> onChanged;
  final int resultCount;
  final int totalCount;

  static final _df = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        backgroundColor: scheme.surfaceContainerLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Фильтры', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '$resultCount / $totalCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportType?>(
              key: ValueKey('report_type_${filter.type?.id ?? 'all'}'),
              initialValue: filter.type,
              decoration: const InputDecoration(
                labelText: 'Тип отчёта',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все типы')),
                ...ReportType.values.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                ),
              ],
              onChanged: (v) => onChanged(
                filter.copyWith(type: v, clearType: v == null),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Отправлен с',
                    value: filter.dateFrom,
                    onPick: (d) => onChanged(filter.copyWith(dateFrom: d)),
                    onClear: () =>
                        onChanged(filter.copyWith(clearDateFrom: true)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'Отправлен по',
                    value: filter.dateTo,
                    onPick: (d) => onChanged(filter.copyWith(dateTo: d)),
                    onClear: () => onChanged(filter.copyWith(clearDateTo: true)),
                  ),
                ),
              ],
            ),
            if (filter.hasActiveFilters)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onChanged(ManagerReportFilter.empty),
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Сбросить'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text =
        value != null ? ManagerReportFiltersBar._df.format(value!) : '';
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 1),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          text.isEmpty ? '—' : text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
