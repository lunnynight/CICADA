import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/core/json_file.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_file_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('JsonFile.read', () {
    test('returns empty map for non-existent file', () async {
      final path = '${tempDir.path}/nonexistent.json';
      final result = await JsonFile.read(path);
      expect(result, isEmpty);
    });

    test('reads valid JSON file', () async {
      final path = '${tempDir.path}/config.json';
      await File(path).writeAsString('{"key": "value", "num": 42}');
      final result = await JsonFile.read(path);
      expect(result['key'], 'value');
      expect(result['num'], 42);
    });

    test('returns empty map for empty file', () async {
      final path = '${tempDir.path}/empty.json';
      await File(path).writeAsString('');
      final result = await JsonFile.read(path);
      expect(result, isEmpty);
    });

    test('returns empty map for whitespace-only file', () async {
      final path = '${tempDir.path}/whitespace.json';
      await File(path).writeAsString('   \n  ');
      final result = await JsonFile.read(path);
      expect(result, isEmpty);
    });

    test('returns empty map for invalid JSON', () async {
      final path = '${tempDir.path}/invalid.json';
      await File(path).writeAsString('not valid json {{{');
      final result = await JsonFile.read(path);
      expect(result, isEmpty);
    });
  });

  group('JsonFile.write', () {
    test('creates file with JSON content', () async {
      final path = '${tempDir.path}/output.json';
      await JsonFile.write(path, {'hello': 'world', 'count': 3});
      expect(await File(path).exists(), true);
      final content = await File(path).readAsString();
      expect(content, contains('"hello"'));
      expect(content, contains('"world"'));
    });

    test('creates parent directories if missing', () async {
      final path = '${tempDir.path}/nested/deep/config.json';
      await JsonFile.write(path, {'x': 1});
      expect(await File(path).exists(), true);
    });

    test('overwrites existing file', () async {
      final path = '${tempDir.path}/overwrite.json';
      await JsonFile.write(path, {'v': 1});
      await JsonFile.write(path, {'v': 2});
      final result = await JsonFile.read(path);
      expect(result['v'], 2);
    });
  });

  group('JsonFile round-trip', () {
    test('write then read returns same data', () async {
      final path = '${tempDir.path}/roundtrip.json';
      final data = {
        'name': 'cicada',
        'version': '1.0.0',
        'count': 42,
        'enabled': true,
        'nested': {'key': 'val'},
      };
      await JsonFile.write(path, data);
      final result = await JsonFile.read(path);
      expect(result['name'], 'cicada');
      expect(result['version'], '1.0.0');
      expect(result['count'], 42);
      expect(result['enabled'], true);
      expect((result['nested'] as Map)['key'], 'val');
    });

    test('empty map round-trip', () async {
      final path = '${tempDir.path}/empty_rt.json';
      await JsonFile.write(path, {});
      final result = await JsonFile.read(path);
      expect(result, isEmpty);
    });
  });
}
