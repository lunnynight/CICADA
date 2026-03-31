import 'dart:convert';
import 'dart:io';

/// Shared JSON file I/O with atomic writes.
///
/// Atomic write: write to tmp file → rename. Prevents corruption on crash.
class JsonFile {
  static Future<Map<String, dynamic>> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      return json.decode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> write(
    String path,
    Map<String, dynamic> data, {
    bool restrictPermissions = false,
  }) async {
    final dir = Directory(File(path).parent.path);
    if (!await dir.exists()) await dir.create(recursive: true);
    final encoder = const JsonEncoder.withIndent('  ');
    final tmp = File('$path.tmp.${DateTime.now().millisecondsSinceEpoch}');
    await tmp.writeAsString(encoder.convert(data));
    await tmp.rename(path);
    if (restrictPermissions) await _setPermissions(path);
  }

  static Future<void> _setPermissions(String path) async {
    if (Platform.isWindows) {
      try {
        final user = Platform.environment['USERNAME'] ?? '';
        if (user.isNotEmpty) {
          await Process.run('icacls', [
            path, '/inheritance:r', '/grant:r', '$user:(R,W)',
          ], runInShell: true);
        }
      } catch (_) {}
    } else {
      try {
        await Process.run('chmod', ['600', path]);
      } catch (_) {}
    }
  }
}
