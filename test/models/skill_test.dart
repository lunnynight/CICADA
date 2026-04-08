import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/skill.dart';

void main() {
  group('SkillSource enum', () {
    test('has bundled, clawhub, github, local values', () {
      expect(SkillSource.values, containsAll([
        SkillSource.bundled,
        SkillSource.clawhub,
        SkillSource.github,
        SkillSource.local,
      ]));
    });
  });

  group('Skill.fromJson', () {
    test('parses all fields from JSON', () {
      final json = {
        'slug': 'code-review',
        'name': '代码审查',
        'description': '自动代码审查',
        'author': 'cicada-team',
        'category': '开发',
        'emoji': '🔍',
        'version': '1.0.0',
        'source': 'bundled',
        'isInstalled': true,
        'installedVersion': '1.0.0',
        'score': 4.8,
        'downloads': 1000,
      };
      final skill = Skill.fromJson(json);
      expect(skill.slug, 'code-review');
      expect(skill.name, '代码审查');
      expect(skill.description, '自动代码审查');
      expect(skill.author, 'cicada-team');
      expect(skill.category, '开发');
      expect(skill.emoji, '🔍');
      expect(skill.version, '1.0.0');
      expect(skill.source, SkillSource.bundled);
      expect(skill.isInstalled, true);
      expect(skill.installedVersion, '1.0.0');
      expect(skill.score, 4.8);
      expect(skill.downloads, 1000);
    });

    test('uses defaults for missing optional fields', () {
      final json = {'slug': 'test', 'name': 'Test', 'description': 'desc'};
      final skill = Skill.fromJson(json);
      expect(skill.author, '');
      expect(skill.category, '');
      expect(skill.emoji, '');
      expect(skill.version, '');
      expect(skill.source, SkillSource.local);
      expect(skill.isInstalled, false);
      expect(skill.installedVersion, isNull);
      expect(skill.score, 0.0);
      expect(skill.downloads, 0);
    });

    test('parses clawhub source', () {
      final json = {'slug': 'x', 'name': 'X', 'description': 'd', 'source': 'clawhub'};
      expect(Skill.fromJson(json).source, SkillSource.clawhub);
    });

    test('parses github source', () {
      final json = {'slug': 'x', 'name': 'X', 'description': 'd', 'source': 'github'};
      expect(Skill.fromJson(json).source, SkillSource.github);
    });

    test('unknown source defaults to local', () {
      final json = {'slug': 'x', 'name': 'X', 'description': 'd', 'source': 'unknown'};
      expect(Skill.fromJson(json).source, SkillSource.local);
    });
  });

  group('Skill.toJson', () {
    test('round-trip fromJson → toJson', () {
      final json = {
        'slug': 'code-review',
        'name': '代码审查',
        'description': '自动代码审查',
        'author': 'team',
        'category': '开发',
        'emoji': '🔍',
        'version': '1.0.0',
        'source': 'bundled',
        'isInstalled': true,
        'installedVersion': '1.0.0',
        'score': 4.8,
        'downloads': 500,
      };
      final skill = Skill.fromJson(json);
      final out = skill.toJson();
      expect(out['slug'], 'code-review');
      expect(out['name'], '代码审查');
      expect(out['source'], 'bundled');
      expect(out['isInstalled'], true);
      expect(out['installedVersion'], '1.0.0');
      expect(out['score'], 4.8);
      expect(out['downloads'], 500);
    });

    test('installedVersion omitted when null', () {
      const skill = Skill(slug: 'x', name: 'X', description: 'd');
      final out = skill.toJson();
      expect(out.containsKey('installedVersion'), false);
    });
  });

  group('Skill.copyWith', () {
    test('updates only specified fields', () {
      const skill = Skill(
        slug: 'code-review',
        name: '代码审查',
        description: 'desc',
        isInstalled: false,
        version: '1.0.0',
      );
      final updated = skill.copyWith(isInstalled: true, installedVersion: '1.0.0');
      expect(updated.slug, 'code-review');
      expect(updated.name, '代码审查');
      expect(updated.isInstalled, true);
      expect(updated.installedVersion, '1.0.0');
      expect(updated.version, '1.0.0');
    });
  });

  group('Skill computed properties', () {
    test('isBundled returns true for bundled source', () {
      const skill = Skill(
        slug: 'x',
        name: 'X',
        description: 'd',
        source: SkillSource.bundled,
      );
      expect(skill.isBundled, true);
    });

    test('isBundled returns false for non-bundled source', () {
      const skill = Skill(slug: 'x', name: 'X', description: 'd', source: SkillSource.clawhub);
      expect(skill.isBundled, false);
    });

    test('hasUpdate returns true when installed version differs from latest', () {
      const skill = Skill(
        slug: 'x',
        name: 'X',
        description: 'd',
        isInstalled: true,
        version: '2.0.0',
        installedVersion: '1.0.0',
      );
      expect(skill.hasUpdate, true);
    });

    test('hasUpdate returns false when versions match', () {
      const skill = Skill(
        slug: 'x',
        name: 'X',
        description: 'd',
        isInstalled: true,
        version: '1.0.0',
        installedVersion: '1.0.0',
      );
      expect(skill.hasUpdate, false);
    });

    test('hasUpdate returns false when not installed', () {
      const skill = Skill(
        slug: 'x',
        name: 'X',
        description: 'd',
        isInstalled: false,
        version: '2.0.0',
        installedVersion: '1.0.0',
      );
      expect(skill.hasUpdate, false);
    });
  });

  group('Skill.fromClawHub', () {
    test('creates skill with clawhub source', () {
      final entry = {
        'slug': 'hub-skill',
        'name': 'Hub Skill',
        'description': 'From ClawHub',
        'category': '工具',
        'emoji': '🛠',
        'score': 4.5,
      };
      final skill = Skill.fromClawHub(entry);
      expect(skill.slug, 'hub-skill');
      expect(skill.source, SkillSource.clawhub);
      expect(skill.author, 'ClawHub');
      expect(skill.score, 4.5);
    });
  });
}
