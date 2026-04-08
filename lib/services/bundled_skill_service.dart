import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pub_semver/pub_semver.dart';

/// Metadata for a single bundled skill
class BundledSkillMeta {
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> files;

  const BundledSkillMeta({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.files,
  });

  factory BundledSkillMeta.fromJson(Map<String, dynamic> json) =>
      BundledSkillMeta(
        name: json['name'] as String,
        version: json['version'] as String? ?? '0.0.0',
        description: json['description'] as String? ?? '',
        author: json['author'] as String? ?? 'unknown',
        files:
            (json['files'] as List<dynamic>?)?.cast<String>() ?? ['skill.md'],
      );
}

/// Manages bundled skills that ship with the app.
/// Provides offline-first skill installation by extracting
/// bundled assets to the OpenClaw skills directory.
class BundledSkillService {
  static List<BundledSkillMeta>? _cachedManifest;
  static String? _skillsDirOverride;

  /// Clear cached manifest for testing.
  static void clearCacheForTest() {
    _cachedManifest = null;
  }

  /// Override skills directory for testing. Pass null to reset.
  static void overrideSkillsDirForTest(String? path) {
    _skillsDirOverride = path;
  }

  /// Load the bundled skills manifest from assets
  static Future<List<BundledSkillMeta>> loadManifest() async {
    if (_cachedManifest != null) return _cachedManifest!;
    try {
      final str = await rootBundle.loadString(
        'assets/bundled_skills/index.json',
      );
      final data = json.decode(str) as Map<String, dynamic>;
      final skills =
          (data['skills'] as List<dynamic>)
              .map((e) => BundledSkillMeta.fromJson(e as Map<String, dynamic>))
              .toList();
      _cachedManifest = skills;
      return skills;
    } catch (_) {
      return [];
    }
  }

  /// Get the OpenClaw skills directory path
  static String _getSkillsDir() {
    if (_skillsDirOverride != null) return _skillsDirOverride!;
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
    return '$home/.openclaw/skills';
  }

  /// Check if a skill is already installed locally
  static Future<bool> isInstalled(String skillName) async {
    final dir = Directory('${_getSkillsDir()}/$skillName');
    return dir.existsSync();
  }

  /// Get installed version of a skill (reads version from local metadata)
  static Future<String?> getInstalledVersion(String skillName) async {
    final metaFile = File('${_getSkillsDir()}/$skillName/.cicada-version');
    if (await metaFile.exists()) {
      return (await metaFile.readAsString()).trim();
    }
    return null;
  }

  /// Check if a bundled skill is newer than the installed version
  static Future<bool> needsUpdate(BundledSkillMeta meta) async {
    final installed = await getInstalledVersion(meta.name);
    if (installed == null) return true;
    return _isNewer(meta.version, installed);
  }

  /// Install a bundled skill by copying assets to OpenClaw skills dir
  static Future<bool> installBundled(BundledSkillMeta meta) async {
    try {
      final targetDir = Directory('${_getSkillsDir()}/${meta.name}');

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      for (final fileName in meta.files) {
        final assetPath = 'assets/bundled_skills/${meta.name}/$fileName';
        try {
          final content = await rootBundle.loadString(assetPath);
          final targetFile = File('${targetDir.path}/$fileName');
          await targetFile.writeAsString(content);
        } catch (_) {
          // Skip files that don't exist in bundle
        }
      }

      final versionFile = File('${targetDir.path}/.cicada-version');
      await versionFile.writeAsString(meta.version);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Install all bundled skills that are not yet installed or need updates.
  /// Returns the number of skills installed/updated.
  static Future<int> syncBundledSkills() async {
    final manifest = await loadManifest();
    int count = 0;
    for (final meta in manifest) {
      if (await needsUpdate(meta)) {
        final ok = await installBundled(meta);
        if (ok) count++;
      }
    }
    return count;
  }

  /// Check if a skill name is in the bundled manifest
  static Future<bool> isBundled(String skillName) async {
    final manifest = await loadManifest();
    return manifest.any((m) => m.name == skillName);
  }

  static bool _isNewer(String remote, String current) {
    try {
      final remoteVer = Version.parse(remote);
      final currentVer = Version.parse(current);
      return remoteVer > currentVer;
    } catch (_) {
      return false;
    }
  }
}
