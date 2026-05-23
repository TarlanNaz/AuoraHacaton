import 'report_type.dart';

/// Шаблон инструкций для GigaChat, создаётся руководителем.
class ReportTemplate {
  final String id;
  final String title;
  final ReportType? reportType;
  final String instruction;
  final bool isDefault;

  const ReportTemplate({
    required this.id,
    required this.title,
    this.reportType,
    required this.instruction,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reportType': reportType?.id,
        'instruction': instruction,
        'isDefault': isDefault,
      };

  factory ReportTemplate.fromJson(Map<String, dynamic> json) => ReportTemplate(
        id: json['id'] as String,
        title: json['title'] as String,
        reportType: json['reportType'] == null
            ? null
            : ReportType.fromId(json['reportType'] as String?),
        instruction: json['instruction'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  ReportTemplate copyWith({
    String? title,
    ReportType? reportType,
    String? instruction,
    bool? isDefault,
  }) {
    return ReportTemplate(
      id: id,
      title: title ?? this.title,
      reportType: reportType ?? this.reportType,
      instruction: instruction ?? this.instruction,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
