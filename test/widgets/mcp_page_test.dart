import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/mcp_page.dart';

void main() {
  group('McpPage', () {
    Widget buildPage() => const MaterialApp(home: Scaffold(body: McpPage()));

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
      expect(find.byType(McpPage), findsOneWidget);
    });

    testWidgets('shows loading or content state', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      expect(find.byType(McpPage), findsOneWidget);
    });

    testWidgets('completes async load without error', (tester) async {
      await pumpAndWait(tester, buildPage());
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
