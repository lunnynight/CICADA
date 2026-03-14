import 'dart:async';
import 'dart:io';

class InstallerService {
  static String? _openclawPath;

  /// Resolve full path to openclaw binary.
  /// GUI apps on Windows may not inherit npm global PATH.
  static Future<String> _resolveOpenClawPath() async {
    if (_openclawPath != null) return _openclawPath!;
    if (Platform.isWindows) {
      try {
        final result = await Process.run('where', ['openclaw'], runInShell: true);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim().split('\n').first.trim();
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

  static Future<Process> installNodejs({String? mirrorUrl}) async {
    if (Platform.isWindows) {
      return Process.start(
        'winget',
        [
          'install',
          'OpenJS.NodeJS.LTS',
          '--accept-source-agreements',
          '--accept-package-agreements',
        ],
        runInShell: true,
      );
    } else if (Platform.isLinux) {
      return Process.start('bash', ['-c', 'curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs']);
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
    final args = pm == 'pnpm'
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
    final args = pm == 'pnpm'
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
        '-s', '-o', '/dev/null', '-w', '%{http_code}',
        '--connect-timeout', '2',
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

    process.stdout.transform(const SystemEncoding().decoder).listen(
      (data) => onOutput(data),
    );
    process.stderr.transform(const SystemEncoding().decoder).listen(
      (data) => onOutput(data),
    );

    process.exitCode.then((code) {
      completer.complete(code);
    });

    return completer.future;
  }
}
