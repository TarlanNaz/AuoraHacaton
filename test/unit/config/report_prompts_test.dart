import 'package:flutter_test/flutter_test.dart';
import 'package:structurator/config/report_prompts.dart';
import 'package:structurator/models/report_type.dart';

void main() {
  test('buildSystemPrompt includes type and anti-hallucination rules', () {
    final prompt = ReportPrompts.buildSystemPrompt(
      type: ReportType.incident,
      imageCount: 2,
      workerName: 'Иванов А.П.',
      templateInstruction: 'Укажи ответственного',
    );

    expect(prompt, contains('ИНЦИДЕНТ'));
    expect(prompt, contains('Иванов А.П.'));
    expect(prompt, contains('Укажи ответственного'));
    expect(prompt, contains('Фотофиксация'));
    expect(prompt, contains('приложено 2 фото'));
  });

  test('text-only prompt forbids inventing photo details', () {
    final prompt = ReportPrompts.buildSystemPrompt(
      type: ReportType.metrics,
      imageCount: 0,
    );
    expect(prompt, contains('без просмотра фото'));
  });

  test('includes input invalid marker instructions', () {
    final prompt = ReportPrompts.buildSystemPrompt(
      type: ReportType.incident,
      imageCount: 0,
    );
    expect(prompt, contains(ReportPrompts.inputInvalidMarker));
    expect(prompt, contains('ОТКАЗ ОТ ГЕНЕРАЦИИ'));
  });
}
