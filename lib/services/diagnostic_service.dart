import 'dart:io';
import '../models/diagnostic.dart';
import 'installer_service.dart';
import 'config_service.dart';

/// Three-layer diagnostic service:
/// 1. Local detection (no LLM required)
/// 2. Preset fixes (curated actions)
/// 3. Report export (copy/share)
class DiagnosticService {
  /// Run full diagnostic suite
  static Future<DiagnosticReport> runDiagnostics() async {
    final findings = <DiagnosticFinding>[];

    // Layer 1: Environment checks
    findings.addAll(await _checkNodeJs());
    findings.addAll(await _checkOpenClaw());
    findings.addAll(await _checkConfig());
    findings.addAll(await _checkNetwork());

    // Calculate overall status
    final level = _calculateOverallLevel(findings);
    final title = _generateTitle(level);
    final summary = _generateSummary(level, findings);

    return DiagnosticReport(
      level: level,
      title: title,
      summary: summary,
      findings: findings,
    );
  }

  /// Check Node.js installation and version
  static Future<List<DiagnosticFinding>> _checkNodeJs() async {
    final findings = <DiagnosticFinding>[];

    try {
      final result = await InstallerService.checkNode();
      if (result.exitCode == 0) {
        final version = (result.stdout as String).trim();
        findings.add(DiagnosticFinding(
          id: 'node_ok',
          level: 'ok',
          title: 'Node.js 已安装',
          summary: '检测到 Node.js $version',
          actions: [],
        ));
      } else {
        findings.add(DiagnosticFinding(
          id: 'node_missing',
          level: 'error',
          title: 'Node.js 未安装',
          summary: 'OpenClaw 需要 Node.js 运行环境',
          detail: '请前往安装向导完成 Node.js 安装',
          actions: [
            const DiagnosticAction(id: 'goto_setup', label: '前往安装向导'),
          ],
        ));
      }
    } catch (e) {
      findings.add(DiagnosticFinding(
        id: 'node_check_failed',
        level: 'warn',
        title: 'Node.js 检测失败',
        summary: '无法检测 Node.js 状态: $e',
        actions: [
          const DiagnosticAction(id: 'retry', label: '重新检测'),
        ],
      ));
    }

    return findings;
  }

  /// Check OpenClaw installation
  static Future<List<DiagnosticFinding>> _checkOpenClaw() async {
    final findings = <DiagnosticFinding>[];

    try {
      final result = await InstallerService.checkOpenClaw();
      if (result.exitCode == 0) {
        final version = (result.stdout as String).trim();
        findings.add(DiagnosticFinding(
          id: 'claw_ok',
          level: 'ok',
          title: 'OpenClaw 已安装',
          summary: '检测到 OpenClaw $version',
          actions: [],
        ));
      } else {
        findings.add(DiagnosticFinding(
          id: 'claw_missing',
          level: 'error',
          title: 'OpenClaw 未安装',
          summary: '请安装 OpenClaw CLI 工具',
          detail: '请前往安装向导完成 OpenClaw 安装',
          actions: [
            const DiagnosticAction(id: 'goto_setup', label: '前往安装向导'),
          ],
        ));
      }
    } catch (e) {
      findings.add(DiagnosticFinding(
        id: 'claw_check_failed',
        level: 'warn',
        title: 'OpenClaw 检测失败',
        summary: '无法检测 OpenClaw 状态: $e',
        actions: [
          const DiagnosticAction(id: 'retry', label: '重新检测'),
        ],
      ));
    }

    // Check if service is running
    try {
      final running = await InstallerService.isServiceRunning();
      if (running) {
        findings.add(DiagnosticFinding(
          id: 'service_ok',
          level: 'ok',
          title: 'OpenClaw 服务运行中',
          summary: 'http://127.0.0.1:18789 可访问',
          actions: [],
        ));
      } else {
        findings.add(DiagnosticFinding(
          id: 'service_stopped',
          level: 'info',
          title: 'OpenClaw 服务已停止',
          summary: '服务未运行，可在仪表盘启动',
          actions: [
            const DiagnosticAction(id: 'goto_dashboard', label: '前往仪表盘'),
          ],
        ));
      }
    } catch (e) {
      findings.add(DiagnosticFinding(
        id: 'service_check_failed',
        level: 'warn',
        title: '服务状态检测失败',
        summary: '无法检测服务状态: $e',
        actions: [
          const DiagnosticAction(id: 'retry', label: '重新检测'),
        ],
      ));
    }

    return findings;
  }

  /// Check configuration file
  static Future<List<DiagnosticFinding>> _checkConfig() async {
    final findings = <DiagnosticFinding>[];

    try {
      final config = await ConfigService.readConfig();
      final providers = config['providers'] as Map<String, dynamic>?;

      if (providers == null || providers.isEmpty) {
        findings.add(DiagnosticFinding(
          id: 'config_no_providers',
          level: 'warn',
          title: '未配置模型提供商',
          summary: '建议至少配置一个 AI 模型提供商',
          detail: '请前往模型配置页面添加至少一个提供商',
          actions: [
            const DiagnosticAction(id: 'goto_models', label: '前往模型配置'),
          ],
        ));
      } else {
        findings.add(DiagnosticFinding(
          id: 'config_ok',
          level: 'ok',
          title: '配置文件正常',
          summary: '已配置 ${providers.length} 个模型提供商',
          actions: [],
        ));
      }

      final configFile = File(ConfigService.configPath);
      if (await configFile.exists()) {
        final stat = await configFile.stat();
        findings.add(DiagnosticFinding(
          id: 'config_file_exists',
          level: 'ok',
          title: '配置文件存在',
          summary: ConfigService.configPath,
          detail: '文件大小: ${stat.size} 字节',
          actions: [],
        ));
      }
    } catch (e) {
      findings.add(DiagnosticFinding(
        id: 'config_check_failed',
        level: 'warn',
        title: '配置检查失败',
        summary: '无法读取配置: $e',
        actions: [
          const DiagnosticAction(id: 'retry', label: '重新检测'),
        ],
      ));
    }

    return findings;
  }

  /// Check network connectivity
  static Future<List<DiagnosticFinding>> _checkNetwork() async {
    final findings = <DiagnosticFinding>[];

    // Check npm registry connectivity
    try {
      final result = await Process.run(
        'curl',
        ['-s', '-o', '/dev/null', '-w', '%{http_code}', '--connect-timeout', '5', 'https://registry.npmmirror.com'],
        runInShell: true,
      );
      final code = (result.stdout as String).trim();
      if (code == '200' || code == '301' || code == '302' || code == '304') {
        findings.add(DiagnosticFinding(
          id: 'network_npm_ok',
          level: 'ok',
          title: 'npm 镜像可访问',
          summary: 'https://registry.npmmirror.com 连接正常',
          actions: [],
        ));
      } else {
        findings.add(DiagnosticFinding(
          id: 'network_npm_warn',
          level: 'warn',
          title: 'npm 镜像可能不可用',
          summary: 'HTTP 状态码: $code',
          actions: [
            const DiagnosticAction(id: 'check_mirror', label: '检查镜像源'),
          ],
        ));
      }
    } catch (e) {
      findings.add(DiagnosticFinding(
        id: 'network_npm_failed',
        level: 'info',
        title: '网络检测跳过',
        summary: 'curl 不可用，跳过网络检测',
        actions: [],
      ));
    }

    return findings;
  }

  /// Calculate overall report level from findings
  static String _calculateOverallLevel(List<DiagnosticFinding> findings) {
    final hasError = findings.any((f) => f.level == 'error');
    final hasWarn = findings.any((f) => f.level == 'warn');

    if (hasError) return 'error';
    if (hasWarn) return 'warn';
    return 'ok';
  }

  /// Generate human-readable title for overall level
  static String _generateTitle(String level) {
    switch (level) {
      case 'ok':
        return '系统状态良好';
      case 'warn':
        return '需要注意';
      case 'error':
        return '发现问题';
      default:
        return '诊断完成';
    }
  }

  /// Generate summary text
  static String _generateSummary(String level, List<DiagnosticFinding> findings) {
    final okCount = findings.where((f) => f.level == 'ok').length;
    final warnCount = findings.where((f) => f.level == 'warn').length;
    final errorCount = findings.where((f) => f.level == 'error').length;

    final parts = <String>[];
    if (okCount > 0) parts.add('$okCount 项正常');
    if (warnCount > 0) parts.add('$warnCount 项警告');
    if (errorCount > 0) parts.add('$errorCount 项错误');

    return parts.join('，');
  }

  /// Apply a fix action
  static Future<bool> applyFix(String actionId) async {
    switch (actionId) {
      case 'retry':
        // Will be handled by UI re-running diagnostics
        return true;
      default:
        return false;
    }
  }

  /// Export report as text
  static String exportReport(DiagnosticReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# CICADA 诊断报告');
    buffer.writeln('生成时间: ${DateTime.now().toLocal().toString()}');
    buffer.writeln('');
    buffer.writeln('## 总体状态');
    buffer.writeln('- 级别: ${report.level.toUpperCase()}');
    buffer.writeln('- 标题: ${report.title}');
    buffer.writeln('- 摘要: ${report.summary}');
    buffer.writeln('');
    buffer.writeln('## 详细发现');

    for (final finding in report.findings) {
      buffer.writeln('### ${_levelToEmoji(finding.level)} ${finding.title}');
      buffer.writeln('- ID: ${finding.id}');
      buffer.writeln('- 摘要: ${finding.summary}');
      if (finding.detail != null) {
        buffer.writeln('- 详情: ${finding.detail}');
      }
      if (finding.actions.isNotEmpty) {
        buffer.writeln('- 建议操作:');
        for (final action in finding.actions) {
          buffer.writeln('  - [${action.id}] ${action.label}');
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static String _levelToEmoji(String level) {
    switch (level) {
      case 'ok':
        return '✅';
      case 'info':
        return 'ℹ️';
      case 'warn':
        return '⚠️';
      case 'error':
        return '❌';
      default:
        return '📝';
    }
  }
}
