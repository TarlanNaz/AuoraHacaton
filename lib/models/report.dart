import 'package:intl/intl.dart';

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
  /// Момент отправки руководителю (фиксируется при [ReportStatus.sent]).
  final DateTime? sentAt;
  final List<String> imagePaths;
  final String workerName;
  final String? templateId;
  /// Комментарий руководителя при отклонении или замечания.
  final String? managerFeedback;
  /// Текст в поле «Место / объект».
  final String? locationQuery;
  /// Адрес после геокодирования или GPS.
  final String? locationName;
  final double? locationLat;
  final double? locationLon;

  const Report({
    required this.id,
    this.rawText,
    this.finalText,
    required this.type,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.imagePaths = const [],
    this.workerName = WorkerProfile.defaultName,
    this.templateId,
    this.managerFeedback,
    this.locationQuery,
    this.locationName,
    this.locationLat,
    this.locationLon,
  });

  /// Обратная совместимость со старым UI/тестами.
  bool get isDraft => status == ReportStatus.draft;
  String? get structuredText => finalText;

  String get displayBody => finalText ?? rawText ?? '';
  bool get hasStructured => (finalText ?? '').isNotEmpty;
  bool get hasRawData => (rawText ?? '').isNotEmpty;
  bool get hasImages => imagePaths.isNotEmpty;

  bool get hasLocationCoords => locationLat != null && locationLon != null;

  bool get hasLocationData =>
      (locationQuery ?? '').trim().isNotEmpty || hasLocationCoords;

  /// Для списков и фильтров руководителя (дата отправки).
  DateTime get submittedAt => sentAt ?? createdAt;

  bool get hasSentTimestamp =>
      sentAt != null || status != ReportStatus.draft;

  /// Подпись даты для UI руководителя.
  String sentAtLabel(DateFormat formatter) {
    if (status == ReportStatus.draft) {
      return 'Черновик · ${formatter.format(createdAt)}';
    }
    return 'Отправлен ${formatter.format(submittedAt)}';
  }

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
    DateTime? sentAt,
    List<String>? imagePaths,
    String? workerName,
    String? templateId,
    String? managerFeedback,
    String? locationQuery,
    String? locationName,
    double? locationLat,
    double? locationLon,
    bool clearRawText = false,
    bool clearManagerFeedback = false,
    bool clearSentAt = false,
    bool clearLocation = false,
  }) {
    return Report(
      id: id ?? this.id,
      rawText: clearRawText ? null : (rawText ?? this.rawText),
      finalText: finalText ?? this.finalText,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: clearSentAt ? null : (sentAt ?? this.sentAt),
      imagePaths: imagePaths ?? this.imagePaths,
      workerName: workerName ?? this.workerName,
      templateId: templateId ?? this.templateId,
      managerFeedback: clearManagerFeedback
          ? null
          : (managerFeedback ?? this.managerFeedback),
      locationQuery: clearLocation ? null : (locationQuery ?? this.locationQuery),
      locationName: clearLocation ? null : (locationName ?? this.locationName),
      locationLat: clearLocation ? null : (locationLat ?? this.locationLat),
      locationLon: clearLocation ? null : (locationLon ?? this.locationLon),
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
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        'imagePaths': imagePaths,
        'workerName': workerName,
        'templateId': templateId,
        'managerFeedback': managerFeedback,
        if (locationQuery != null) 'locationQuery': locationQuery,
        if (locationName != null) 'locationName': locationName,
        if (locationLat != null) 'locationLat': locationLat,
        if (locationLon != null) 'locationLon': locationLon,
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
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      imagePaths: images,
      workerName: json['workerName'] as String? ?? WorkerProfile.defaultName,
      templateId: json['templateId'] as String?,
      managerFeedback: json['managerFeedback'] as String?,
      locationQuery: json['locationQuery'] as String?,
      locationName: json['locationName'] as String?,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLon: (json['locationLon'] as num?)?.toDouble(),
    );
  }
}
