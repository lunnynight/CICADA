import 'dart:io';

class InstallerService {
  static Future<ProcessResult> checkNode() async {
    try {
      return await Process.run('node', ['--version']);
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
      return await Process.run('ollama', ['--version']);
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
      );
    }
    throw UnsupportedError('Unsupported platform');
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
}
