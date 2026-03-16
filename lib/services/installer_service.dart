import 'dart:async';
import 'dart:io';
import 'bundled_installer_service.dart' show BundledInstallerService;

/// Progress information for installation operations
class InstallProgress {
  final String step;
  final int percent;

  const InstallProgress({required this.step, required this.percent});
}

class InstallerService {
  static String? _openclawPath;

  /// Resolve full path to openclaw binary.
  /// GUI apps on Windows may not inherit npm global PATH.
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
    }
    return 'openclaw';
  }

  static Future<ProcessResult> checkNode() async {
    try {
      return await Process.run('node', ['--version'], runInShell: true);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  static Future<ProcessResult> checkOpenClaw() async {
    try {
      final bin = await _resolveOpenClawPath();
      return await Process.run(bin, ['--version'], runInShell: true);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  static Future<ProcessResult> checkOllama() async {
    try {
      return await Process.run('ollama', ['--version'], runInShell: true);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  /// Check if OpenClaw is installed (binary exists)
  static Future<bool> isOpenClawInstalled() async {
    final result = await checkOpenClaw();
    return result.exitCode == 0;
  }

  /// Check if OpenClaw Gateway is running (port 1933)
  static Future<bool> isGatewayRunning() async {
    try {
      final socket = await Socket.connect('127.0.0.1', 1933, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get OpenClaw status
  static Future<OpenClawStatus> getOpenClawStatus() async {
    final installed = await isOpenClawInstalled();
    if (!installed) return OpenClawStatus.notInstalled;

    final running = await isGatewayRunning();
    return running ? OpenClawStatus.running : OpenClawStatus.installed;
  }

  static Future<Process> installNodejs({String? mirrorUrl}) async {
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
      ]);
    } else if (Platform.isMacOS) {
      return Process.start('bash', ['-c', 'brew install node@22']);
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Detect available package manager: pnpm > npm
  static Future<String> _detectPkgManager() async {
    try {
      final result = await Process.run('pnpm', ['--version'], runInShell: true);
      if (result.exitCode == 0) return 'pnpm';
    } catch (_) {}
    return 'npm';
  }

  static Future<Process> installOpenClaw({String? mirrorUrl}) async {
    final pm = await _detectPkgManager();
    final args =
        pm == 'pnpm'
            ? ['add', '-g', 'openclaw']
            : ['install', '-g', 'openclaw'];
    if (mirrorUrl != null) {
      args.addAll(['--registry', mirrorUrl]);
    }
    return Process.start(pm, args, runInShell: true);
  }

  /// Uninstall OpenClaw via package manager
  static Future<Process> uninstallOpenClaw() async {
    final pm = await _detectPkgManager();
    final args =
        pm == 'pnpm'
            ? ['remove', '-g', 'openclaw']
            : ['uninstall', '-g', 'openclaw'];
    return Process.start(pm, args, runInShell: true);
  }

  static Future<ProcessResult> startService() async {
    final bin = await _resolveOpenClawPath();
    return Process.run(bin, ['start'], runInShell: true);
  }

  static Future<ProcessResult> stopService() async {
    final bin = await _resolveOpenClawPath();
    return Process.run(bin, ['stop'], runInShell: true);
  }

  /// Check if OpenClaw service is running by probing its HTTP port
  static Future<bool> isServiceRunning({int port = 18789}) async {
    try {
      final result = await Process.run('curl', [
        '-s',
        '-o',
        '/dev/null',
        '-w',
        '%{http_code}',
        '--connect-timeout',
        '2',
        'http://127.0.0.1:$port/',
      ]);
      final code = (result.stdout as String).trim();
      return code == '200' || code == '302' || code == '301';
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

/// Utility to merge multiple streams
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();
    int pending = streams.length;

    for (final stream in streams) {
      stream.listen(
        (data) => controller.add(data),
        onError: (e) => controller.addError(e),
        onDone: () {
          pending--;
          if (pending == 0) controller.close();
        },
      );
    }

    return controller.stream;
  }
}

/// OpenClaw installation and runtime status
enum OpenClawStatus {
  notInstalled,
  installed,
  running,
}
