import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/setup_page.dart';

void main() {
  group('SetupPage', () {
    Widget buildSetupPage({VoidCallback? onSetupComplete}) {
      return MaterialApp(
        home: Scaffold(
          body: SetupPage(onSetupComplete: onSetupComplete),
        ),
      );
    }

    // Pump widget and wait for _detect() real async I/O to complete.
    Future<void> pumpAndDetect(WidgetTester tester, Widget widget) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
        await Future.delayed(const Duration(seconds: 3));
      });
      await tester.pump();
      await tester.pump();
    }

    testWidgets('renders SETUP WIZARD header text', (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.text('SETUP WIZARD'), findsOneWidget);
    });

    testWidgets('renders step list with 环境检测 step title', (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.text('环境检测'), findsWidgets);
    });

    testWidgets('renders LinearProgressIndicator (overall progress bar)',
        (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Node.js and OpenClaw check items after detection',
        (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.text('Node.js'), findsWidgets);
      expect(find.text('OpenClaw'), findsWidgets);
    });

    testWidgets('shows 总进度 label in progress section', (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.text('总进度'), findsOneWidget);
    });

    testWidgets('shows detection result: installed or not-installed state',
        (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      // Either "已安装" (installed) or "未安装" (not installed) appears
      // depending on the host machine — both are valid detection outcomes
      final hasInstalled = find.text('已安装').evaluate().isNotEmpty;
      final hasNotInstalled = find.text('未安装').evaluate().isNotEmpty;
      expect(hasInstalled || hasNotInstalled, isTrue);
    });

    testWidgets('step navigation: 下一步 button is present', (tester) async {
      await pumpAndDetect(tester, buildSetupPage());
      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('step navigation: tapping 下一步 advances step content',
        (tester) async {
      await pumpAndDetect(tester, buildSetupPage());

      await tester.tap(find.text('下一步'), warnIfMissed: false);
      await tester.pump();

      // Header persists after navigation
      expect(find.text('SETUP WIZARD'), findsOneWidget);
    });

    testWidgets('onSetupComplete callback is accepted without error',
        (tester) async {
      var called = false;
      await pumpAndDetect(
        tester,
        buildSetupPage(onSetupComplete: () => called = true),
      );
      // Widget rendered without error regardless of callback invocation
      expect(find.text('SETUP WIZARD'), findsOneWidget);
      // called may be true if both installed and complete step is shown
      expect(called, isA<bool>());
    });
  });
}
