import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/report_prompts.dart';
import '../../config/sample_inputs.dart';
import '../../models/report_type.dart';
import '../../providers/generation_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../services/image_storage_service.dart';
import '../../utils/draft_autosave.dart';
import '../../utils/ui_feedback.dart';
import '../../widgets/app_ui.dart';
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
  late final TextEditingController _locationController;
  late ReportType _type;
  late List<String> _imageNames;
  String? _savedReportId;
  bool _sending = false;
  late final DraftAutosave _autosave;
  AutosaveUiState _autosaveUi = AutosaveUiState.idle;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    _rawController = TextEditingController(text: widget.initialText ?? '');
    _resultController = TextEditingController();
    _locationController = TextEditingController();
    _type = widget.initialType ?? ReportType.incident;
    _imageNames = List.from(widget.initialImagePaths);
    _savedReportId = widget.reportId;

    _autosave = DraftAutosave(
      debounce: ReportPrompts.draftAutosaveDebounce,
      onSave: _persistDraft,
    );

    _rawController.addListener(_onContentChanged);
    _resultController.addListener(_onContentChanged);
    _locationController.addListener(_onLocationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraftFromReport());

    if (_rawController.text.isNotEmpty ||
        _imageNames.isNotEmpty ||
        _savedReportId != null) {
      _autosave.schedule();
    }
  }

  void _onLocationChanged() {
    if (!mounted) return;
    setState(() => _autosaveUi = AutosaveUiState.pending);
    _autosave.schedule();
  }

  void _loadDraftFromReport() {
    final id = _savedReportId;
    if (id == null) return;

    final matches =
        context.read<ReportProvider>().workerReports.where((r) => r.id == id);
    if (matches.isEmpty) return;
    final report = matches.first;

    if ((report.finalText ?? '').isNotEmpty) {
      _resultController.text = report.finalText!;
    }
    if ((report.rawText ?? '').isNotEmpty && _rawController.text.isEmpty) {
      _rawController.text = report.rawText!;
    }

    final locationText =
        report.locationQuery ?? report.locationName ?? '';
    if (locationText.isNotEmpty) {
      _locationController.text = locationText;
    }
  }

  @override
  void dispose() {
    _autosave.dispose();
    _rawController.dispose();
    _resultController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!mounted) return;
    setState(() => _autosaveUi = AutosaveUiState.pending);
    _autosave.schedule();
  }

  Future<void> _persistDraft() async {
    if (!mounted) return;

    final gen = context.read<GenerationProvider>();
    final hasStructured = gen.status == GenerationStatus.success;
    final raw = hasStructured ? '' : _rawController.text;
    final hasPhotos = _imageNames.isNotEmpty;
    if (raw.trim().isEmpty &&
        !hasPhotos &&
        _resultController.text.trim().isEmpty &&
        !_hasLocationDraft()) {
      return;
    }

    setState(() => _autosaveUi = AutosaveUiState.saving);

    try {
      final rp = context.read<ReportProvider>();
      final profile = context.read<WorkerProfileProvider>().profile;
      final tpl = context.read<TemplateProvider>().templateForType(_type);

      final finalText = hasStructured ? _resultController.text : null;

      final locQuery = _locationController.text.trim();

      final saved = await rp.upsertDraft(
        existingId: _savedReportId,
        rawText: raw,
        finalText: finalText,
        type: _type,
        workerName: profile.fullName,
        imagePaths: _imageNames,
        templateId: tpl?.id,
        locationQuery: locQuery.isEmpty ? null : locQuery,
        locationName: locQuery.isEmpty ? null : locQuery,
      );

      if (!mounted) return;
      if (saved != null) {
        _savedReportId = saved.id;
        setState(() {
          _autosaveUi = AutosaveUiState.saved;
          _lastSavedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _autosaveUi = AutosaveUiState.error);
    }
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

  bool _hasLocationDraft() => _locationController.text.trim().isNotEmpty;

  String? _locationPromptContext() {
    final q = _locationController.text.trim();
    return q.isEmpty ? null : q;
  }

  String _systemPrompt() {
    final tpl = context.read<TemplateProvider>().instructionForType(_type);
    final name = context.read<WorkerProfileProvider>().profile.fullName;
    return ReportPrompts.buildSystemPrompt(
      type: _type,
      templateInstruction: tpl,
      imageCount: _imageNames.length,
      workerName: name,
      locationContext: _locationPromptContext(),
    );
  }

  Future<void> _generate() async {
    await _autosave.flush();

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
      _autosave.schedule();
      if (mounted) {
        UiFeedback.info(context, 'Отчёт сгенерирован. Правки сохраняются автоматически');
      }
    }
  }

  Future<void> _sendToManager() async {
    await _autosave.flush();

    if (_savedReportId == null) {
      UiFeedback.warning(context, 'Сначала введите заметки или сгенерируйте отчёт');
      return;
    }

    final gen = context.read<GenerationProvider>();
    if (gen.status != GenerationStatus.success &&
        _resultController.text.trim().isEmpty) {
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

  Future<bool> _onWillPop() async {
    await _autosave.flush();
    return true;
  }

  void _applySample(SampleInput s) {
    setState(() => _type = s.reportType);
    _rawController.text = s.body;
    _autosave.schedule();
    UiFeedback.info(
      context,
      s.requiresPhoto ? 'Добавьте фото — без них отчёт будет неполным' : 'Пример вставлен',
    );
  }

  void _onImagesChanged(List<String> names) {
    setState(() => _imageNames = names);
    _autosave.schedule();
  }

  void _onTypeChanged(ReportType? v) {
    setState(() => _type = v ?? _type);
    _autosave.schedule();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _autosave.flush();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Создание отчёта'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AuroraGradient.header),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final leave = await _onWillPop();
              if (leave && context.mounted) Navigator.maybePop(context);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _AutosaveIndicator(
                  state: _autosaveUi,
                  savedAt: _lastSavedAt,
                  onDarkBackground: true,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppFormSection(
                      title: 'Тип и объект',
                      subtitle: 'Укажите место текстом — сохранится в черновик',
                      icon: Icons.place_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<ReportType>(
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Тип отчёта',
                            ),
                            items: ReportType.values
                                .where((t) => !t.isProfileChange)
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _onTypeChanged,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Место / объект',
                              hintText: 'Например: цех Б, узел №4',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppFormSection(
                      title: 'Материалы',
                      subtitle: 'Фото и готовые примеры для типа отчёта',
                      icon: Icons.photo_library_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AttachedImagesPanel(
                            imageNames: _imageNames,
                            imageStorage:
                                context.read<ImageStorageService>(),
                            onChanged: _onImagesChanged,
                          ),
                          const SizedBox(height: 12),
                          _SamplesStrip(type: _type, onPick: _applySample),
                        ],
                      ),
                    ),
                    AppFormSection(
                      title: 'Сырые заметки',
                      subtitle: 'Кратко, как в блокноте — ИИ оформит по шаблону',
                      icon: Icons.edit_note_outlined,
                      child: TextField(
                        controller: _rawController,
                        maxLines: 5,
                        minLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Сырые заметки',
                          hintText: 'Факты, цифры, что видели на объекте',
                        ),
                      ),
                    ),
                    AppFormSection(
                      title: 'Структурированный отчёт',
                      subtitle: 'Появится после генерации, можно править',
                      icon: Icons.auto_awesome_outlined,
                      child: SizedBox(
                        height: 240,
                        child: _ResultArea(controller: _resultController),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Consumer<GenerationProvider>(
              builder: (context, gen, _) {
                return AppBottomActionBar(
                  children: [
                    FilledButton.icon(
                      onPressed: gen.isLoading ? null : _generate,
                      icon: gen.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        gen.isLoading ? 'Анализ…' : 'Сгенерировать отчёт',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppTheme.minTouchTarget,
                        ),
                      ),
                    ),
                    if (gen.status == GenerationStatus.success) ...[
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _sending ? null : _sendToManager,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(
                            AppTheme.minTouchTarget,
                          ),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Отправить руководителю'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum AutosaveUiState { idle, pending, saving, saved, error }

class _AutosaveIndicator extends StatelessWidget {
  const _AutosaveIndicator({
    required this.state,
    this.savedAt,
    this.onDarkBackground = false,
  });

  final AutosaveUiState state;
  final DateTime? savedAt;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = onDarkBackground
        ? Colors.white.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;
    final accent = onDarkBackground ? Colors.white : theme.colorScheme.primary;
    final (icon, label, color) = switch (state) {
      AutosaveUiState.idle => (Icons.cloud_outlined, 'Черновик', muted),
      AutosaveUiState.pending => (Icons.cloud_sync_outlined, '…', muted),
      AutosaveUiState.saving => (
          Icons.cloud_upload_outlined,
          'Сохранение',
          accent,
        ),
      AutosaveUiState.saved => (
          Icons.cloud_done_outlined,
          savedAt != null ? DateFormat('HH:mm').format(savedAt!) : 'Сохранено',
          accent,
        ),
      AutosaveUiState.error => (
          Icons.cloud_off_outlined,
          'Ошибка',
          onDarkBackground ? const Color(0xFFFFCDD2) : theme.colorScheme.error,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
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
            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.demoPanelBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Нажмите «Сгенерировать отчёт» внизу экрана',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            );
          case GenerationStatus.loading:
            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          case GenerationStatus.error:
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(gen.error ?? 'Ошибка'),
              ),
            );
          case GenerationStatus.success:
            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Структурированный текст…',
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
