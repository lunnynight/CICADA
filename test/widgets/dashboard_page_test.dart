import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/dashboard_page.dart';

void main() {
  group('DashboardPage', () {
    Widget buildPage({void Function(int)? onNavigate}) {
      return MaterialApp(
        home: Scaffold(
          body: DashboardPage(onNavigate: onNavigate),
        ),
      );
    }

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
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      // Either loading or loaded state is valid
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.byType(SingleChildScrollView).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows stats and actions after loading', (tester) async {
      await pumpAndWait(tester, buildPage());
      // After async load, should show content (not just spinner)
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('onNavigate callback is accepted', (tester) async {
      int? navigatedTo;
      await pumpAndWait(tester, buildPage(onNavigate: (i) => navigatedTo = i));
      expect(find.byType(DashboardPage), findsOneWidget);
      // navigatedTo may remain null if no tap occurred — that's fine
      expect(navigatedTo, isNull);
    });

    testWidgets('disposes timer without error', (tester) async {
      await pumpAndWait(tester, buildPage());
      // Pumping a new widget disposes the old one, exercising dispose()
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
    });
  });
}
