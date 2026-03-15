import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

/// Backup information for rollback
class BackupInfo {
  final String version;
  final String backupPath;
  final DateTime backupTime;
  final bool isValid;

  const BackupInfo({
    required this.version,
    required this.backupPath,
    required this.backupTime,
    required this.isValid,
  });

  BackupInfo.invalid()
      : version = '',
        backupPath = '',
        backupTime = DateTime(1970),
        isValid = false;
}

class UpdateService {
  static const String _currentVersion = '0.1.0';
  static const String _apiUrl =
      'https://api.github.com/repos/2233admin/cicada/releases/latest';
  static const String _backupDirName = 'cicada_backups';

  static Future<UpdateInfo> checkForUpdate() async {
    final response = await http.get(
      Uri.parse(_apiUrl),
      headers: {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API returned ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
    final body = data['body'] as String? ?? '';
    final assets = (data['assets'] as List<dynamic>? ?? []);

    String downloadUrl = '';
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.exe') || name.endsWith('.msix')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }

    final hasUpdate = _isNewer(tagName, _currentVersion);

    return UpdateInfo(
      hasUpdate: hasUpdate,
      latestVersion: tagName,
      releaseNotes: body,
      downloadUrl: downloadUrl,
    );
  }

  static bool _isNewer(String remote, String current) {
    final r = _parseVersion(remote);
    final c = _parseVersion(current);
    for (int i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  /// Create backup of current application before update
  static Future<BackupInfo> createBackup() async {
    try {
      // Get current app path
      final appDir = await _getAppDirectory();
      if (appDir == null) {
        return BackupInfo.invalid();
      }

      // Create backup directory
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_${_currentVersion}_$timestamp';

      // Create backup directory
      final backupFolder = Directory(backupPath);
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }

      // Copy essential files (main executable and related files)
      await _copyAppFiles(appDir, backupFolder);

      // Save backup metadata
      final metaFile = File('$backupPath/backup_meta.json');
      await metaFile.writeAsString(jsonEncode({
        'version': _currentVersion,
        'timestamp': timestamp,
        'platform': Platform.operatingSystem,
      }));

      return BackupInfo(
        version: _currentVersion,
        backupPath: backupPath,
        backupTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
        isValid: true,
      );
    } catch (e) {
      return BackupInfo.invalid();
    }
  }

  /// Check if there's a valid backup available
  static Future<BackupInfo?> getLatestBackup() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) return null;

      BackupInfo? latest;
      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final metaFile = File('${entity.path}/backup_meta.json');
          if (await metaFile.exists()) {
            final meta = jsonDecode(await metaFile.readAsString());
            final info = BackupInfo(
              version: meta['version'] as String,
              backupPath: entity.path,
              backupTime: DateTime.fromMillisecondsSinceEpoch(meta['timestamp'] as int),
              isValid: true,
            );
            if (latest == null || info.backupTime.isAfter(latest.backupTime)) {
              latest = info;
            }
          }
        }
      }
      return latest;
    } catch (e) {
      return null;
    }
  }

  /// Rollback to previous version from backup
  static Future<bool> rollback(BackupInfo backup) async {
    if (!backup.isValid) return false;

    try {
      final appDir = await _getAppDirectory();
      if (appDir == null) return false;

      // Restore files from backup
      final backupFolder = Directory(backup.backupPath);
      await _restoreAppFiles(backupFolder, appDir);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clean up old backups (keep only last 3)
  static Future<void> cleanupOldBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) return;

      final backups = <BackupInfo>[];
      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final metaFile = File('${entity.path}/backup_meta.json');
          if (await metaFile.exists()) {
            final meta = jsonDecode(await metaFile.readAsString());
            backups.add(BackupInfo(
              version: meta['version'] as String,
              backupPath: entity.path,
              backupTime: DateTime.fromMillisecondsSinceEpoch(meta['timestamp'] as int),
              isValid: true,
            ));
          }
        }
      }

      // Sort by time (newest first) and remove old ones
      backups.sort((a, b) => b.backupTime.compareTo(a.backupTime));
      for (int i = 3; i < backups.length; i++) {
        await Directory(backups[i].backupPath).delete(recursive: true);
      }
    } catch (e) {
      // Silently ignore cleanup errors
    }
  }

  /// Get app directory path
  static Future<Directory?> _getAppDirectory() async {
    try {
      if (Platform.isWindows) {
        final exePath = Platform.resolvedExecutable;
        return Directory(File(exePath).parent.path);
      } else if (Platform.isMacOS) {
        final exePath = Platform.resolvedExecutable;
        // For .app bundle, go up to the .app directory
        final appDir = File(exePath).parent.parent.parent;
        return appDir;
      } else {
        final exePath = Platform.resolvedExecutable;
        return Directory(File(exePath).parent.path);
      }
    } catch (e) {
      return null;
    }
  }

  /// Get backup directory
  static Future<Directory> _getBackupDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final backupDir = Directory('${appSupport.path}/$_backupDirName');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Copy app files to backup
  static Future<void> _copyAppFiles(Directory source, Directory dest) async {
    await for (final entity in source.list()) {
      final name = entity.path.split(Platform.pathSeparator).last;
      // Skip certain directories/files
      if (name.startsWith('.') || name == _backupDirName) continue;

      if (entity is File) {
        final target = File('${dest.path}/$name');
        await entity.copy(target.path);
      } else if (entity is Directory) {
        final target = Directory('${dest.path}/$name');
        await target.create(recursive: true);
        await _copyAppFiles(entity, target);
      }
    }
  }

  /// Restore app files from backup
  static Future<void> _restoreAppFiles(Directory source, Directory dest) async {
    await for (final entity in source.list()) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name == 'backup_meta.json') continue;

      if (entity is File) {
        final target = File('${dest.path}/$name');
        await entity.copy(target.path);
      } else if (entity is Directory) {
        final target = Directory('${dest.path}/$name');
        await target.create(recursive: true);
        await _restoreAppFiles(entity, target);
      }
    }
  }

  /// Download and install update with optional backup
  static Future<void> downloadAndLaunch(
    String url, {
    bool createBackup = true,
    Function(double)? onProgress,
  }) async {
    // Create backup if requested
    if (createBackup) {
      await UpdateService.createBackup();
      await UpdateService.cleanupOldBackups();
    }

    final tempDir = await getTemporaryDirectory();
    final ext = url.endsWith('.msix') ? '.msix' : '.exe';
    final dest = File('${tempDir.path}/cicada_update$ext');

    // Download with progress
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    final sink = dest.openWrite();

    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (onProgress != null && totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    // Launch installer
    if (Platform.isWindows) {
      if (ext == '.msix') {
        await Process.run('powershell', [
          '-Command',
          'Add-AppxPackage -Path "${dest.path}"',
        ]);
      } else {
        await Process.run(dest.path, [], runInShell: true);
      }
    } else if (Platform.isMacOS) {
      // For macOS, open the dmg or pkg
      await Process.run('open', [dest.path]);
    }
  }
}
