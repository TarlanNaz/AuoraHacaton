import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:structurator/models/report.dart';
import 'package:structurator/models/user_role.dart';
import 'package:structurator/providers/auth_provider.dart';
import 'package:structurator/providers/generation_provider.dart';
import 'package:structurator/providers/report_provider.dart';
import 'package:structurator/providers/template_provider.dart';
import 'package:structurator/providers/worker_profile_provider.dart';
import 'package:structurator/screens/worker/worker_dashboard.dart';
import 'package:structurator/services/giga_chat_service.dart';
import 'package:structurator/services/image_storage_service.dart';
import 'package:structurator/services/mock_report_api_service.dart';
import 'package:structurator/services/storage_service.dart';

import 'fakes.dart';

class FakeMockReportApi implements MockReportApiService {
  @override
  Future<bool> submitToManager(Report report) async => true;

  @override
  Future<void> syncPending() async {}
}

class HarnessHandles {
  HarnessHandles({
    required this.storage,
    required this.giga,
    required this.reports,
    required this.generation,
  });

  final FakeStorageService storage;
  final FakeGigaChatService giga;
  final ReportProvider reports;
  final GenerationProvider generation;
}

Future<HarnessHandles> pumpStructurator(
  WidgetTester tester, {
  FakeStorageService? storage,
  FakeGigaChatService? giga,
  String? manualToken,
}) async {
  final fakeStorage = storage ?? FakeStorageService();
  final fakeGiga = giga ?? FakeGigaChatService();

  if (manualToken != null && manualToken.isNotEmpty) {
    await fakeStorage.saveManualToken(manualToken);
  }

  final auth = AuthProvider(storage: fakeStorage);
  await auth.init();
  await auth.login(UserRole.worker);

  final templates = TemplateProvider(storage: fakeStorage);
  await templates.init();

  final profile = WorkerProfileProvider(storage: fakeStorage);
  await profile.init();

  final reports = ReportProvider(
    storage: fakeStorage,
    gigaChatService: fakeGiga,
    mockApi: FakeMockReportApi(),
  );
  await reports.init();

  final generation = GenerationProvider(service: fakeGiga);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: fakeStorage),
        Provider<GigaChatService>.value(value: fakeGiga),
        Provider<ImageStorageService>(
          create: (_) => FileImageStorageService(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<TemplateProvider>.value(value: templates),
        ChangeNotifierProvider<WorkerProfileProvider>.value(value: profile),
        ChangeNotifierProvider<ReportProvider>.value(value: reports),
        ChangeNotifierProvider<GenerationProvider>.value(value: generation),
      ],
      child: const MaterialApp(home: WorkerDashboard()),
    ),
  );

  await tester.pumpAndSettle();

  return HarnessHandles(
    storage: fakeStorage,
    giga: fakeGiga,
    reports: reports,
    generation: generation,
  );
}
