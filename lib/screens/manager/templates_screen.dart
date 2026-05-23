import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_theme.dart';
import '../../models/report_template.dart';
import '../../models/report_type.dart';
import '../../providers/template_provider.dart';
import '../../widgets/app_ui.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateProvider>(
      builder: (context, tp, _) {
        if (tp.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilledButton.icon(
                onPressed: () => _edit(context, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Новый шаблон'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppTheme.minTouchTarget),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tp.templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = tp.templates[i];
                  final scheme = Theme.of(context).colorScheme;
                  return AppCard(
                    onTap: () => _edit(context, t),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Icon(
                            t.reportType?.icon ?? Icons.description_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (t.reportType != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  t.reportType!.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: scheme.primary),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                t.instruction,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (!t.isDefault)
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: scheme.error),
                            onPressed: () => tp.remove(t.id),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, ReportTemplate? existing) async {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final instrC = TextEditingController(text: existing?.instruction ?? '');
    var type = existing?.reportType ?? ReportType.incident;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Новый шаблон' : 'Редактировать'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Тип отчёта'),
                  items: ReportType.values
                      .where((t) => !t.isProfileChange)
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setSt(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instrC,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Инструкция для ИИ',
                    hintText: 'Обязательно указывать причину, время…',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Сохранить')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<TemplateProvider>().upsert(
            ReportTemplate(
              id: existing?.id ?? const Uuid().v4(),
              title: titleC.text.trim(),
              reportType: type,
              instruction: instrC.text.trim(),
            ),
          );
    }
  }
}
