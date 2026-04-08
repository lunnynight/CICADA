import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/mcp_presets.dart';

void main() {
  group('mcpPresets', () {
    test('is non-empty', () {
      expect(mcpPresets, isNotEmpty);
    });

    test('every preset has a non-empty name', () {
      for (final preset in mcpPresets) {
        expect(preset.name, isNotEmpty, reason: 'A preset has empty name');
      }
    });

    test('every preset has a non-empty command', () {
      for (final preset in mcpPresets) {
        expect(preset.command, isNotEmpty,
            reason: 'Preset ${preset.name} has empty command');
      }
    });

    test('every preset has non-empty args', () {
      for (final preset in mcpPresets) {
        expect(preset.args, isNotEmpty,
            reason: 'Preset ${preset.name} has empty args');
      }
    });

    test('every preset has a non-empty category', () {
      for (final preset in mcpPresets) {
        expect(preset.category, isNotEmpty,
            reason: 'Preset ${preset.name} has empty category');
      }
    });

    test('contains Filesystem preset', () {
      final preset = mcpPresets.firstWhere((p) => p.name == 'Filesystem');
      expect(preset.command, equals('npx'));
      expect(preset.args, contains('@anthropic-ai/mcp-filesystem'));
      expect(preset.category, equals('系统'));
    });

    test('GitHub preset requires GITHUB_TOKEN env key', () {
      final preset = mcpPresets.firstWhere((p) => p.name == 'GitHub');
      expect(preset.envKeys, contains('GITHUB_TOKEN'));
    });

    test('presets without env requirements have empty envKeys', () {
      final filesystem = mcpPresets.firstWhere((p) => p.name == 'Filesystem');
      expect(filesystem.envKeys, isEmpty);
    });

    test('all preset categories are in mcpPresetCategories (excluding 全部)', () {
      final validCategories =
          mcpPresetCategories.where((c) => c != '全部').toSet();
      for (final preset in mcpPresets) {
        expect(
          validCategories,
          contains(preset.category),
          reason:
              'Preset ${preset.name} has unknown category: ${preset.category}',
        );
      }
    });

    test('toServer creates McpServer with correct fields', () {
      final preset = mcpPresets.firstWhere((p) => p.name == 'Filesystem');
      final server = preset.toServer(id: 'test-id');
      expect(server.id, equals('test-id'));
      expect(server.name, equals('Filesystem'));
      expect(server.command, equals('npx'));
      expect(server.source, equals('preset'));
    });

    test('toServer with env values passes them through', () {
      final preset =
          mcpPresets.firstWhere((p) => p.name == 'GitHub');
      final server = preset.toServer(
        id: 'gh-1',
        env: {'GITHUB_TOKEN': 'ghp_test'},
      );
      expect(server.env['GITHUB_TOKEN'], equals('ghp_test'));
    });
  });

  group('mcpPresetCategories', () {
    test('starts with 全部', () {
      expect(mcpPresetCategories.first, equals('全部'));
    });

    test('contains expected categories', () {
      expect(mcpPresetCategories, containsAll(['系统', '开发', '搜索', 'AI']));
    });

    test('has no duplicates', () {
      final unique = mcpPresetCategories.toSet();
      expect(unique.length, equals(mcpPresetCategories.length));
    });
  });
}
