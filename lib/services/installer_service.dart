import 'dart:async';
import 'dart:io';
import 'package:async/async.dart' show StreamGroup;
import 'package:http/http.dart' as http;
import '../core/platform/platform_info.dart';
import '../core/platform/shell_env.dart';
import 'bundled_installer_service.dart' show BundledInstallerService;
import 'termux_bridge.dart';

/// Progress information for installation operations
class InstallProgress {
  final String step;
  final int percent;

  const InstallProgress({required this.step, required this.percent});
}

class InstallerService {
  static String? _openclawPath;
  static String? _claudeCodePath;

  /// Resolve full path to openclaw binary.
  /// GUI apps on Windows/macOS may not inherit npm global PATH.
  static Future<String> _resolveOpenClawPath() async {
    if (_openclawPath != null) return _openclawPath!;
    if (Platform.isWindows) {
      try {
        final result = await Process.run('where', [
          'openclaw',
        ], runInShell: true);
        if (result.exitCode == 0) {
          final path =
              (result.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty) {
            _openclawPath = path;
            return path;
          }
        }
      } catch (_) {}
      final home = Platform.environment['USERPROFILE'] ?? '';
      final candidates = [
        '$home\\AppData\\Roaming\\npm\\openclaw.cmd',
        '$home\\AppData\\Local\\pnpm\\openclaw.cmd',
      ];
      for (final c in candidates) {
        if (await File(c).exists()) {
          _openclawPath = c;
          return c;
        }
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      try {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('which', ['openclaw'],
            runInShell: true, environment: env);
        if (result.exitCode == 0) {
          final path =
              (result.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty) {
            _openclawPath = path;
            return path;
          }
        }
      } catch (_) {}
    }
    return 'openclaw';
  }

  static Future<ProcessResult> checkNode() async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.runCommand('node', args: ['--version']);
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    try {
      final env = await ShellEnv.getEnv();
      return await Process.run('node', ['--version'],
          runInShell: true, environment: env);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  /// Parse major version from Node.js version string like "v22.3.0" → 22.
  /// Returns null if parsing fails.
  static int? parseNodeMajorVersion(String versionStr) {
    final cleaned = versionStr.trim();
    final match = RegExp(r'^v?(\d+)').firstMatch(cleaned);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Check if Node.js is installed AND version >= [minMajor].
  static Future<({bool installed, bool sufficient, int? major, String raw})>
      isNodeVersionSufficient({int minMajor = 22}) async {
    final result = await checkNode();
    if (result.exitCode != 0) {
      return (installed: false, sufficient: false, major: null, raw: '');
    }
    final raw = (result.stdout as String).trim();
    final major = parseNodeMajorVersion(raw);
    return (
      installed: true,
      sufficient: major != null && major >= minMajor,
      major: major,
      raw: raw,
    );
  }

  static Future<ProcessResult> checkOpenClaw() async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.runCommand('openclaw', args: ['--version']);
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    try {
      final bin = await _resolveOpenClawPath();
      final env = await ShellEnv.getEnv();
      return await Process.run(bin, ['--version'],
          runInShell: true, environment: env);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  static Future<ProcessResult> checkOllama() async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.runCommand('ollama', args: ['--version']);
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    try {
      final env = await ShellEnv.getEnv();
      return await Process.run('ollama', ['--version'],
          runInShell: true, environment: env);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  /// Check if OpenClaw is installed (binary exists)
  static Future<bool> isOpenClawInstalled() async {
    final result = await checkOpenClaw();
    return result.exitCode == 0;
  }

  // ==================== Claude Code ====================

  /// Resolve full path to claude binary (same pattern as OpenClaw).
  static Future<String> _resolveClaudeCodePath() async {
    if (_claudeCodePath != null) return _claudeCodePath!;
    if (Platform.isWindows) {
      try {
        final result = await Process.run('where', ['claude'], runInShell: true);
        if (result.exitCode == 0) {
          final path =
              (result.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty) {
            _claudeCodePath = path;
            return path;
          }
        }
      } catch (_) {}
      final home = Platform.environment['USERPROFILE'] ?? '';
      final candidates = [
        '$home\\AppData\\Roaming\\npm\\claude.cmd',
        '$home\\AppData\\Local\\pnpm\\claude.cmd',
      ];
      for (final c in candidates) {
        if (await File(c).exists()) {
          _claudeCodePath = c;
          return c;
        }
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      try {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('which', ['claude'],
            runInShell: true, environment: env);
        if (result.exitCode == 0) {
          final path =
              (result.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty) {
            _claudeCodePath = path;
            return path;
          }
        }
      } catch (_) {}
    }
    return 'claude';
  }

  static Future<ProcessResult> checkClaudeCode() async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.runCommand('claude', args: ['--version']);
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    try {
      final bin = await _resolveClaudeCodePath();
      final env = await ShellEnv.getEnv();
      return await Process.run(bin, ['--version'],
          runInShell: true, environment: env);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  static Future<bool> isClaudeCodeInstalled() async {
    final result = await checkClaudeCode();
    return result.exitCode == 0;
  }

  /// Install Claude Code — prefer official install script, npm as fallback.
  static Future<Process> installClaudeCode({String? mirrorUrl}) async {
    final env = await ShellEnv.getEnv();
    if (mirrorUrl != null) {
      // Mirror specified → use npm/pnpm directly
      return _installClaudeCodeViaNpm(mirrorUrl: mirrorUrl);
    }
    // Official script for macOS/Linux; npm fallback for Windows
    if (Platform.isMacOS || Platform.isLinux) {
      return Process.start(
        'bash',
        ['-c', 'curl -fsSL https://claude.ai/install.sh | bash'],
        runInShell: true,
        environment: env,
      );
    } else if (Platform.isWindows) {
      return Process.start(
        'powershell',
        ['-Command', 'irm https://claude.ai/install.ps1 | iex'],
        runInShell: true,
      );
    }
    // Fallback
    return _installClaudeCodeViaNpm();
  }

  /// npm/pnpm fallback for Claude Code installation.
  static Future<Process> _installClaudeCodeViaNpm({String? mirrorUrl}) async {
    final env = await ShellEnv.getEnv();
    final pm = await _detectPkgManager();
    final args = pm == 'pnpm'
        ? ['add', '-g', '@anthropic-ai/claude-code']
        : ['install', '-g', '@anthropic-ai/claude-code'];
    if (mirrorUrl != null) {
      args.addAll(['--registry', mirrorUrl]);
    }
    return Process.start(pm, args, runInShell: true, environment: env);
  }

  static Future<Process> uninstallClaudeCode() async {
    final env = await ShellEnv.getEnv();
    final pm = await _detectPkgManager();
    final args = pm == 'pnpm'
        ? ['remove', '-g', '@anthropic-ai/claude-code']
        : ['uninstall', '-g', '@anthropic-ai/claude-code'];
    return Process.start(pm, args, runInShell: true, environment: env);
  }

  // ==================== VS Code ====================

  /// Check if VS Code CLI (`code`) is available.
  static Future<bool> checkVSCode() async {
    if (Platform.isAndroid) return false;
    try {
      // Try common macOS VS Code binary locations first.
      if (Platform.isMacOS) {
        final candidates = [
          '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
          '/Applications/VS Code.app/Contents/Resources/app/bin/code',
        ];
        for (final path in candidates) {
          if (await File(path).exists()) {
            return true;
          }
        }
      }
      // Fall back to PATH lookup.
      final env = await ShellEnv.getEnv();
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, ['code'],
          runInShell: true, environment: env);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if Claude Code extension is installed in VS Code.
  static Future<bool> isClaudeCodeExtensionInstalled() async {
    if (Platform.isAndroid) return false;
    try {
      final env = await ShellEnv.getEnv();
      final result = await Process.run(
        'code',
        ['--list-extensions'],
        runInShell: true,
        environment: env,
      );
      if (result.exitCode != 0) return false;
      final output = (result.stdout as String).toLowerCase();
      return output.contains('anthropic.claude-code');
    } catch (_) {
      return false;
    }
  }

  /// Install Claude Code extension in VS Code.
  static Future<Process> installClaudeCodeExtension() async {
    if (Platform.isAndroid) {
      throw UnsupportedError('VS Code is not available on Android');
    }
    final env = await ShellEnv.getEnv();
    // Resolve code binary: try common macOS paths first.
    String codeCmd = 'code';
    if (Platform.isMacOS) {
      final candidates = [
        '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
        '/Applications/VS Code.app/Contents/Resources/app/bin/code',
      ];
      for (final path in candidates) {
        if (await File(path).exists()) {
          codeCmd = path;
          break;
        }
      }
    }
    return Process.start(
      codeCmd,
      ['--install-extension', 'anthropic.claude-code'],
      runInShell: true,
      environment: env,
    );
  }

  static Future<Process> updateClaudeCode({String? mirrorUrl}) async {
    // npm update -g doesn't work reliably; reinstall is the standard approach
    return installClaudeCode(mirrorUrl: mirrorUrl);
  }

  /// Check if OpenClaw Gateway is running (port 18789)
  static Future<bool> isGatewayRunning() async {
    // On all platforms, just try HTTP health check first
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:18789/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {}
    // Fallback: TCP probe (desktop only)
    if (PlatformInfo.isDesktop) {
      try {
        final socket = await Socket.connect('127.0.0.1', 18789,
            timeout: const Duration(seconds: 2));
        await socket.close();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Get OpenClaw status
  static Future<OpenClawStatus> getOpenClawStatus() async {
    final installed = await isOpenClawInstalled();
    if (!installed) return OpenClawStatus.notInstalled;

    final running = await isGatewayRunning();
    return running ? OpenClawStatus.running : OpenClawStatus.installed;
  }

  static Future<Process> installNodejs({String? mirrorUrl}) async {
    if (Platform.isAndroid) {
      throw UnsupportedError('Use TermuxBridge.installNode() on Android');
    }
    final env = await ShellEnv.getEnv();
    if (Platform.isWindows) {
      return Process.start('winget', [
        'install',
        'OpenJS.NodeJS.LTS',
        '--accept-source-agreements',
        '--accept-package-agreements',
      ], runInShell: true);
    } else if (Platform.isLinux) {
      return Process.start('bash', [
        '-c',
        'curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs',
      ], environment: env);
    } else if (Platform.isMacOS) {
      return Process.start('bash', ['-c', 'brew install node@22'],
          environment: env);
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Detect available package manager: pnpm > npm
  static Future<String> _detectPkgManager() async {
    try {
      final env = await ShellEnv.getEnv();
      final result = await Process.run('pnpm', ['--version'],
          runInShell: true, environment: env);
      if (result.exitCode == 0) return 'pnpm';
    } catch (_) {}
    return 'npm';
  }

  static Future<Process> installOpenClaw({String? mirrorUrl}) async {
    final env = await ShellEnv.getEnv();
    final pm = await _detectPkgManager();
    final args =
        pm == 'pnpm'
            ? ['add', '-g', 'openclaw']
            : ['install', '-g', 'openclaw'];
    if (mirrorUrl != null) {
      args.addAll(['--registry', mirrorUrl]);
    }
    return Process.start(pm, args, runInShell: true, environment: env);
  }

  /// Uninstall OpenClaw via package manager
  static Future<Process> uninstallOpenClaw() async {
    final env = await ShellEnv.getEnv();
    final pm = await _detectPkgManager();
    final args =
        pm == 'pnpm'
            ? ['remove', '-g', 'openclaw']
            : ['uninstall', '-g', 'openclaw'];
    return Process.start(pm, args, runInShell: true, environment: env);
  }

  static Future<ProcessResult> startService({
    Map<String, String>? extraEnv,
  }) async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.startGateway();
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    final bin = await _resolveOpenClawPath();
    final shellEnv = await ShellEnv.getEnv();
    final env = <String, String>{
      ...?shellEnv,
      if (extraEnv != null) ...extraEnv,
    };
    return Process.run(bin, ['start'],
        runInShell: true, environment: env.isNotEmpty ? env : null);
  }

  static Future<ProcessResult> stopService() async {
    if (PlatformInfo.needsTermux) {
      final r = await TermuxBridge.stopGateway();
      return ProcessResult(0, r.exitCode, r.stdout, r.stderr);
    }
    final bin = await _resolveOpenClawPath();
    final env = await ShellEnv.getEnv();
    return Process.run(bin, ['stop'], runInShell: true, environment: env);
  }

  /// Check if OpenClaw service is running by probing its HTTP port
  static Future<bool> isServiceRunning({int port = 18789}) async {
    // Use http package on all platforms (works on Android too)
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:$port/'))
          .timeout(const Duration(seconds: 2));
      final code = response.statusCode;
      return code == 200 || code == 302 || code == 301;
    } catch (_) {
      return false;
    }
  }

  /// Stream install output via callback
  static Future<int> runInstallWithCallback(
    Future<Process> Function() starter,
    void Function(String line) onOutput,
  ) async {
    final process = await starter();
    final completer = Completer<int>();

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((data) => onOutput(data));
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((data) => onOutput(data));

    process.exitCode.then((code) {
      completer.complete(code);
    });

    return completer.future;
  }

  // ==================== Bundled/Offline Installation ====================

  /// Check if bundled dependencies are available for offline installation
  static Future<bool> isBundledAvailable() async {
    return BundledInstallerService.isBundledAvailable();
  }

  /// Get bundled versions info
  static Future<Map<String, String>?> getBundledVersions() async {
    return BundledInstallerService.getBundledVersions();
  }

  /// Install Node.js from bundled assets (offline)
  /// Returns a stream of progress updates
  static Stream<InstallProgress> installBundledNodeJs() async* {
    yield InstallProgress(step: '检查离线资源...', percent: 0);

    // Check if already extracted
    if (await BundledInstallerService.isNodeExtracted()) {
      yield InstallProgress(step: 'Node.js 已解压，验证中...', percent: 50);
      if (await BundledInstallerService.testNodeInstallation()) {
        yield InstallProgress(step: 'Node.js 已可用', percent: 100);
        return;
      }
    }

    // Extract from bundled assets
    await for (final progress in BundledInstallerService.extractNodeJs()) {
      yield InstallProgress(step: progress.step, percent: progress.percent);
    }

    // Verify installation
    if (!await BundledInstallerService.testNodeInstallation()) {
      throw StateError('Node.js installation verification failed');
    }
  }

  /// Install OpenClaw from bundled assets (offline)
  /// Returns a stream of progress updates
  static Stream<InstallProgress> installBundledOpenClaw() async* {
    yield InstallProgress(step: '准备离线安装...', percent: 0);

    // Ensure Node.js is available first
    if (!await BundledInstallerService.isNodeExtracted()) {
      yield InstallProgress(step: '需要先解压 Node.js...', percent: 10);
      await for (final progress in BundledInstallerService.extractNodeJs()) {
        yield InstallProgress(
          step: progress.step,
          percent: progress.percent ~/ 2,
        );
      }
    }

    // Check if already installed
    if (await BundledInstallerService.isOpenClawInstalled()) {
      yield InstallProgress(step: 'OpenClaw 已安装', percent: 100);
      return;
    }

    // Extract and install from bundled tgz
    await for (final progress in BundledInstallerService.extractOpenClaw()) {
      yield InstallProgress(
        step: progress.step,
        percent: 50 + progress.percent ~/ 2,
      );
    }

    // Verify installation
    final checkResult = await checkOpenClaw();
    if (checkResult.exitCode != 0) {
      throw StateError('OpenClaw installation verification failed');
    }
  }

  /// Try bundled installation first, fallback to online installation
  /// Returns a stream of progress updates
  static Stream<InstallProgress> tryBundledInstallNodeJs() async* {
    if (await isBundledAvailable()) {
      try {
        yield InstallProgress(step: '使用离线安装...', percent: 0);
        await for (final progress in installBundledNodeJs()) {
          yield progress;
        }
        return;
      } catch (e) {
        yield InstallProgress(step: '离线安装失败，回退到在线安装: $e', percent: 0);
      }
    }

    // Fallback to online installation
    yield InstallProgress(step: '开始在线安装...', percent: 0);

    final process = await installNodejs();
    final stdoutController = StreamController<String>();
    final stderrController = StreamController<String>();

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => stdoutController.add(data),
          onDone: () => stdoutController.close(),
        );
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => stderrController.add(data),
          onDone: () => stderrController.close(),
        );

    // Merge stdout and stderr streams
    await for (final line in StreamGroup.merge([
      stdoutController.stream,
      stderrController.stream,
    ])) {
      yield InstallProgress(step: line.trim(), percent: 50);
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('Online installation failed with exit code $exitCode');
    }
    yield InstallProgress(step: '在线安装完成', percent: 100);
  }

  /// Try bundled installation first, fallback to online installation
  /// Returns a stream of progress updates
  static Stream<InstallProgress> tryBundledInstallOpenClaw({
    String? mirrorUrl,
  }) async* {
    if (await isBundledAvailable()) {
      try {
        yield InstallProgress(step: '使用离线安装...', percent: 0);
        await for (final progress in installBundledOpenClaw()) {
          yield progress;
        }
        return;
      } catch (e) {
        yield InstallProgress(step: '离线安装失败，回退到在线安装: $e', percent: 0);
      }
    }

    // Fallback to online installation
    yield InstallProgress(step: '开始在线安装...', percent: 0);

    final process = await installOpenClaw(mirrorUrl: mirrorUrl);
    final stdoutController = StreamController<String>();
    final stderrController = StreamController<String>();

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => stdoutController.add(data),
          onDone: () => stdoutController.close(),
        );
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => stderrController.add(data),
          onDone: () => stderrController.close(),
        );

    // Merge stdout and stderr streams
    await for (final line in StreamGroup.merge([
      stdoutController.stream,
      stderrController.stream,
    ])) {
      yield InstallProgress(step: line.trim(), percent: 50);
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('Online installation failed with exit code $exitCode');
    }
    yield InstallProgress(step: '在线安装完成', percent: 100);
  }
}

/// OpenClaw installation and runtime status
enum OpenClawStatus {
  notInstalled,
  installed,
  running,
}
