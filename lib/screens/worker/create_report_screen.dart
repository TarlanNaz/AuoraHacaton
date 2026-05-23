import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/report_prompts.dart';
import '../../config/sample_inputs.dart';
import '../../models/geo_place.dart';
import '../../models/report_type.dart';
import '../../providers/generation_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/worker_profile_provider.dart';
import '../../services/image_storage_service.dart';
import '../../services/location_service.dart';
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
  bool _geocoding = false;
  GeoPlace? _resolvedPlace;

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

    if (_rawController.text.isNotEmpty || _imageNames.isNotEmpty) {
      _autosave.schedule();
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
    if (raw.trim().isEmpty && !hasPhotos && _resultController.text.trim().isEmpty) {
      return;
    }

    setState(() => _autosaveUi = AutosaveUiState.saving);

    try {
      final rp = context.read<ReportProvider>();
      final profile = context.read<WorkerProfileProvider>().profile;
      final tpl = context.read<TemplateProvider>().templateForType(_type);

      final finalText = hasStructured ? _resultController.text : null;

      final saved = await rp.upsertDraft(
        existingId: _savedReportId,
        rawText: raw,
        finalText: finalText,
        type: _type,
        workerName: profile.fullName,
        imagePaths: _imageNames,
        templateId: tpl?.id,
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

  String? _locationPromptContext() {
    final place = _resolvedPlace;
    if (place == null) return null;
    return '${place.displayName} (координаты: ${place.coordinatesLabel})';
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

  Future<void> _resolveLocation() async {
    final query = _locationController.text.trim();
    if (query.length < 3) {
      UiFeedback.warning(context, 'Введите место не короче 3 символов');
      return;
    }

    setState(() => _geocoding = true);
    try {
      final place =
          await context.read<LocationService>().searchPlace(query);
      if (!mounted) return;
      if (place == null) {
        setState(() {
          _resolvedPlace = null;
          _geocoding = false;
        });
        UiFeedback.warning(context, 'Место не найдено. Уточните запрос.');
        return;
      }
      setState(() {
        _resolvedPlace = place;
        _geocoding = false;
      });
      UiFeedback.info(context, 'Место уточнено через OpenStreetMap');
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _geocoding = false);
      UiFeedback.warning(context, e.message);
    }
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
              child: Center(child: _AutosaveIndicator(state: _autosaveUi, savedAt: _lastSavedAt)),
            ),
          ],
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
              DropdownButtonFormField<ReportType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Тип отчёта',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportType.values
                      .where((t) => !t.isProfileChange)
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Место / объект',
                    hintText: 'Напр. цех Б, узел №4, Мурманск',
                    prefixIcon: const Icon(Icons.place_outlined),
                    suffixIcon: _geocoding
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Уточнить на карте (API 2)',
                            icon: const Icon(Icons.map_outlined),
                            onPressed: _geocoding ? null : _resolveLocation,
                          ),
                  ),
                  onSubmitted: (_) => _resolveLocation(),
                ),
                if (_resolvedPlace != null) ...[
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    borderColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resolvedPlace!.displayName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _resolvedPlace = null),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              _SamplesStrip(type: _type, onPick: _applySample),
              const SizedBox(height: 12),
                AttachedImagesPanel(
                  imageNames: _imageNames,
                  imageStorage: context.read<ImageStorageService>(),
                  onChanged: _onImagesChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _rawController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Сырые заметки',
                    hintText: 'Кратко, как в блокноте. Сохраняется автоматически.',
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
                SizedBox(
                  height: 220,
                  child: _ResultArea(controller: _resultController),
                ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Consumer<GenerationProvider>(
                  builder: (context, gen, _) {
                    if (gen.status != GenerationStatus.success) {
                      return const SizedBox.shrink();
                    }
                    return FilledButton.icon(
                      onPressed: _sending ? null : _sendToManager,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Отправить руководителю'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AutosaveUiState { idle, pending, saving, saved, error }

class _AutosaveIndicator extends StatelessWidget {
  const _AutosaveIndicator({required this.state, this.savedAt});

  final AutosaveUiState state;
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = switch (state) {
      AutosaveUiState.idle => (
          Icons.cloud_outlined,
          'Черновик',
          theme.colorScheme.onSurfaceVariant,
        ),
      AutosaveUiState.pending => (
          Icons.cloud_sync_outlined,
          '…',
          theme.colorScheme.onSurfaceVariant,
        ),
      AutosaveUiState.saving => (
          Icons.cloud_upload_outlined,
          'Сохранение',
          theme.colorScheme.primary,
        ),
      AutosaveUiState.saved => (
          Icons.cloud_done_outlined,
          savedAt != null ? DateFormat('HH:mm').format(savedAt!) : 'Сохранено',
          theme.colorScheme.primary,
        ),
      AutosaveUiState.error => (
          Icons.cloud_off_outlined,
          'Ошибка',
          theme.colorScheme.error,
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
                    Text(
                      'Редактируйте отчёт — изменения сохраняются автоматически',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
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
