import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/skill_installer_service.dart';

void main() {
  group('SkillInstallerService filesystem', () {
    late Directory skillsDir;
    late Directory testSkillDir;

    setUpAll(() {
      final home = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '';
      skillsDir = Directory('$home/.openclaw/skills');
    });

    setUp(() async {
      // Create a test skill directory for each test
      testSkillDir =
          Directory('${skillsDir.path}/cicada-test-skill-tmp');
      if (await testSkillDir.exists()) {
        await testSkillDir.delete(recursive: true);
      }
    });

    tearDown(() async {
      if (await testSkillDir.exists()) {
        await testSkillDir.delete(recursive: true);
      }
    });

    test('isInstalled returns false when skill dir missing', () async {
      final result =
          await SkillInstallerService.isInstalled('cicada-test-skill-tmp');
      expect(result, isFalse);
    });

    test('isInstalled returns true after creating skill dir', () async {
      await testSkillDir.create(recursive: true);
      final result =
          await SkillInstallerService.isInstalled('cicada-test-skill-tmp');
      expect(result, isTrue);
    });

    test('getInstalledVersion returns null when .cicada-version missing',
        () async {
      await testSkillDir.create(recursive: true);
      final version = await SkillInstallerService.getInstalledVersion(
          'cicada-test-skill-tmp');
      expect(version, isNull);
    });

    test('getInstalledVersion returns version from .cicada-version',
        () async {
      await testSkillDir.create(recursive: true);
      await File('${testSkillDir.path}/.cicada-version')
          .writeAsString('1.2.3\nclawhub\n');
      final version = await SkillInstallerService.getInstalledVersion(
          'cicada-test-skill-tmp');
      expect(version, '1.2.3');
    });

    test('scanInstalled includes skill with isInstalled=true', () async {
      await testSkillDir.create(recursive: true);
      final skills = await SkillInstallerService.scanInstalled();
      expect(
          skills.any(
              (s) => s.slug == 'cicada-test-skill-tmp' && s.isInstalled),
          isTrue);
    });

    test('uninstall removes skill directory', () async {
      await testSkillDir.create(recursive: true);
      final result =
          await SkillInstallerService.uninstall('cicada-test-skill-tmp');
      expect(result.isSuccess, isTrue);
      expect(await testSkillDir.exists(), isFalse);
    });

    test('uninstall nonexistent skill returns Success', () async {
      final result =
          await SkillInstallerService.uninstall('cicada-test-skill-tmp');
      expect(result.isSuccess, isTrue);
    });
  });
}
