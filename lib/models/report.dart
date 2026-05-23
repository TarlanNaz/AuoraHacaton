import 'report_status.dart';
import 'report_type.dart';
import 'worker_profile.dart';

/// Отчёт полевого сотрудника или запись во входящих руководителя.
class Report {
  final String id;
  final String? rawText;
  final String? finalText;
  final ReportType type;
  final ReportStatus status;
  final DateTime createdAt;
  final List<String> imagePaths;
  final String workerName;
  final String? templateId;
  /// Комментарий руководителя при отклонении или замечания.
  final String? managerFeedback;

  const Report({
    required this.id,
    this.rawText,
    this.finalText,
    required this.type,
    required this.status,
    required this.createdAt,
    this.imagePaths = const [],
    this.workerName = WorkerProfile.defaultName,
    this.templateId,
    this.managerFeedback,
  });

  /// Обратная совместимость со старым UI/тестами.
  bool get isDraft => status == ReportStatus.draft;
  String? get structuredText => finalText;

  String get displayBody => finalText ?? rawText ?? '';
  bool get hasStructured => (finalText ?? '').isNotEmpty;
  bool get hasRawData => (rawText ?? '').isNotEmpty;
  bool get hasImages => imagePaths.isNotEmpty;

  String get title {
    final source = displayBody.trim();
    if (source.isEmpty && hasImages) {
      return '${type.label} (с фото)';
    }
    if (source.isEmpty) return type.label;

    final firstLine = source
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[#*_>`]'), '').trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => type.label);

    return firstLine.length > 64
        ? '${firstLine.substring(0, 64)}…'
        : firstLine;
  }

  Report copyWith({
    String? id,
    String? rawText,
    String? finalText,
    ReportType? type,
    ReportStatus? status,
    DateTime? createdAt,
    List<String>? imagePaths,
    String? workerName,
    String? templateId,
    String? managerFeedback,
    bool clearRawText = false,
    bool clearManagerFeedback = false,
  }) {
    return Report(
      id: id ?? this.id,
      rawText: clearRawText ? null : (rawText ?? this.rawText),
      finalText: finalText ?? this.finalText,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imagePaths: imagePaths ?? this.imagePaths,
      workerName: workerName ?? this.workerName,
      templateId: templateId ?? this.templateId,
      managerFeedback: clearManagerFeedback
          ? null
          : (managerFeedback ?? this.managerFeedback),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'finalText': finalText,
        'structuredText': finalText,
        'type': type.id,
        'status': status.id,
        'createdAt': createdAt.toIso8601String(),
        'imagePaths': imagePaths,
        'workerName': workerName,
        'templateId': templateId,
        'managerFeedback': managerFeedback,
        'isDraft': isDraft,
      };

  factory Report.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagePaths'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    ReportStatus status;
    if (json['status'] != null) {
      status = ReportStatus.fromId(json['status'] as String?);
    } else {
      status = (json['isDraft'] as bool? ?? false)
          ? ReportStatus.draft
          : ReportStatus.synced;
    }

    return Report(
      id: json['id'] as String,
      rawText: json['rawText'] as String?,
      finalText: (json['finalText'] ?? json['structuredText']) as String?,
      type: ReportType.fromId(json['type'] as String?),
      status: status,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePaths: images,
      workerName: json['workerName'] as String? ?? WorkerProfile.defaultName,
      templateId: json['templateId'] as String?,
      managerFeedback: json['managerFeedback'] as String?,
    );
  }
}
