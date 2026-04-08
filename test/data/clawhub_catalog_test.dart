import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/clawhub_catalog.dart';

void main() {
  group('ClawHubSkill', () {
    test('url is constructed from slug', () {
      const skill = ClawHubSkill(
        slug: 'test-skill',
        name: 'Test',
        description: 'desc',
        category: '开发工具',
      );
      expect(skill.url, equals('https://clawhub.ai/skills/test-skill'));
    });

    test('default emoji is package box', () {
      const skill = ClawHubSkill(
        slug: 'x',
        name: 'X',
        description: 'd',
        category: 'c',
      );
      expect(skill.emoji, equals('📦'));
    });

    test('default score is 0', () {
      const skill = ClawHubSkill(
        slug: 'x',
        name: 'X',
        description: 'd',
        category: 'c',
      );
      expect(skill.score, equals(0));
    });
  });

  group('ClawHubCatalog.skills', () {
    test('is non-empty', () {
      expect(ClawHubCatalog.skills, isNotEmpty);
    });

    test('every skill has a non-empty slug', () {
      for (final skill in ClawHubCatalog.skills) {
        expect(skill.slug, isNotEmpty,
            reason: 'Skill ${skill.name} has empty slug');
      }
    });

    test('every skill has a non-empty name', () {
      for (final skill in ClawHubCatalog.skills) {
        expect(skill.name, isNotEmpty,
            reason: 'A skill has empty name');
      }
    });

    test('every skill has a non-empty category', () {
      for (final skill in ClawHubCatalog.skills) {
        expect(skill.category, isNotEmpty,
            reason: 'Skill ${skill.name} has empty category');
      }
    });

    test('every skill url starts with clawhub siteUrl', () {
      for (final skill in ClawHubCatalog.skills) {
        expect(
          skill.url,
          startsWith(ClawHubCatalog.siteUrl),
          reason: 'Skill ${skill.name} has unexpected url: ${skill.url}',
        );
      }
    });

    test('all skill categories are in ClawHubCatalog.categories (excluding 全部)', () {
      final validCategories =
          ClawHubCatalog.categories.where((c) => c != '全部').toSet();
      for (final skill in ClawHubCatalog.skills) {
        expect(
          validCategories,
          contains(skill.category),
          reason:
              'Skill ${skill.name} has unknown category: ${skill.category}',
        );
      }
    });

    test('contains git-essentials skill', () {
      final skill = ClawHubCatalog.skills
          .firstWhere((s) => s.slug == 'git-essentials');
      expect(skill.name, equals('Git Essentials'));
      expect(skill.category, equals('Git & 版本控制'));
    });

    test('no duplicate slugs', () {
      final slugs = ClawHubCatalog.skills.map((s) => s.slug).toList();
      final unique = slugs.toSet();
      expect(unique.length, equals(slugs.length),
          reason: 'Duplicate slugs found in catalog');
    });
  });

  group('ClawHubCatalog.categories', () {
    test('starts with 全部', () {
      expect(ClawHubCatalog.categories.first, equals('全部'));
    });

    test('contains expected categories', () {
      expect(
        ClawHubCatalog.categories,
        containsAll(['开发工具', 'Git & 版本控制', '测试', '安全']),
      );
    });

    test('has no duplicates', () {
      final unique = ClawHubCatalog.categories.toSet();
      expect(unique.length, equals(ClawHubCatalog.categories.length));
    });
  });

  group('ClawHubCatalog.siteUrl', () {
    test('is the expected URL', () {
      expect(ClawHubCatalog.siteUrl, equals('https://clawhub.ai'));
    });
  });
}
