import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/report_prompts.dart';
import '../../config/sample_inputs.dart';
import '../../models/report_type.dart';
import '../../providers/generation_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../services/image_storage_service.dart';
import '../../utils/ui_feedback.dart';
import '../widgets/attached_images_panel.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({
    super.key,
    this.initialText,
    this.initialImagePaths = const [],
    this.initialType,
    this.reportId,
  });

  final String? initialText;
  final List<String> initialImagePaths;
  final ReportType? initialType;
  final String? reportId;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  late final TextEditingController _rawController;
  late final TextEditingController _resultController;
  late ReportType _type;
  late List<String> _imageNames;
  String? _savedReportId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _rawController = TextEditingController(text: widget.initialText ?? '');
    _resultController = TextEditingController();
    _type = widget.initialType ?? ReportType.incident;
    _imageNames = List.from(widget.initialImagePaths);
    _savedReportId = widget.reportId;
  }

  @override
  void dispose() {
    _rawController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<List<File>> _imageFiles() async {
    final storage = context.read<ImageStorageService>();
    final files = <File>[];
    for (final n in _imageNames) {
      final f = await storage.resolveFile(n);
      if (await f.exists()) files.add(f);
    }
    return files;
  }

  String _systemPrompt() {
    final tpl = context.read<TemplateProvider>().instructionForType(_type);
    return ReportPrompts.buildSystemPrompt(
      type: _type,
      templateInstruction: tpl,
      imageCount: _imageNames.length,
    );
  }

  Future<void> _generate() async {
    final raw = _rawController.text.trim();
    if (raw.isEmpty && _imageNames.isEmpty) {
      UiFeedback.warning(context, 'Введите текст или прикрепите фото');
      return;
    }

    final reports = context.read<ReportProvider>();
    if (!reports.hasCredentials) {
      UiFeedback.warning(context, 'Настройте GIGACHAT_AUTH_KEY в .env');
      return;
    }

    FocusScope.of(context).unfocus();
    final gen = context.read<GenerationProvider>();
    await gen.generate(
      rawText: raw,
      tokenResolver: reports.ensureToken,
      imageFiles: await _imageFiles(),
      systemPrompt: _systemPrompt(),
    );

    if (!mounted) return;
    if (gen.status == GenerationStatus.success && gen.result != null) {
      _resultController.text = gen.result!;
      final workerName = context.read<WorkerProfileProvider>().profile.fullName;
      final saved = await reports.saveGenerated(
        finalText: gen.result!,
        type: _type,
        workerName: workerName,
        imagePaths: _imageNames,
        templateId: context.read<TemplateProvider>().templateForType(_type)?.id,
        existingId: _savedReportId,
      );
      _savedReportId = saved.id;
      UiFeedback.info(context, 'Отчёт сгенерирован. Можно отредактировать перед отправкой');
    }
  }

  Future<void> _saveDraft() async {
    final raw = _rawController.text.trim();
    if (raw.isEmpty && _imageNames.isEmpty) return;
    final rp = context.read<ReportProvider>();
    final workerName = context.read<WorkerProfileProvider>().profile.fullName;
    final r = await rp.saveDraft(
      rawText: raw.isEmpty ? 'Черновик с фото (см. приложения)' : raw,
      type: _type,
      workerName: workerName,
      imagePaths: _imageNames,
    );
    _savedReportId = r.id;
    UiFeedback.draftSavedLocally(context);
  }

  Future<void> _sendToManager() async {
    if (_savedReportId == null) {
      UiFeedback.warning(context, 'Сначала сгенерируйте отчёт');
      return;
    }

    setState(() => _sending = true);
    final edited = _resultController.text.trim();
    if (edited.isNotEmpty) {
      await context.read<ReportProvider>().saveGenerated(
        finalText: edited,
        type: _type,
        workerName: context.read<WorkerProfileProvider>().profile.fullName,
        imagePaths: _imageNames,
        existingId: _savedReportId,
      );
    }

    final ok = await context.read<ReportProvider>().sendToManager(_savedReportId!);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      UiFeedback.info(context, 'Отправлено руководителю');
      Navigator.of(context).pop();
    } else {
      UiFeedback.warning(
        context,
        'Нет сети — отчёт в очереди, отправится при синхронизации',
      );
    }
  }

  void _applySample(SampleInput s) {
    setState(() => _type = s.reportType);
    _rawController.text = s.body;
    UiFeedback.info(
      context,
      s.requiresPhoto ? 'Добавьте фото — без них отчёт будет неполным' : 'Пример вставлен',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание отчёта'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ReportType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Тип отчёта',
                  border: OutlineInputBorder(),
                ),
                items: ReportType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              _SamplesStrip(type: _type, onPick: _applySample),
              const SizedBox(height: 12),
              AttachedImagesPanel(
                imageNames: _imageNames,
                imageStorage: context.read<ImageStorageService>(),
                onChanged: (n) => setState(() => _imageNames = n),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rawController,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Сырые заметки',
                  hintText: 'Кратко, как в блокноте. Детали — на фото.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<GenerationProvider>(
                builder: (context, gen, _) => FilledButton.icon(
                  onPressed: gen.isLoading ? null : _generate,
                  icon: gen.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(gen.isLoading ? 'Анализ…' : 'Сгенерировать'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _ResultArea(controller: _resultController)),
              const SizedBox(height: 8),
              Consumer<GenerationProvider>(
                builder: (context, gen, _) {
                  if (gen.status != GenerationStatus.success &&
                      gen.status != GenerationStatus.error) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saveDraft,
                          child: const Text('Черновик'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _sending || gen.status != GenerationStatus.success
                              ? null
                              : _sendToManager,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text('Отправить руководителю'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SamplesStrip extends StatelessWidget {
  const _SamplesStrip({required this.type, required this.onPick});
  final ReportType type;
  final ValueChanged<SampleInput> onPick;

  @override
  Widget build(BuildContext context) {
    final samples = SampleInputs.forType(type);
    if (samples.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: samples.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final s = samples[i];
          return ActionChip(
            avatar: Icon(s.icon, size: 18),
            label: Text(s.title),
            onPressed: () => onPick(s),
          );
        },
      ),
    );
  }
}

class _ResultArea extends StatelessWidget {
  const _ResultArea({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerationProvider>(
      builder: (context, gen, _) {
        switch (gen.status) {
          case GenerationStatus.empty:
            return Card(
              child: Center(
                child: Text(
                  'Результат появится здесь',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            );
          case GenerationStatus.loading:
            return const Card(
              child: Center(child: CircularProgressIndicator()),
            );
          case GenerationStatus.error:
            return Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(gen.error ?? 'Ошибка'),
              ),
            );
          case GenerationStatus.success:
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Редактируйте отчёт перед отправкой',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Структурированный текст…',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
