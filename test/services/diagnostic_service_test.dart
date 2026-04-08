import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/diagnostic_service.dart';
import '../../lib/models/diagnostic.dart';

DiagnosticReport _makeReport({
  String level = 'ok',
  String title = 'Test Title',
  String summary = 'Test Summary',
  List<DiagnosticFinding> findings = const [],
}) =>
    DiagnosticReport(
      level: level,
      title: title,
      summary: summary,
      findings: findings,
    );

DiagnosticFinding _makeFinding({
  String id = 'test_id',
  String level = 'ok',
  String title = 'Finding Title',
  String summary = 'Finding Summary',
  String? detail,
  List<DiagnosticAction> actions = const [],
}) =>
    DiagnosticFinding(
      id: id,
      level: level,
      title: title,
      summary: summary,
      detail: detail,
      actions: actions,
    );

void main() {
  group('DiagnosticService.exportReport', () {
    test('output contains report header', () {
      final report = _makeReport();
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('# CICADA 诊断报告'));
    });

    test('output contains level in uppercase', () {
      final report = _makeReport(level: 'warn', title: '需要注意');
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('WARN'));
      expect(output, contains('需要注意'));
    });

    test('output contains finding title and summary', () {
      final finding = _makeFinding(title: 'Node.js 已安装', summary: 'v22.3.0');
      final report = _makeReport(findings: [finding]);
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('Node.js 已安装'));
      expect(output, contains('v22.3.0'));
    });

    test('output contains finding detail when present', () {
      final finding = _makeFinding(detail: '详细说明文字');
      final report = _makeReport(findings: [finding]);
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('详细说明文字'));
    });

    test('output contains action labels', () {
      final finding = _makeFinding(
        actions: [const DiagnosticAction(id: 'goto_setup', label: '前往安装向导')],
      );
      final report = _makeReport(findings: [finding]);
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('前往安装向导'));
    });

    test('output omits detail line when detail is null', () {
      final finding = _makeFinding(detail: null);
      final report = _makeReport(findings: [finding]);
      final output = DiagnosticService.exportReport(report);
      expect(output, isNot(contains('- 详情:')));
    });

    test('report with error level shows ERROR', () {
      final report = _makeReport(level: 'error', title: '发现问题');
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('ERROR'));
    });

    test('report with ok level shows OK', () {
      final report = _makeReport(level: 'ok', title: '系统状态良好');
      final output = DiagnosticService.exportReport(report);
      expect(output, contains('OK'));
    });
  });

  group('DiagnosticService.applyFix', () {
    test('retry action returns true', () async {
      final result = await DiagnosticService.applyFix('retry');
      expect(result, isTrue);
    });

    test('unknown action returns false', () async {
      final result = await DiagnosticService.applyFix('unknown_action_xyz');
      expect(result, isFalse);
    });
  });
}
