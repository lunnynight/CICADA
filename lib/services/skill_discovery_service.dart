import '../models/skill.dart';
import 'skill_installer_service.dart';
import 'bundled_skill_service.dart';
import '../data/clawhub_catalog.dart';
/// Unified skill discovery: local scan + ClawHub catalog + bundled.
class SkillDiscoveryService {
  /// Get all skills from all sources, merged and deduplicated.
  ///
  /// Priority: installed state from local scan, metadata from catalog.
  static Future<List<Skill>> discoverAll() async {
    final installed = await SkillInstallerService.scanInstalled();
    final installedMap = {for (final s in installed) s.slug: s};

    final bundled = await _loadBundled();
    final catalog = _loadCatalog();

    // Merge: catalog as base, overlay with installed state
    final merged = <String, Skill>{};

    for (final s in catalog) {
      final inst = installedMap[s.slug];
      merged[s.slug] = s.copyWith(
        isInstalled: inst != null,
        installedVersion: inst?.installedVersion,
      );
    }

    // Add bundled skills
    for (final s in bundled) {
      final existing = merged[s.slug];
      final inst = installedMap[s.slug];
      if (existing != null) {
        merged[s.slug] = existing.copyWith(
          source: SkillSource.bundled,
          isInstalled: inst != null,
          installedVersion: inst?.installedVersion,
        );
      } else {
        merged[s.slug] = s.copyWith(
          isInstalled: inst != null,
          installedVersion: inst?.installedVersion,
        );
      }
    }

    // Add locally installed skills not in catalog
    for (final entry in installedMap.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }

    return merged.values.toList();
  }

  /// Search skills by query string.
  static Future<List<Skill>> search(String query) async {
    if (query.isEmpty) return discoverAll();
    final q = query.toLowerCase();
    final all = await discoverAll();
    return all.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.slug.toLowerCase().contains(q) ||
      s.description.toLowerCase().contains(q) ||
      s.category.toLowerCase().contains(q)
    ).toList();
  }

  /// Get skills that have updates available.
  static Future<List<Skill>> checkUpdates() async {
    final all = await discoverAll();
    return all.where((s) => s.hasUpdate).toList();
  }

  /// Get all unique categories.
  static Future<List<String>> getCategories() async {
    final all = await discoverAll();
    final cats = all.map((s) => s.category).where((c) => c.isNotEmpty).toSet();
    return ['全部', '已安装', '内置', ...cats.toList()..sort()];
  }

  // ── Private ──

  static Future<List<Skill>> _loadBundled() async {
    try {
      final manifest = await BundledSkillService.loadManifest();
      return manifest.map((m) => Skill(
        slug: m.name,
        name: m.name,
        description: m.description,
        author: m.author,
        source: SkillSource.bundled,
        version: m.version,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  static List<Skill> _loadCatalog() {
    try {
      return ClawHubCatalog.skills.map((entry) => Skill(
        slug: entry.slug,
        name: entry.name,
        description: entry.description,
        category: entry.category,
        emoji: entry.emoji,
        score: entry.score,
        source: SkillSource.clawhub,
        author: 'ClawHub',
      )).toList();
    } catch (_) {
      return [];
    }
  }
}
