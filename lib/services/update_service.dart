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

class UpdateService {
  static const String _currentVersion = '0.1.0';
  static const String _apiUrl =
      'https://api.github.com/repos/2233admin/cicada/releases/latest';

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

  static Future<void> downloadAndLaunch(String url) async {
    final tempDir = await getTemporaryDirectory();
    final ext = url.endsWith('.msix') ? '.msix' : '.exe';
    final dest = File('${tempDir.path}/cicada_update$ext');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }
    await dest.writeAsBytes(response.bodyBytes);

    if (Platform.isWindows) {
      if (ext == '.msix') {
        await Process.run('powershell', [
          '-Command',
          'Add-AppxPackage -Path "${dest.path}"',
        ]);
      } else {
        await Process.run(dest.path, [], runInShell: true);
      }
    }
  }
}
