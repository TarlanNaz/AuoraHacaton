import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/report_template.dart';
import '../../models/report_type.dart';
import '../../providers/template_provider.dart';

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
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _edit(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Новый шаблон'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tp.templates.length,
                itemBuilder: (context, i) {
                  final t = tp.templates[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(t.title),
                      subtitle: Text(
                        t.instruction,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: t.isDefault
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => tp.remove(t.id),
                            ),
                      onTap: () => _edit(context, t),
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
                  value: type,
                  decoration: const InputDecoration(labelText: 'Тип отчёта'),
                  items: ReportType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
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
