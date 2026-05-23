import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/env.dart';
import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/generation_provider.dart';
import 'providers/report_provider.dart';
import 'providers/template_provider.dart';
import 'providers/worker_profile_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'services/mock_auth_service.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/worker/worker_dashboard.dart';
import 'services/giga_chat_service.dart';
import 'services/image_storage_service.dart';
import 'services/mock_report_api_service.dart';
import 'services/storage_service.dart';
import 'utils/app_logger.dart';

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (kDebugMode) {
      client.badCertificateCallback = (cert, host, port) {
        AppLogger.warn('TLS', 'accepting cert in debug mode for $host');
        return true;
      };
    }
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _DevHttpOverrides();
  await Env.load();
  runApp(const StructuratorApp());
}

class StructuratorApp extends StatelessWidget {
  const StructuratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(create: (_) => SharedPrefsStorageService()),
        Provider<GigaChatService>(create: (_) => HttpGigaChatService()),
        Provider<ImageStorageService>(create: (_) => FileImageStorageService()),
        Provider<MockReportApiService>(
          create: (ctx) => HttpMockReportApiService(ctx.read<StorageService>()),
        ),
        Provider<MockAuthService>(
          create: (ctx) => LocalMockAuthService(ctx.read<StorageService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(
            storage: ctx.read<StorageService>(),
            authService: ctx.read<MockAuthService>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TemplateProvider(storage: ctx.read<StorageService>())..init(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => WorkerProfileProvider(
            storage: ctx.read<StorageService>(),
            imageStorage: ctx.read<ImageStorageService>(),
          )..init(),
        ),
        ChangeNotifierProxyProvider2<StorageService, GigaChatService, ReportProvider>(
          create: (ctx) => ReportProvider(
            storage: ctx.read<StorageService>(),
            gigaChatService: ctx.read<GigaChatService>(),
            mockApi: ctx.read<MockReportApiService>(),
            imageStorage: ctx.read<ImageStorageService>(),
          )..init(),
          update: (_, __, ___, prev) => prev!,
        ),
        ChangeNotifierProxyProvider<GigaChatService, GenerationProvider>(
          create: (ctx) => GenerationProvider(service: ctx.read<GigaChatService>()),
          update: (_, __, prev) => prev!,
        ),
      ],
      child: MaterialApp(
        title: 'Структуратор',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isReady) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.brandNavy,
                    AppTheme.brandBlue,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.brandBlue),
              ),
            ),
          );
        }
        if (!auth.isLoggedIn) return const AuthScreen();
        return switch (auth.role!) {
          UserRole.worker => const WorkerDashboard(),
          UserRole.manager => const ManagerDashboard(),
        };
      },
    );
  }
}
