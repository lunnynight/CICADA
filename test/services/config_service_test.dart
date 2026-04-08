import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/services/config_service.dart';

void main() {
  group('ConfigService provider CRUD', () {
    late File configFile;
    String? _backup;

    setUp(() async {
      configFile = File(ConfigService.configPath);
      if (await configFile.exists()) {
        _backup = await configFile.readAsString();
      } else {
        _backup = null;
      }
      // Ensure clean state: delete config if exists
      if (await configFile.exists()) {
        await configFile.delete();
      }
    });

    tearDown(() async {
      // Restore original config
      if (_backup != null) {
        await configFile.parent.create(recursive: true);
        await configFile.writeAsString(_backup!);
      } else if (await configFile.exists()) {
        await configFile.delete();
      }
    });

    test('readConfig returns empty map when file missing', () async {
      final config = await ConfigService.readConfig();
      expect(config, isEmpty);
    });

    test('setProvider writes provider entry to config', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'test-key-123',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'claude-3-5-sonnet',
      );
      final config = await ConfigService.readConfig();
      expect(config['providers'], isA<Map>());
      final providers = config['providers'] as Map<String, dynamic>;
      expect(providers.containsKey('anthropic'), isTrue);
      expect(providers['anthropic']['apiKey'], 'test-key-123');
      expect(providers['anthropic']['apiBase'], 'https://api.anthropic.com');
      expect(providers['anthropic']['defaultModel'], 'claude-3-5-sonnet');
    });

    test('setProvider sets defaultProvider when none configured', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k1',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'claude-3-5-sonnet',
      );
      final config = await ConfigService.readConfig();
      expect(config['defaultProvider'], 'anthropic');
      expect(config['defaultModel'], 'claude-3-5-sonnet');
    });

    test('setProvider does NOT overwrite existing defaultProvider', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k1',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm1',
      );
      await ConfigService.setProvider(
        providerId: 'openai',
        apiKey: 'k2',
        apiBase: 'https://api.openai.com',
        defaultModel: 'm2',
      );
      final config = await ConfigService.readConfig();
      expect(config['defaultProvider'], 'anthropic');
    });

    test('second setProvider with same id overwrites entry', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'old-key',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm1',
      );
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'new-key',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm1',
      );
      final config = await ConfigService.readConfig();
      final providers = config['providers'] as Map<String, dynamic>;
      expect(providers['anthropic']['apiKey'], 'new-key');
    });

    test('removeProvider removes the provider entry', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm',
      );
      await ConfigService.removeProvider('anthropic');
      final config = await ConfigService.readConfig();
      final providers = (config['providers'] as Map<String, dynamic>?) ?? {};
      expect(providers.containsKey('anthropic'), isFalse);
    });

    test('removeProvider clears defaultProvider when it was the removed provider',
        () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm',
      );
      await ConfigService.removeProvider('anthropic');
      final config = await ConfigService.readConfig();
      expect(config.containsKey('defaultProvider'), isFalse);
      expect(config.containsKey('defaultModel'), isFalse);
    });

    test('removeProvider switches defaultProvider to remaining provider',
        () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k1',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm1',
      );
      await ConfigService.setProvider(
        providerId: 'openai',
        apiKey: 'k2',
        apiBase: 'https://api.openai.com',
        defaultModel: 'm2',
      );
      await ConfigService.removeProvider('anthropic');
      final config = await ConfigService.readConfig();
      expect(config['defaultProvider'], 'openai');
    });

    test('switchProvider updates defaultProvider and defaultModel', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k1',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'claude-3-5-sonnet',
      );
      await ConfigService.setProvider(
        providerId: 'openai',
        apiKey: 'k2',
        apiBase: 'https://api.openai.com',
        defaultModel: 'gpt-4',
      );
      await ConfigService.switchProvider('openai');
      final config = await ConfigService.readConfig();
      expect(config['defaultProvider'], 'openai');
      expect(config['defaultModel'], 'gpt-4');
    });

    test('switchProvider throws StateError when provider not configured',
        () async {
      expect(
        () => ConfigService.switchProvider('nonexistent'),
        throwsA(isA<StateError>()),
      );
    });

    test('getConfiguredProviders returns set of provider IDs', () async {
      await ConfigService.setProvider(
        providerId: 'anthropic',
        apiKey: 'k1',
        apiBase: 'https://api.anthropic.com',
        defaultModel: 'm1',
      );
      await ConfigService.setProvider(
        providerId: 'openai',
        apiKey: 'k2',
        apiBase: 'https://api.openai.com',
        defaultModel: 'm2',
      );
      final providers = await ConfigService.getConfiguredProviders();
      expect(providers, containsAll(['anthropic', 'openai']));
      expect(providers.length, 2);
    });
  });
}
