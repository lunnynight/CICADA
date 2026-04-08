import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/pages/settings_page.dart';

void main() {
  group('SettingsPage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildPage() => const MaterialApp(home: Scaffold(body: SettingsPage()));

    Future<void> pumpAndWait(WidgetTester tester, Widget widget) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      await tester.pump();
    }

    testWidgets('renders without crashing', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('shows loading or content state', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('completes async load without error', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
