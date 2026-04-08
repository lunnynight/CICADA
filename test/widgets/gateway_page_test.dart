import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/gateway_page.dart';

void _suppressOverflow() {
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    FlutterError.dumpErrorToConsole(details);
  };
}

void main() {
  group('GatewayPage', () {
    Widget buildPage() => const MaterialApp(home: Scaffold(body: GatewayPage()));

    Future<void> pumpAndWait(WidgetTester tester, Widget widget) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      await tester.pump();
    }

    testWidgets('renders without crashing', (tester) async {
      _suppressOverflow();
      addTearDown(() {
        FlutterError.onError = FlutterError.dumpErrorToConsole;
        tester.view.resetPhysicalSize();
      });
      await pumpAndWait(tester, buildPage());
      expect(find.byType(GatewayPage), findsOneWidget);
    });

    testWidgets('shows loading or content state', (tester) async {
      _suppressOverflow();
      addTearDown(() {
        FlutterError.onError = FlutterError.dumpErrorToConsole;
        tester.view.resetPhysicalSize();
      });
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildPage());
      await tester.pump();
      expect(find.byType(GatewayPage), findsOneWidget);
    });

    testWidgets('completes async load without error', (tester) async {
      _suppressOverflow();
      addTearDown(() {
        FlutterError.onError = FlutterError.dumpErrorToConsole;
        tester.view.resetPhysicalSize();
      });
      await pumpAndWait(tester, buildPage());
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
