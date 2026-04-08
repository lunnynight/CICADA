import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/skill_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SkillDiscoveryService', () {
    late Directory testSkillDir;

    setUpAll(() {
      final home = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '';
      testSkillDir =
          Directory('$home/.openclaw/skills/cicada-search-test-tmp');
    });

    tearDown(() async {
      if (await testSkillDir.exists()) {
        await testSkillDir.delete(recursive: true);
      }
    });

    test('getCategories starts with 全部 and 已安装', () async {
      final cats = await SkillDiscoveryService.getCategories();
      expect(cats.length, greaterThanOrEqualTo(2));
      expect(cats[0], '全部');
      expect(cats[1], '已安装');
    });

    test('search empty string returns same count as discoverAll', () async {
      final all = await SkillDiscoveryService.discoverAll();
      final searched = await SkillDiscoveryService.search('');
      expect(searched.length, all.length);
    });

    test('search with non-matching query returns empty list', () async {
      final results =
          await SkillDiscoveryService.search('xyzzy_no_match_12345');
      expect(results, isEmpty);
    });

    test('search finds installed skill by slug', () async {
      await testSkillDir.create(recursive: true);
      await File('${testSkillDir.path}/SKILL.md')
          .writeAsString('# cicada-search-test-tmp\nA test skill');

      final results =
          await SkillDiscoveryService.search('cicada-search-test-tmp');
      expect(
          results.any((s) => s.slug == 'cicada-search-test-tmp'), isTrue);
    });

    test('checkUpdates returns only skills with hasUpdate=true', () async {
      final updates = await SkillDiscoveryService.checkUpdates();
      for (final skill in updates) {
        expect(skill.hasUpdate, isTrue,
            reason: 'skill ${skill.slug} should have hasUpdate=true');
      }
    });
  });
}
