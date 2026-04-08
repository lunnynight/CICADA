import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/claude_code_service.dart';

void main() {
  group('ApiProvider', () {
    test('fromJson parses all fields', () {
      final json = {
        'name': 'anthropic',
        'baseUrl': 'https://api.anthropic.com',
        'apiKey': 'sk-ant-test',
        'model': 'claude-3-opus',
        'description': 'Official Anthropic API',
      };
      final provider = ApiProvider.fromJson(json);
      expect(provider.name, equals('anthropic'));
      expect(provider.baseUrl, equals('https://api.anthropic.com'));
      expect(provider.apiKey, equals('sk-ant-test'));
      expect(provider.model, equals('claude-3-opus'));
      expect(provider.description, equals('Official Anthropic API'));
    });

    test('fromJson uses empty strings for missing fields', () {
      final provider = ApiProvider.fromJson({});
      expect(provider.name, equals(''));
      expect(provider.baseUrl, equals(''));
      expect(provider.apiKey, equals(''));
      expect(provider.model, equals(''));
      expect(provider.description, isNull);
    });

    test('toJson round-trips correctly', () {
      const provider = ApiProvider(
        name: 'test',
        baseUrl: 'https://example.com',
        apiKey: 'key123',
        model: 'gpt-4',
      );
      final json = provider.toJson();
      expect(json['name'], equals('test'));
      expect(json['baseUrl'], equals('https://example.com'));
      expect(json['apiKey'], equals('key123'));
      expect(json['model'], equals('gpt-4'));
      expect(json.containsKey('description'), isFalse);
    });

    test('toJson includes description when present', () {
      const provider = ApiProvider(
        name: 'x',
        baseUrl: 'u',
        apiKey: 'k',
        model: 'm',
        description: 'desc',
      );
      expect(provider.toJson()['description'], equals('desc'));
    });

    test('copyWith updates specified fields only', () {
      const original = ApiProvider(
        name: 'orig',
        baseUrl: 'https://orig.com',
        apiKey: 'orig-key',
        model: 'orig-model',
      );
      final updated = original.copyWith(name: 'new', apiKey: 'new-key');
      expect(updated.name, equals('new'));
      expect(updated.apiKey, equals('new-key'));
      expect(updated.baseUrl, equals('https://orig.com'));
      expect(updated.model, equals('orig-model'));
    });
  });

  group('ClaudeCodeService — file I/O with temp dir', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('claude_code_test_');
      ClaudeCodeService.overrideClaudeDirForTest(tempDir.path);
    });

    tearDown(() async {
      ClaudeCodeService.overrideClaudeDirForTest(null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('readSettings / writeSettings', () {
      test('readSettings returns empty map when file does not exist', () async {
        final settings = await ClaudeCodeService.readSettings();
        expect(settings, isEmpty);
      });

      test('writeSettings then readSettings round-trips data', () async {
        await ClaudeCodeService.writeSettings({'theme': 'dark', 'version': 2});
        final settings = await ClaudeCodeService.readSettings();
        expect(settings['theme'], equals('dark'));
        expect(settings['version'], equals(2));
      });
    });

    group('getEnvVars / setEnvVar / removeEnvVar', () {
      test('getEnvVars returns empty map when no env set', () async {
        final env = await ClaudeCodeService.getEnvVars();
        expect(env, isEmpty);
      });

      test('setEnvVar stores value retrievable via getEnvVars', () async {
        await ClaudeCodeService.setEnvVar('ANTHROPIC_API_KEY', 'sk-test');
        final env = await ClaudeCodeService.getEnvVars();
        expect(env['ANTHROPIC_API_KEY'], equals('sk-test'));
      });

      test('setEnvVar preserves existing env vars', () async {
        await ClaudeCodeService.setEnvVar('KEY_A', 'val_a');
        await ClaudeCodeService.setEnvVar('KEY_B', 'val_b');
        final env = await ClaudeCodeService.getEnvVars();
        expect(env['KEY_A'], equals('val_a'));
        expect(env['KEY_B'], equals('val_b'));
      });

      test('removeEnvVar deletes the key', () async {
        await ClaudeCodeService.setEnvVar('TO_REMOVE', 'value');
        await ClaudeCodeService.removeEnvVar('TO_REMOVE');
        final env = await ClaudeCodeService.getEnvVars();
        expect(env.containsKey('TO_REMOVE'), isFalse);
      });

      test('removeEnvVar on non-existent key does not throw', () async {
        await expectLater(
          ClaudeCodeService.removeEnvVar('NONEXISTENT'),
          completes,
        );
      });
    });

    group('getProviders / addProvider / removeProvider', () {
      test('getProviders returns empty list when file does not exist', () async {
        final providers = await ClaudeCodeService.getProviders();
        expect(providers, isEmpty);
      });

      test('addProvider stores provider retrievable via getProviders', () async {
        const provider = ApiProvider(
          name: 'test-provider',
          baseUrl: 'https://api.test.com',
          apiKey: 'key-123',
          model: 'test-model',
        );
        await ClaudeCodeService.addProvider(provider);
        final providers = await ClaudeCodeService.getProviders();
        expect(providers.length, equals(1));
        expect(providers.first.name, equals('test-provider'));
      });

      test('addProvider sets first provider as current', () async {
        const provider = ApiProvider(
          name: 'first',
          baseUrl: 'https://api.test.com',
          apiKey: 'key',
          model: 'model',
        );
        await ClaudeCodeService.addProvider(provider);
        final current = await ClaudeCodeService.getCurrentProvider();
        expect(current, equals('first'));
      });

      test('removeProvider deletes the provider', () async {
        const provider = ApiProvider(
          name: 'to-remove',
          baseUrl: 'https://api.test.com',
          apiKey: 'key',
          model: 'model',
        );
        await ClaudeCodeService.addProvider(provider);
        await ClaudeCodeService.removeProvider('to-remove');
        final providers = await ClaudeCodeService.getProviders();
        expect(providers, isEmpty);
      });
    });

    group('getMcpServers', () {
      test('returns empty map when settings has no mcpServers', () async {
        final servers = await ClaudeCodeService.getMcpServers();
        expect(servers, isEmpty);
      });

      test('returns mcpServers from settings', () async {
        await ClaudeCodeService.writeSettings({
          'mcpServers': {'filesystem': {'command': 'npx'}},
        });
        final servers = await ClaudeCodeService.getMcpServers();
        expect(servers.containsKey('filesystem'), isTrue);
      });
    });

    group('listSessions', () {
      test('returns empty list when projects directory does not exist', () async {
        final sessions = await ClaudeCodeService.listSessions();
        expect(sessions, isEmpty);
      });

      test('returns sessions from jsonl files', () async {
        final projectDir =
            Directory('${tempDir.path}/projects/my-project');
        await projectDir.create(recursive: true);
        final sessionFile =
            File('${projectDir.path}/session-abc123.jsonl');
        await sessionFile.writeAsString(
          '${jsonEncode({'type': 'human', 'message': {'content': 'Hello'}, 'timestamp': '2026-01-01T00:00:00Z'})}\n',
        );

        final sessions = await ClaudeCodeService.listSessions();
        expect(sessions.length, equals(1));
        expect(sessions.first.sessionId, equals('session-abc123'));
        expect(sessions.first.project, equals('my-project'));
      });
    });

    group('loadSession', () {
      test('returns empty list for non-existent file', () async {
        final messages =
            await ClaudeCodeService.loadSession('${tempDir.path}/nonexistent.jsonl');
        expect(messages, isEmpty);
      });

      test('parses messages from jsonl file', () async {
        final file = File('${tempDir.path}/test.jsonl');
        await file.writeAsString(
          '${jsonEncode({'type': 'human', 'data': {}, 'timestamp': '2026-01-01T00:00:00Z'})}\n'
          '${jsonEncode({'type': 'assistant', 'data': {}, 'timestamp': '2026-01-01T00:00:01Z'})}\n',
        );
        final messages = await ClaudeCodeService.loadSession(file.path);
        expect(messages.length, equals(2));
        expect(messages.first.type, equals('human'));
        expect(messages.last.type, equals('assistant'));
      });
    });
  });
}
