import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/diagnostic_page.dart';
import '../../lib/pages/home_page.dart' show NavIndex;
import '../../lib/models/diagnostic.dart';

/// Fake report with one finding per navigation action, guaranteeing all
/// three buttons appear regardless of the real environment state.
DiagnosticReport _fakeReport() {
  return const DiagnosticReport(
    level: 'warn',
    title: '测试诊断报告',
    summary: '包含三个导航动作的测试报告',
    findings: [
      DiagnosticFinding(
        id: 'test_setup',
        level: 'warn',
        title: '测试：前往安装向导',
        summary: '触发 goto_setup',
        actions: [DiagnosticAction(id: 'goto_setup', label: '前往安装向导')],
      ),
      DiagnosticFinding(
        id: 'test_models',
        level: 'warn',
        title: '测试：前往模型配置',
        summary: '触发 goto_models',
        actions: [DiagnosticAction(id: 'goto_models', label: '前往模型配置')],
      ),
      DiagnosticFinding(
        id: 'test_dashboard',
        level: 'info',
        title: '测试：前往仪表盘',
        summary: '触发 goto_dashboard',
        actions: [DiagnosticAction(id: 'goto_dashboard', label: '前往仪表盘')],
      ),
    ],
  );
}

void main() {
  group('DiagnosticPage navigation callbacks', () {
    testWidgets('goto_setup triggers onNavigate with NavIndex.setup', (tester) async {
      int? capturedIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiagnosticPage(
              onNavigate: (i) => capturedIndex = i,
              diagnosticsOverride: _fakeReport(),
            ),
          ),
        ),
      );
      await tester.pump(); // let initState + setState complete

      final setupBtn = find.text('前往安装向导');
      expect(setupBtn, findsOneWidget);

      await tester.ensureVisible(setupBtn);
      await tester.tap(setupBtn);
      await tester.pump();

      expect(capturedIndex, equals(NavIndex.setup));
    });

    testWidgets('goto_models triggers onNavigate with NavIndex.models', (tester) async {
      int? capturedIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiagnosticPage(
              onNavigate: (i) => capturedIndex = i,
              diagnosticsOverride: _fakeReport(),
            ),
          ),
        ),
      );
      await tester.pump();

      final modelsBtn = find.text('前往模型配置');
      expect(modelsBtn, findsOneWidget);

      await tester.ensureVisible(modelsBtn);
      await tester.tap(modelsBtn);
      await tester.pump();

      expect(capturedIndex, equals(NavIndex.models));
    });

    testWidgets('goto_dashboard triggers onNavigate with NavIndex.dashboard',
        (tester) async {
      int? capturedIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DiagnosticPage(
              onNavigate: (i) => capturedIndex = i,
              diagnosticsOverride: _fakeReport(),
            ),
          ),
        ),
      );
      await tester.pump();

      final dashBtn = find.text('前往仪表盘');
      expect(dashBtn, findsOneWidget);

      await tester.ensureVisible(dashBtn);
      await tester.tap(dashBtn);
      await tester.pump();

      expect(capturedIndex, equals(NavIndex.dashboard));
    });
  });
}
