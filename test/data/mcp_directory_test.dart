import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/mcp_directory.dart';

void main() {
  group('mcpDirectory', () {
    test('is non-empty', () {
      expect(mcpDirectory, isNotEmpty);
    });

    test('every entry has a non-empty name', () {
      for (final entry in mcpDirectory) {
        expect(entry.name, isNotEmpty, reason: 'Entry npm=${entry.npm} has empty name');
      }
    });

    test('every entry has a non-empty npm package name', () {
      for (final entry in mcpDirectory) {
        expect(entry.npm, isNotEmpty, reason: 'Entry name=${entry.name} has empty npm');
      }
    });

    test('every entry has a non-empty category', () {
      for (final entry in mcpDirectory) {
        expect(entry.category, isNotEmpty, reason: 'Entry name=${entry.name} has empty category');
      }
    });

    test('every entry has a non-negative star count', () {
      for (final entry in mcpDirectory) {
        expect(entry.stars, greaterThanOrEqualTo(0));
      }
    });

    test('contains Filesystem entry from Anthropic', () {
      final entry = mcpDirectory.firstWhere((e) => e.name == 'Filesystem');
      expect(entry.npm, equals('@anthropic-ai/mcp-filesystem'));
      expect(entry.category, equals('系统'));
    });

    test('contains GitHub entry', () {
      final entry = mcpDirectory.firstWhere((e) => e.name == 'GitHub');
      expect(entry.npm, contains('mcp-github'));
    });

    test('all categories are in mcpDirectoryCategories (excluding 全部)', () {
      final validCategories = mcpDirectoryCategories.where((c) => c != '全部').toSet();
      for (final entry in mcpDirectory) {
        expect(
          validCategories,
          contains(entry.category),
          reason: 'Entry ${entry.name} has unknown category: ${entry.category}',
        );
      }
    });
  });

  group('mcpDirectoryCategories', () {
    test('starts with 全部', () {
      expect(mcpDirectoryCategories.first, equals('全部'));
    });

    test('contains expected categories', () {
      expect(mcpDirectoryCategories, containsAll(['系统', '开发', '搜索', '数据库']));
    });

    test('has no duplicates', () {
      final unique = mcpDirectoryCategories.toSet();
      expect(unique.length, equals(mcpDirectoryCategories.length));
    });
  });
}
