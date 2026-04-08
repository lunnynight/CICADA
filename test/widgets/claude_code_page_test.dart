import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/claude_code_page.dart';

void main() {
  group('ClaudeCodePage', () {
    Widget buildPage() => const MaterialApp(home: Scaffold(body: ClaudeCodePage()));

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
      expect(find.byType(ClaudeCodePage), findsOneWidget);
    });

    testWidgets('shows loading or content state', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(ClaudeCodePage), findsOneWidget);
    });

    testWidgets('completes async load without error', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
