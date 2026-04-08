import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/config_repository.dart';
import '../../lib/providers/config_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('config_provider_test_');
    ConfigRepository.overrideConfigDirForTest(tempDir.path);
  });

  tearDown(() async {
    ConfigRepository.overrideConfigDirForTest(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('configRepositoryProvider', () {
    test('returns a ConfigRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(configRepositoryProvider);
      expect(repo, isA<ConfigRepository>());
    });
  });

  group('configDataProvider', () {
    test('returns empty map when no config file exists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = await container.read(configDataProvider.future);
      expect(data, isEmpty);
    });

    test('returns config data when file exists', () async {
      final configFile = File('${tempDir.path}/openclaw.json');
      await configFile.writeAsString('{"apiKey":"test-key","model":"claude-3"}');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = await container.read(configDataProvider.future);
      expect(data['apiKey'], equals('test-key'));
      expect(data['model'], equals('claude-3'));
    });
  });

  group('configuredProvidersProvider', () {
    test('returns empty set when no providers configured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providers = await container.read(configuredProvidersProvider.future);
      expect(providers, isEmpty);
    });

    test('returns provider keys when providers exist', () async {
      final configFile = File('${tempDir.path}/openclaw.json');
      await configFile.writeAsString(
        '{"providers":{"anthropic":{},"openai":{}}}',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providers = await container.read(configuredProvidersProvider.future);
      expect(providers, containsAll(['anthropic', 'openai']));
      expect(providers.length, equals(2));
    });
  });

  group('mcpServersProvider', () {
    test('returns a list (empty when no mcp.json)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final servers = await container.read(mcpServersProvider.future);
      expect(servers, isA<List>());
    });
  });

  group('mcpEnabledCountProvider', () {
    test('returns 0 when no servers configured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(mcpEnabledCountProvider.future);
      expect(count, equals(0));
    });
  });

  group('proxyConfigProvider', () {
    test('returns a ProxyConfig instance', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final proxy = await container.read(proxyConfigProvider.future);
      expect(proxy, isNotNull);
    });

    test('returns disabled proxy when no proxy config', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final proxy = await container.read(proxyConfigProvider.future);
      expect(proxy.enabled, isFalse);
    });
  });
}
