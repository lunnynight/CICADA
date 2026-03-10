import 'dart:async';
import 'dart:io';

class InstallerService {
  static Future<ProcessResult> checkNode() async {
    try {
      return await Process.run('node', ['--version'], runInShell: true);
    } catch (e) {
      return ProcessResult(0, 1, '', e.toString());
    }
  }

  static Future<ProcessResult> checkOpenClaw() async {
    try {
      return await Process.run('openclaw', ['--version'], runInShell: true);
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

  static Future<Process> installOpenClaw({String? mirrorUrl}) async {
    final args = ['install', '-g', 'openclaw'];
    if (mirrorUrl != null) {
      args.addAll(['--registry', mirrorUrl]);
    }
    return Process.start('npm', args, runInShell: true);
  }

  static Future<ProcessResult> startService() async {
    return Process.run('openclaw', ['start'], runInShell: true);
  }

  static Future<ProcessResult> stopService() async {
    return Process.run('openclaw', ['stop'], runInShell: true);
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
