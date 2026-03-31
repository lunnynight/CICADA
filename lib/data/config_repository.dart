import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/app_error.dart';
import '../core/platform/platform_info.dart';
import '../core/result.dart';

/// Data layer for OpenClaw configuration file I/O.
///
/// Encapsulates all file system operations:
/// - Atomic write (temp file → rename)
/// - File permissions (chmod 600 on Unix)
/// - JSON parse/serialize
class ConfigRepository {
  static String? _cachedConfigDir;

  static String get _homePath =>
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';

  /// On desktop: ~/.openclaw
  /// On Android: app documents dir (via path_provider)
  static Future<String> getConfigDir() async {
    if (_cachedConfigDir != null) return _cachedConfigDir!;
    if (PlatformInfo.isMobile) {
      final dir = await getApplicationDocumentsDirectory();
      _cachedConfigDir = '${dir.path}/.openclaw';
    } else {
      _cachedConfigDir = '$_homePath/.openclaw';
    }
    return _cachedConfigDir!;
  }

  static Future<String> getConfigPath() async {
    final dir = await getConfigDir();
    return '$dir/openclaw.json';
  }

  // Sync accessors for backward compatibility (desktop only)
  static String get configDir => '$_homePath/.openclaw';
  static String get configPath => '$configDir/openclaw.json';

  /// Read and parse the config file.
  Future<Result<Map<String, dynamic>>> readConfig() async {
    final path = await getConfigPath();
    final file = File(path);
    if (!await file.exists()) {
      return const Success(<String, dynamic>{});
    }
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return const Success(<String, dynamic>{});
      final data = json.decode(content) as Map<String, dynamic>;
      return Success(data);
    } on FormatException catch (e) {
      return Failure(ConfigError.parseFailed(cause: e));
    } catch (e) {
      return Failure(ConfigError.readFailed(cause: e));
    }
  }

  /// Write config with atomic write + file permissions.
  Future<Result<void>> writeConfig(Map<String, dynamic> config) async {
    try {
      final dirPath = await getConfigDir();
      final path = await getConfigPath();
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final encoder = const JsonEncoder.withIndent('  ');
      final content = encoder.convert(config);

      final tmpFile = File('$path.tmp.${DateTime.now().millisecondsSinceEpoch}');
      await tmpFile.writeAsString(content);
      await tmpFile.rename(path);
      await _setFilePermissions(path);

      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Read a specific key from config.
  Future<Result<dynamic>> readKey(String key) async {
    final result = await readConfig();
    return result.map((data) => data[key]);
  }

  /// Update a specific key in config (read-modify-write).
  Future<Result<void>> updateKey(String key, dynamic value) async {
    final readResult = await readConfig();
    if (readResult.isFailure) return Failure(readResult.errorOrNull!);

    final config = Map<String, dynamic>.from(readResult.dataOrNull!);
    config[key] = value;
    return writeConfig(config);
  }

  /// Remove a specific key from config.
  Future<Result<void>> removeKey(String key) async {
    final readResult = await readConfig();
    if (readResult.isFailure) return Failure(readResult.errorOrNull!);

    final config = Map<String, dynamic>.from(readResult.dataOrNull!);
    config.remove(key);
    return writeConfig(config);
  }

  /// Check if config file exists.
  Future<bool> exists() async {
    final path = await getConfigPath();
    return File(path).exists();
  }

  /// Set restrictive file permissions.
  Future<void> _setFilePermissions(String path) async {
    if (Platform.isWindows) {
      // Windows: use icacls to restrict to current user
      // Best-effort; failure is non-fatal
      try {
        final user = Platform.environment['USERNAME'] ?? '';
        if (user.isNotEmpty) {
          await Process.run('icacls', [
            path, '/inheritance:r', '/grant:r', '$user:(R,W)',
          ], runInShell: true);
        }
      } catch (_) {}
    } else {
      // Unix: chmod 600 (owner read/write only)
      try {
        await Process.run('chmod', ['600', path]);
      } catch (_) {}
    }
  }
}
