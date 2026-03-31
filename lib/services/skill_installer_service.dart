import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_error.dart';
import '../core/result.dart';
import '../models/skill.dart';

/// Install, uninstall, and manage skills from ClawHub or GitHub.
class SkillInstallerService {
  static String get _homePath =>
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  static String get _skillsDir => '$_homePath/.openclaw/skills';

  /// Install a skill from ClawHub by slug.
  ///
  /// 1. Fetch skill metadata from ClawHub API
  /// 2. Download skill files
  /// 3. Write to ~/.openclaw/skills/{slug}/
  /// 4. Write .cicada-version marker
  static Future<Result<void>> installFromClawHub(String slug) async {
    try {
      final dir = Directory('$_skillsDir/$slug');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Try ClawHub API first
      final result = await _downloadFromClawHub(slug, dir.path);
      if (result.isSuccess) {
        await _writeVersionMarker(dir.path, 'clawhub');
        return const Success(null);
      }

      // Fallback: try GitHub raw download
      return Failure(InstallError(
        message: '从 ClawHub 安装 $slug 失败',
        code: 'SKILL_INSTALL_FAILED',
        cause: result.errorOrNull,
      ));
    } catch (e) {
      return Failure(InstallError(
        message: '安装技能 $slug 失败: $e',
        code: 'SKILL_INSTALL_FAILED',
        cause: e,
      ));
    }
  }

  /// Install a skill from a GitHub repository URL.
  static Future<Result<void>> installFromGitHub(String repoUrl, String slug) async {
    try {
      final dir = Directory('$_skillsDir/$slug');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Extract owner/repo from URL
      final uri = Uri.tryParse(repoUrl);
      if (uri == null || uri.pathSegments.length < 2) {
        return Failure(ValidationError.invalidUrl(cause: repoUrl));
      }

      final owner = uri.pathSegments[0];
      final repo = uri.pathSegments[1];

      // Download SKILL.md from GitHub raw
      final rawUrl = 'https://raw.githubusercontent.com/$owner/$repo/main/SKILL.md';
      final response = await _httpGet(rawUrl);
      if (response == null) {
        return Failure(NetworkError.unreachable(endpoint: rawUrl));
      }

      await File('${dir.path}/SKILL.md').writeAsString(response);
      await _writeVersionMarker(dir.path, 'github:$owner/$repo');

      return const Success(null);
    } catch (e) {
      return Failure(InstallError(
        message: '从 GitHub 安装失败: $e',
        code: 'SKILL_GITHUB_INSTALL_FAILED',
        cause: e,
      ));
    }
  }

  /// Uninstall a skill by slug.
  static Future<Result<void>> uninstall(String slug) async {
    try {
      final dir = Directory('$_skillsDir/$slug');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return const Success(null);
    } catch (e) {
      return Failure(InstallError(
        message: '卸载技能 $slug 失败: $e',
        code: 'SKILL_UNINSTALL_FAILED',
        cause: e,
      ));
    }
  }

  /// Scan all installed skills (not just bundled).
  static Future<List<Skill>> scanInstalled() async {
    final skills = <Skill>[];
    final dir = Directory(_skillsDir);
    if (!await dir.exists()) return skills;

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final slug = entity.path.split(Platform.pathSeparator).last;
        final skillFile = File('${entity.path}/SKILL.md');
        final versionFile = File('${entity.path}/.cicada-version');

        String? version;
        String source = 'local';
        if (await versionFile.exists()) {
          final content = await versionFile.readAsString();
          final lines = content.trim().split('\n');
          if (lines.isNotEmpty) version = lines[0];
          if (lines.length > 1) source = lines[1];
        }

        skills.add(Skill(
          slug: slug,
          name: slug,
          description: await skillFile.exists()
              ? _extractDescription(await skillFile.readAsString())
              : '',
          isInstalled: true,
          installedVersion: version,
          source: source.startsWith('github')
              ? SkillSource.github
              : source == 'clawhub'
                  ? SkillSource.clawhub
                  : source == 'bundled'
                      ? SkillSource.bundled
                      : SkillSource.local,
        ));
      }
    }
    return skills;
  }

  /// Check if a skill is installed.
  static Future<bool> isInstalled(String slug) async {
    return Directory('$_skillsDir/$slug').exists();
  }

  /// Get installed version of a skill.
  static Future<String?> getInstalledVersion(String slug) async {
    final file = File('$_skillsDir/$slug/.cicada-version');
    if (!await file.exists()) return null;
    final lines = (await file.readAsString()).trim().split('\n');
    return lines.isNotEmpty ? lines[0] : null;
  }

  // ── Private helpers ──

  static Future<Result<void>> _downloadFromClawHub(String slug, String destPath) async {
    // ClawHub API endpoint (best-effort, may not exist)
    final apiUrl = 'https://clawhub.ai/api/skills/$slug';
    final metaResponse = await _httpGet(apiUrl);
    if (metaResponse == null) {
      return Failure(NetworkError.unreachable(endpoint: apiUrl));
    }

    try {
      final meta = json.decode(metaResponse) as Map<String, dynamic>;
      final files = meta['files'] as List<dynamic>? ?? [];

      for (final fileInfo in files) {
        final fileName = fileInfo['name'] as String? ?? '';
        final downloadUrl = fileInfo['download_url'] as String? ?? '';
        if (fileName.isEmpty || downloadUrl.isEmpty) continue;

        final content = await _httpGet(downloadUrl);
        if (content != null) {
          await File('$destPath/$fileName').writeAsString(content);
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(InstallError(
        message: '解析 ClawHub 响应失败',
        code: 'SKILL_PARSE_FAILED',
        cause: e,
      ));
    }
  }

  static Future<void> _writeVersionMarker(String dirPath, String source) async {
    final now = DateTime.now().toIso8601String().split('T')[0];
    await File('$dirPath/.cicada-version').writeAsString('$now\n$source\n');
  }

  static Future<String?> _httpGet(String url) async {
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isNotEmpty && !body.startsWith('<!DOCTYPE')) return body;
      }
    } catch (_) {}
    return null;
  }

  static String _extractDescription(String content) {
    // Extract first non-heading, non-empty line as description
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('---')) {
        continue;
      }
      return trimmed.length > 100 ? '${trimmed.substring(0, 100)}...' : trimmed;
    }
    return '';
  }
}
