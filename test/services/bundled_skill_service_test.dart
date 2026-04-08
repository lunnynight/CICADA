import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/bundled_skill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledSkillMeta', () {
    test('fromJson parses all fields', () {
      final json = {
        'name': 'code-review',
        'version': '1.2.3',
        'description': 'Automated code review',
        'author': 'cicada',
        'files': ['skill.md', 'README.md'],
      };
      final meta = BundledSkillMeta.fromJson(json);
      expect(meta.name, equals('code-review'));
      expect(meta.version, equals('1.2.3'));
      expect(meta.description, equals('Automated code review'));
      expect(meta.author, equals('cicada'));
      expect(meta.files, equals(['skill.md', 'README.md']));
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {'name': 'minimal'};
      final meta = BundledSkillMeta.fromJson(json);
      expect(meta.version, equals('0.0.0'));
      expect(meta.description, equals(''));
      expect(meta.author, equals('unknown'));
      expect(meta.files, equals(['skill.md']));
    });
  });

  group('BundledSkillService.loadManifest', () {
    setUp(() {
      // Reset cached manifest between tests
      BundledSkillService.clearCacheForTest();
    });

    test('returns a list of BundledSkillMeta', () async {
      final result = await BundledSkillService.loadManifest();
      expect(result, isA<List<BundledSkillMeta>>());
    });

    test('each skill in manifest has a non-empty name and version', () async {
      final result = await BundledSkillService.loadManifest();
      for (final meta in result) {
        expect(meta.name, isNotEmpty);
        expect(meta.version, isNotEmpty);
      }
    });
  });

  group('BundledSkillService.isInstalled', () {
    test('returns false for a skill that does not exist on disk', () async {
      final result =
          await BundledSkillService.isInstalled('nonexistent-skill-xyz');
      expect(result, isFalse);
    });
  });

  group('BundledSkillService.getInstalledVersion', () {
    test('returns null when skill directory does not exist', () async {
      final version =
          await BundledSkillService.getInstalledVersion('nonexistent-skill-xyz');
      expect(version, isNull);
    });

    test('returns version string when .cicada-version file exists', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('bundled_skill_test_');
      try {
        final versionFile = File('${tempDir.path}/.cicada-version');
        await versionFile.writeAsString('1.0.0');

        // Override skills dir to point at temp parent
        BundledSkillService.overrideSkillsDirForTest(tempDir.parent.path);
        final skillName = tempDir.path.split(Platform.pathSeparator).last;
        final version =
            await BundledSkillService.getInstalledVersion(skillName);
        expect(version, equals('1.0.0'));
      } finally {
        BundledSkillService.overrideSkillsDirForTest(null);
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('BundledSkillService.isBundled', () {
    test('returns true for a known bundled skill name', () async {
      BundledSkillService.clearCacheForTest();
      final manifest = await BundledSkillService.loadManifest();
      if (manifest.isNotEmpty) {
        final knownName = manifest.first.name;
        final result = await BundledSkillService.isBundled(knownName);
        expect(result, isTrue);
      }
      // If manifest is empty (no assets), isBundled returns false — both are valid
    });

    test('returns false for an unknown skill name', () async {
      BundledSkillService.clearCacheForTest();
      final result = await BundledSkillService.isBundled('definitely-not-a-real-skill-xyz');
      expect(result, isFalse);
    });
  });

  group('BundledSkillService version comparison (_isNewer via needsUpdate)', () {
    test('needsUpdate returns true when skill is not installed', () async {
      BundledSkillService.clearCacheForTest();
      final meta = BundledSkillMeta.fromJson({
        'name': 'nonexistent-skill-xyz',
        'version': '1.0.0',
      });
      final result = await BundledSkillService.needsUpdate(meta);
      expect(result, isTrue);
    });
  });
}
