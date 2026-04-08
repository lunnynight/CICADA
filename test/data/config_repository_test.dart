import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/config_repository.dart';

void main() {
  group('ConfigRepository', () {
    late Directory tempDir;
    late ConfigRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('config_repo_test_');
      // Override the cached config dir to point at our temp directory
      ConfigRepository.overrideConfigDirForTest(tempDir.path);
      repo = ConfigRepository();
    });

    tearDown(() async {
      ConfigRepository.overrideConfigDirForTest(null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('readConfig', () {
      test('returns empty map when config file does not exist', () async {
        final result = await repo.readConfig();
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });

      test('returns empty map when config file is empty', () async {
        final configFile = File('${tempDir.path}/openclaw.json');
        await configFile.writeAsString('');
        final result = await repo.readConfig();
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });

      test('returns parsed data when config file has valid JSON', () async {
        final configFile = File('${tempDir.path}/openclaw.json');
        await configFile.writeAsString('{"key": "value", "num": 42}');
        final result = await repo.readConfig();
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?['key'], equals('value'));
        expect(result.dataOrNull?['num'], equals(42));
      });

      test('returns Failure when config file has invalid JSON', () async {
        final configFile = File('${tempDir.path}/openclaw.json');
        await configFile.writeAsString('{not valid json}');
        final result = await repo.readConfig();
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isNotNull);
      });
    });

    group('writeConfig', () {
      test('creates config file with correct JSON content', () async {
        final data = {'provider': 'anthropic', 'model': 'claude-3'};
        final result = await repo.writeConfig(data);
        expect(result.isSuccess, isTrue);

        final configFile = File('${tempDir.path}/openclaw.json');
        expect(await configFile.exists(), isTrue);
        final content = await configFile.readAsString();
        final parsed = json.decode(content) as Map<String, dynamic>;
        expect(parsed['provider'], equals('anthropic'));
        expect(parsed['model'], equals('claude-3'));
      });

      test('creates parent directory if it does not exist', () async {
        final nestedDir = Directory('${tempDir.path}/nested/config');
        ConfigRepository.overrideConfigDirForTest(nestedDir.path);
        final result = await repo.writeConfig({'x': 1});
        expect(result.isSuccess, isTrue);
        expect(await nestedDir.exists(), isTrue);
      });

      test('overwrites existing config file', () async {
        await repo.writeConfig({'first': true});
        final result = await repo.writeConfig({'second': true});
        expect(result.isSuccess, isTrue);

        final readResult = await repo.readConfig();
        expect(readResult.dataOrNull?.containsKey('first'), isFalse);
        expect(readResult.dataOrNull?['second'], isTrue);
      });
    });

    group('readConfig after writeConfig', () {
      test('round-trips data correctly', () async {
        final original = {
          'apiKey': 'sk-test-123',
          'model': 'claude-3-opus',
          'temperature': 0.7,
          'tags': ['a', 'b'],
        };
        await repo.writeConfig(original);
        final result = await repo.readConfig();
        expect(result.isSuccess, isTrue);
        final data = result.dataOrNull!;
        expect(data['apiKey'], equals('sk-test-123'));
        expect(data['model'], equals('claude-3-opus'));
        expect(data['temperature'], equals(0.7));
      });
    });

    group('updateKey', () {
      test('adds a new key to existing config', () async {
        await repo.writeConfig({'existing': 'value'});
        final result = await repo.updateKey('newKey', 'newValue');
        expect(result.isSuccess, isTrue);

        final readResult = await repo.readConfig();
        expect(readResult.dataOrNull?['existing'], equals('value'));
        expect(readResult.dataOrNull?['newKey'], equals('newValue'));
      });

      test('updates an existing key without affecting others', () async {
        await repo.writeConfig({'a': 1, 'b': 2});
        await repo.updateKey('a', 99);
        final readResult = await repo.readConfig();
        expect(readResult.dataOrNull?['a'], equals(99));
        expect(readResult.dataOrNull?['b'], equals(2));
      });

      test('works on empty config (no file)', () async {
        final result = await repo.updateKey('key', 'val');
        expect(result.isSuccess, isTrue);
        final readResult = await repo.readConfig();
        expect(readResult.dataOrNull?['key'], equals('val'));
      });
    });

    group('removeKey', () {
      test('removes an existing key', () async {
        await repo.writeConfig({'keep': 1, 'remove': 2});
        final result = await repo.removeKey('remove');
        expect(result.isSuccess, isTrue);

        final readResult = await repo.readConfig();
        expect(readResult.dataOrNull?.containsKey('remove'), isFalse);
        expect(readResult.dataOrNull?['keep'], equals(1));
      });

      test('succeeds silently when key does not exist', () async {
        await repo.writeConfig({'a': 1});
        final result = await repo.removeKey('nonexistent');
        expect(result.isSuccess, isTrue);
      });
    });

    group('readKey', () {
      test('returns value for existing key', () async {
        await repo.writeConfig({'token': 'abc123'});
        final result = await repo.readKey('token');
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals('abc123'));
      });

      test('returns null for missing key', () async {
        await repo.writeConfig({'other': 1});
        final result = await repo.readKey('missing');
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });
    });

    group('exists', () {
      test('returns false when config file does not exist', () async {
        expect(await repo.exists(), isFalse);
      });

      test('returns true after writing config', () async {
        await repo.writeConfig({'x': 1});
        expect(await repo.exists(), isTrue);
      });
    });
  });
}
