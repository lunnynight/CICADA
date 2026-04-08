import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/proxy_service.dart';
import '../../lib/services/config_service.dart';
import '../../lib/models/proxy_config.dart';

void main() {
  group('ProxyService config', () {
    late File configFile;
    String? _backup;

    setUp(() async {
      configFile = File(ConfigService.configPath);
      if (await configFile.exists()) {
        _backup = await configFile.readAsString();
        await configFile.delete();
      } else {
        _backup = null;
      }
      // Ensure config directory exists so writes succeed
      await configFile.parent.create(recursive: true);
    });

    tearDown(() async {
      if (_backup != null) {
        await configFile.parent.create(recursive: true);
        await configFile.writeAsString(_backup!);
      } else if (await configFile.exists()) {
        await configFile.delete();
      }
    });

    test('loadConfig returns disabled when no proxy in config', () async {
      final proxy = await ProxyService.loadConfig();
      expect(proxy.enabled, isFalse);
    });

    test('saveConfig persists and loadConfig retrieves', () async {
      const proxy = ProxyConfig(
        enabled: true,
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
      );
      await ProxyService.saveConfig(proxy);
      final loaded = await ProxyService.loadConfig();
      expect(loaded.enabled, isTrue);
      expect(loaded.host, '127.0.0.1');
      expect(loaded.port, 7890);
    });

    test('getProxyEnvVars returns empty map when proxy disabled', () async {
      final vars = await ProxyService.getProxyEnvVars();
      expect(vars, isEmpty);
    });

    test('getProxyEnvVars returns proxy vars when enabled', () async {
      const proxy = ProxyConfig(
        enabled: true,
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
      );
      await ProxyService.saveConfig(proxy);
      final vars = await ProxyService.getProxyEnvVars();
      expect(vars, isNotEmpty);
      expect(vars['HTTP_PROXY'], contains('127.0.0.1'));
      expect(vars['HTTPS_PROXY'], contains('7890'));
    });
  });
}
