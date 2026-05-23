import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structurator/config/auth_stubs.dart';
import 'package:structurator/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold-start: shows auth screen with login tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const StructuratorApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Структуратор'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.textContaining(AuthStubs.workerLogin), findsWidgets);
  });
}
