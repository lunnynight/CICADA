import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/proxy_config.dart';

void main() {
  group('ProxyType enum', () {
    test('has none, http, socks5, system values', () {
      expect(ProxyType.values, containsAll([
        ProxyType.none,
        ProxyType.http,
        ProxyType.socks5,
        ProxyType.system,
      ]));
    });
  });

  group('ProxyConfig.fromJson', () {
    test('parses http proxy with all fields', () {
      final json = {
        'type': 'http',
        'host': '127.0.0.1',
        'port': 7890,
        'username': 'user',
        'password': 'pass',
        'enabled': true,
      };
      final config = ProxyConfig.fromJson(json);
      expect(config.type, ProxyType.http);
      expect(config.host, '127.0.0.1');
      expect(config.port, 7890);
      expect(config.username, 'user');
      expect(config.password, 'pass');
      expect(config.enabled, true);
    });

    test('parses socks5 type', () {
      final json = {'type': 'socks5', 'host': '127.0.0.1', 'port': 1080, 'enabled': false};
      final config = ProxyConfig.fromJson(json);
      expect(config.type, ProxyType.socks5);
    });

    test('defaults to none type for unknown string', () {
      final json = {'type': 'unknown', 'host': '', 'port': 0, 'enabled': false};
      final config = ProxyConfig.fromJson(json);
      expect(config.type, ProxyType.none);
    });

    test('uses defaults for missing fields', () {
      final config = ProxyConfig.fromJson({});
      expect(config.type, ProxyType.none);
      expect(config.host, '');
      expect(config.port, 0);
      expect(config.username, isNull);
      expect(config.password, isNull);
      expect(config.enabled, false);
    });
  });

  group('ProxyConfig.toJson', () {
    test('round-trip fromJson → toJson', () {
      final json = {
        'type': 'http',
        'host': '127.0.0.1',
        'port': 7890,
        'username': 'user',
        'password': 'pass',
        'enabled': true,
      };
      final config = ProxyConfig.fromJson(json);
      final out = config.toJson();
      expect(out['type'], 'http');
      expect(out['host'], '127.0.0.1');
      expect(out['port'], 7890);
      expect(out['username'], 'user');
      expect(out['password'], 'pass');
      expect(out['enabled'], true);
    });

    test('null username/password omitted from JSON', () {
      const config = ProxyConfig(type: ProxyType.http, host: '127.0.0.1', port: 8080);
      final out = config.toJson();
      expect(out.containsKey('username'), false);
      expect(out.containsKey('password'), false);
    });
  });

  group('ProxyConfig.isConfigured', () {
    test('returns true when type=http, host set, port > 0', () {
      const config = ProxyConfig(type: ProxyType.http, host: '127.0.0.1', port: 7890);
      expect(config.isConfigured, true);
    });

    test('returns true when type=socks5, host set, port > 0', () {
      const config = ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080);
      expect(config.isConfigured, true);
    });

    test('returns false when type=none', () {
      const config = ProxyConfig(type: ProxyType.none, host: '127.0.0.1', port: 7890);
      expect(config.isConfigured, false);
    });

    test('returns false when host is empty', () {
      const config = ProxyConfig(type: ProxyType.http, host: '', port: 7890);
      expect(config.isConfigured, false);
    });

    test('returns false when port is 0', () {
      const config = ProxyConfig(type: ProxyType.http, host: '127.0.0.1', port: 0);
      expect(config.isConfigured, false);
    });

    test('disabled() constructor returns not configured', () {
      const config = ProxyConfig.disabled();
      expect(config.isConfigured, false);
    });
  });

  group('ProxyConfig.copyWith', () {
    test('updates only specified fields', () {
      const config = ProxyConfig(
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
        enabled: false,
      );
      final updated = config.copyWith(enabled: true, port: 8080);
      expect(updated.type, ProxyType.http);
      expect(updated.host, '127.0.0.1');
      expect(updated.port, 8080);
      expect(updated.enabled, true);
    });
  });

  group('ProxyConfig.toEnvUrl', () {
    test('returns empty string when not configured', () {
      const config = ProxyConfig();
      expect(config.toEnvUrl(), '');
    });

    test('returns http URL for http proxy', () {
      const config = ProxyConfig(type: ProxyType.http, host: '127.0.0.1', port: 7890);
      expect(config.toEnvUrl(), 'http://127.0.0.1:7890');
    });

    test('returns socks5 URL for socks5 proxy', () {
      const config = ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080);
      expect(config.toEnvUrl(), 'socks5://127.0.0.1:1080');
    });

    test('includes auth when username set', () {
      const config = ProxyConfig(
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
        username: 'user',
        password: 'pass',
      );
      expect(config.toEnvUrl(), 'http://user:pass@127.0.0.1:7890');
    });
  });

  group('ProxyConfig.toEnvVars', () {
    test('returns empty map when not enabled', () {
      const config = ProxyConfig(
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
        enabled: false,
      );
      expect(config.toEnvVars(), isEmpty);
    });

    test('returns proxy env vars when enabled and configured', () {
      const config = ProxyConfig(
        type: ProxyType.http,
        host: '127.0.0.1',
        port: 7890,
        enabled: true,
      );
      final vars = config.toEnvVars();
      expect(vars['HTTP_PROXY'], 'http://127.0.0.1:7890');
      expect(vars['HTTPS_PROXY'], 'http://127.0.0.1:7890');
      expect(vars['http_proxy'], 'http://127.0.0.1:7890');
      expect(vars['https_proxy'], 'http://127.0.0.1:7890');
    });
  });
}
