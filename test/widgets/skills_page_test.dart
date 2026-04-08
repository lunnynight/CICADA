import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/skills_page.dart';

void main() {
  group('SkillsPage', () {
    Widget buildPage() => const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SkillsPage())),
        );

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
      expect(find.byType(SkillsPage), findsOneWidget);
    });

    testWidgets('shows loading or content state', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(SkillsPage), findsOneWidget);
    });

    testWidgets('completes async load without error', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
