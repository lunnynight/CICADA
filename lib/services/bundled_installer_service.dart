import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/platform/shell_env.dart';

/// Service for handling offline/bundled installation of Node.js and OpenClaw.
/// Extracts bundled assets to the application support directory and manages
/// local installations without requiring internet connectivity.
class BundledInstallerService {
  static String? _nodePath;
  static String? _npmPath;
  static Map<String, dynamic>? _manifest;

  static void _log(String message, {String level = 'info'}) {
    developer.log(
      '[BundledInstaller] $message',
      name: 'cicada.bundled_installer',
      level: level == 'error' ? 1000 : 800,
    );
  }

  /// Get the base directory for bundled installations
  static Future<Directory> _getBundledDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/bundled');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get the Node.js installation directory for current platform
  static Future<Directory> _getNodeDir() async {
    final bundled = await _getBundledDir();
    final dir = Directory('${bundled.path}/nodejs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get the OpenClaw installation directory
  static Future<Directory> _getOpenClawDir() async {
    final bundled = await _getBundledDir();
    final dir = Directory('${bundled.path}/openclaw');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Load the bundled dependencies manifest
  static Future<Map<String, dynamic>?> _loadManifest() async {
    if (_manifest != null) return _manifest;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/bundled/manifest.json',
      );
      _manifest = json.decode(jsonStr) as Map<String, dynamic>;
      return _manifest;
    } catch (e) {
      return null;
    }
  }

  /// Get the current platform identifier
  static String _getCurrentPlatform() {
    if (Platform.isWindows) return 'win-x64';
    if (Platform.isMacOS) {
      // Detect architecture
      try {
        final result = Process.runSync('uname', ['-m']);
        final arch = (result.stdout as String).trim();
        if (arch == 'arm64') return 'darwin-arm64';
      } catch (_) {}
      return 'darwin-x64';
    }
    if (Platform.isLinux) return 'linux-x64';
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Check if bundled dependencies are available in assets
  static Future<bool> isBundledAvailable() async {
    try {
      final manifest = await _loadManifest();
      if (manifest == null) {
        _log('Manifest not found', level: 'warning');
        return false;
      }

      final platform = _getCurrentPlatform();
      final platforms = manifest['platforms'] as List<dynamic>?;
      if (platforms == null) {
        _log('No platforms defined in manifest', level: 'warning');
        return false;
      }

      final platformInfo = platforms.cast<Map<String, dynamic>>().firstWhere(
        (p) => p['name'] == platform,
        orElse: () => {},
      );
      if (platformInfo.isEmpty) {
        _log('Platform $platform not found in manifest', level: 'warning');
        return false;
      }

      // Check if the archive exists in assets
      final archivePath = 'assets/bundled/${platformInfo['archive']}';
      try {
        await rootBundle.load(archivePath);
        _log('Found Node.js archive: $archivePath');
      } catch (e) {
        _log('Node.js archive not found: $archivePath', level: 'warning');
        return false;
      }

      // Check if OpenClaw package exists
      final openclaw = manifest['openclaw'] as Map<String, dynamic>?;
      if (openclaw == null) {
        _log('OpenClaw info not found in manifest', level: 'warning');
        return false;
      }
      try {
        await rootBundle.load('assets/bundled/${openclaw['package']}');
        _log('Found OpenClaw package: ${openclaw['package']}');
      } catch (e) {
        _log(
          'OpenClaw package not found: ${openclaw['package']}',
          level: 'warning',
        );
        return false;
      }

      _log('Bundled dependencies available for $platform');
      return true;
    } catch (e, stack) {
      _log('Error checking bundled availability: $e\n$stack', level: 'error');
      return false;
    }
  }

  /// Get information about bundled versions
  static Future<Map<String, String>?> getBundledVersions() async {
    final manifest = await _loadManifest();
    if (manifest == null) return null;

    final openclaw = manifest['openclaw'] as Map<String, dynamic>?;
    return {
      'node': manifest['nodeVersion'] as String? ?? 'unknown',
      'openclaw': openclaw?['version'] as String? ?? 'unknown',
    };
  }

  /// Extract Node.js from assets to application support directory
  static Stream<ExtractProgress> extractNodeJs() async* {
    yield ExtractProgress(step: '准备解压 Node.js...', percent: 0);
    _log('Starting Node.js extraction');

    final manifest = await _loadManifest();
    if (manifest == null) {
      throw StateError('Manifest not found');
    }

    final platform = _getCurrentPlatform();
    _log('Current platform: $platform');

    final platforms = manifest['platforms'] as List<dynamic>;
    final platformInfo = platforms.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['name'] == platform,
      orElse: () => throw StateError('Platform $platform not supported'),
    );

    final archivePath = 'assets/bundled/${platformInfo['archive']}';
    final nodeDir = await _getNodeDir();
    final archiveName = platformInfo['archive'] as String;

    yield ExtractProgress(step: '读取资源文件...', percent: 10);
    _log('Loading archive from assets: $archivePath');

    // Load archive from assets
    final bytes = await rootBundle.load(archivePath);
    final tempFile = File('${nodeDir.path}/$archiveName');
    _log('Writing ${bytes.lengthInBytes} bytes to temp file');
    await tempFile.writeAsBytes(bytes.buffer.asUint8List());

    yield ExtractProgress(step: '正在解压 Node.js...', percent: 30);
    _log('Extracting archive...');

    // Extract based on archive type
    late ProcessResult result;
    if (archiveName.endsWith('.zip')) {
      // Windows - use PowerShell
      _log('Using PowerShell Expand-Archive for Windows');
      result = await Process.run('powershell', [
        '-Command',
        'Expand-Archive -Path "${tempFile.path}" -DestinationPath "${nodeDir.path}" -Force',
      ], runInShell: true);
    } else if (archiveName.endsWith('.tar.gz')) {
      // macOS - use tar
      _log('Using tar for macOS .tar.gz');
      result = await Process.run('tar', [
        '-xzf',
        tempFile.path,
        '-C',
        nodeDir.path,
      ], runInShell: true);
    } else if (archiveName.endsWith('.tar.xz')) {
      // Linux - use tar with xz
      _log('Using tar for Linux .tar.xz');
      result = await Process.run('tar', [
        '-xJf',
        tempFile.path,
        '-C',
        nodeDir.path,
      ], runInShell: true);
    } else {
      throw StateError('Unknown archive format: $archiveName');
    }

    if (result.exitCode != 0) {
      _log('Extraction failed: ${result.stderr}', level: 'error');
      throw StateError('Failed to extract: ${result.stderr}');
    }
    _log('Extraction successful');

    yield ExtractProgress(step: '清理临时文件...', percent: 80);

    // Clean up archive file
    await tempFile.delete();
    _log('Deleted temp archive file');

    // Move contents from nested directory (e.g., node-v22.14.0-darwin-arm64/* -> .)
    final entries = await nodeDir.list().toList();
    final nestedDir = entries.whereType<Directory>().firstWhere(
      (d) => d.path.contains('node-v'),
      orElse: () => nodeDir,
    );

    if (nestedDir != nodeDir) {
      _log('Moving files from nested directory: ${nestedDir.path}');
      await for (final entity in nestedDir.list()) {
        final name = entity.path.split('/').last.split('\\').last;
        final destPath = '${nodeDir.path}${Platform.pathSeparator}$name';
        await entity.rename(destPath);
      }
      await nestedDir.delete();
      _log('Moved files and deleted nested directory');
    }

    yield ExtractProgress(step: 'Node.js 解压完成', percent: 100);
    _log('Node.js extraction completed');

    // Clear cached paths
    _nodePath = null;
    _npmPath = null;
  }

  /// Extract and install OpenClaw from bundled tgz
  static Stream<ExtractProgress> extractOpenClaw() async* {
    yield ExtractProgress(step: '准备安装 OpenClaw...', percent: 0);
    _log('Starting OpenClaw extraction');

    final manifest = await _loadManifest();
    if (manifest == null) {
      throw StateError('Manifest not found');
    }

    final openclaw = manifest['openclaw'] as Map<String, dynamic>;
    final packageName = openclaw['package'] as String;
    final assetPath = 'assets/bundled/$packageName';
    final openclawDir = await _getOpenClawDir();

    yield ExtractProgress(step: '读取 OpenClaw 资源...', percent: 20);
    _log('Loading OpenClaw package: $packageName');

    // Load tgz from assets
    final bytes = await rootBundle.load(assetPath);
    final tgzFile = File(
      '${openclawDir.path}${Platform.pathSeparator}$packageName',
    );
    _log('Writing ${bytes.lengthInBytes} bytes to temp file');
    await tgzFile.writeAsBytes(bytes.buffer.asUint8List());

    yield ExtractProgress(step: '正在安装 OpenClaw...', percent: 50);

    // Get local npm path
    final npmPath = await getNpmPath();
    _log('Using npm from: $npmPath');

    // Install from local tgz using the bundled npm
    final result = await Process.run(
      npmPath,
      ['install', '-g', tgzFile.path],
      runInShell: true,
      environment: {
        // Ensure npm uses the bundled Node.js
        'PATH':
            '${(await _getNodeDir()).path}${Platform.pathSeparator}bin${Platform.isWindows ? ';' : ':'}${Platform.environment['PATH'] ?? ''}',
      },
    );

    if (result.exitCode != 0) {
      _log('OpenClaw installation failed: ${result.stderr}', level: 'error');
      throw StateError('Failed to install OpenClaw: ${result.stderr}');
    }
    _log('OpenClaw installed successfully');

    yield ExtractProgress(step: '清理安装文件...', percent: 80);

    // Clean up tgz file
    await tgzFile.delete();
    _log('Cleaned up temp tgz file');

    yield ExtractProgress(step: 'OpenClaw 安装完成', percent: 100);
  }

  /// Get the path to the bundled Node.js executable
  static Future<String> getNodePath() async {
    if (_nodePath != null) return _nodePath!;

    final manifest = await _loadManifest();
    if (manifest == null) {
      throw StateError('Manifest not found');
    }

    final platform = _getCurrentPlatform();
    final platforms = manifest['platforms'] as List<dynamic>;
    final platformInfo = platforms.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['name'] == platform,
      orElse: () => throw StateError('Platform $platform not supported'),
    );

    final nodeDir = await _getNodeDir();
    final binPath = platformInfo['binPath'] as String;
    final fullPath = '${nodeDir.path}/$binPath';

    // On Windows, handle both path separators
    _nodePath = Platform.isWindows ? fullPath.replaceAll('/', '\\') : fullPath;
    return _nodePath!;
  }

  /// Get the path to the bundled npm executable
  static Future<String> getNpmPath() async {
    if (_npmPath != null) return _npmPath!;

    final manifest = await _loadManifest();
    if (manifest == null) {
      throw StateError('Manifest not found');
    }

    final platform = _getCurrentPlatform();
    final platforms = manifest['platforms'] as List<dynamic>;
    final platformInfo = platforms.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['name'] == platform,
      orElse: () => throw StateError('Platform $platform not supported'),
    );

    final nodeDir = await _getNodeDir();
    final npmPath = platformInfo['npmPath'] as String;
    final fullPath = '${nodeDir.path}/$npmPath';

    // On Windows, handle both path separators
    _npmPath = Platform.isWindows ? fullPath.replaceAll('/', '\\') : fullPath;
    return _npmPath!;
  }

  /// Check if Node.js is already extracted locally
  static Future<bool> isNodeExtracted() async {
    try {
      final nodePath = await getNodePath();
      final file = File(nodePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Check if OpenClaw is installed locally (via bundled installer)
  static Future<bool> isOpenClawInstalled() async {
    try {
      final env = await ShellEnv.getEnv();
      final result = await Process.run('openclaw', [
        '--version',
      ], runInShell: true, environment: env);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Test the bundled Node.js installation
  static Future<bool> testNodeInstallation() async {
    try {
      final nodePath = await getNodePath();
      final result = await Process.run(nodePath, [
        '--version',
      ], runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}

/// Progress information for extraction operations
class ExtractProgress {
  final String step;
  final int percent;

  const ExtractProgress({required this.step, required this.percent});
}
