import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/diagnostic.dart';

void main() {
  group('DiagnosticReport', () {
    test('constructor sets all fields', () {
      const report = DiagnosticReport(
        level: 'ok',
        title: '系统正常',
        summary: '所有检查通过',
        findings: [],
      );
      expect(report.level, 'ok');
      expect(report.title, '系统正常');
      expect(report.summary, '所有检查通过');
      expect(report.findings, isEmpty);
    });

    test('constructor with findings', () {
      const finding = DiagnosticFinding(
        id: 'node-check',
        level: 'ok',
        title: 'Node.js',
        summary: 'v22.0.0 已安装',
      );
      const report = DiagnosticReport(
        level: 'ok',
        title: '诊断报告',
        summary: '1 项检查',
        findings: [finding],
      );
      expect(report.findings.length, 1);
      expect(report.findings.first.id, 'node-check');
    });
  });

  group('DiagnosticFinding', () {
    test('constructor sets required fields', () {
      const finding = DiagnosticFinding(
        id: 'proxy-check',
        level: 'warn',
        title: '代理配置',
        summary: '代理未配置',
      );
      expect(finding.id, 'proxy-check');
      expect(finding.level, 'warn');
      expect(finding.title, '代理配置');
      expect(finding.summary, '代理未配置');
      expect(finding.detail, isNull);
      expect(finding.actions, isEmpty);
    });

    test('constructor with optional detail and actions', () {
      const action = DiagnosticAction(id: 'configure', label: '配置代理');
      const finding = DiagnosticFinding(
        id: 'proxy-check',
        level: 'warn',
        title: '代理配置',
        summary: '代理未配置',
        detail: '详细说明',
        actions: [action],
      );
      expect(finding.detail, '详细说明');
      expect(finding.actions.length, 1);
      expect(finding.actions.first.id, 'configure');
    });
  });

  group('DiagnosticAction', () {
    test('constructor sets id and label', () {
      const action = DiagnosticAction(id: 'fix', label: '修复');
      expect(action.id, 'fix');
      expect(action.label, '修复');
    });
  });

  group('TokenRecord', () {
    test('constructor sets all fields', () {
      final ts = DateTime(2026, 4, 8, 12, 0, 0);
      final record = TokenRecord(
        timestamp: ts,
        model: 'claude-3-5-sonnet',
        inputTokens: 100,
        outputTokens: 200,
        cacheTokens: 50,
      );
      expect(record.timestamp, ts);
      expect(record.model, 'claude-3-5-sonnet');
      expect(record.inputTokens, 100);
      expect(record.outputTokens, 200);
      expect(record.cacheTokens, 50);
    });

    test('totalTokens sums all token fields', () {
      final record = TokenRecord(
        timestamp: DateTime.now(),
        model: 'gpt-4',
        inputTokens: 100,
        outputTokens: 200,
        cacheTokens: 50,
      );
      expect(record.totalTokens, 350);
    });

    test('cacheTokens defaults to 0', () {
      final record = TokenRecord(
        timestamp: DateTime.now(),
        model: 'gpt-4',
        inputTokens: 10,
        outputTokens: 20,
      );
      expect(record.cacheTokens, 0);
      expect(record.totalTokens, 30);
    });
  });
}
