import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/core/app_error.dart';

void main() {
  group('ConfigError', () {
    test('readFailed has correct message and code', () {
      const e = ConfigError.readFailed();
      expect(e.message, '无法读取配置文件');
      expect(e.code, 'CONFIG_READ_FAILED');
      expect(e, isA<AppError>());
    });

    test('writeFailed has correct message and code', () {
      const e = ConfigError.writeFailed();
      expect(e.message, '无法写入配置文件');
      expect(e.code, 'CONFIG_WRITE_FAILED');
    });

    test('parseFailed has correct message and code', () {
      const e = ConfigError.parseFailed();
      expect(e.message, '配置文件格式错误');
      expect(e.code, 'CONFIG_PARSE_FAILED');
    });

    test('notFound has correct message and code', () {
      const e = ConfigError.notFound();
      expect(e.message, '配置文件不存在');
      expect(e.code, 'CONFIG_NOT_FOUND');
      expect(e.cause, isNull);
    });

    test('toString includes code and message', () {
      const e = ConfigError.notFound();
      expect(e.toString(), contains('CONFIG_NOT_FOUND'));
      expect(e.toString(), contains('配置文件不存在'));
    });
  });

  group('NetworkError', () {
    test('timeout has correct message and code', () {
      const e = NetworkError.timeout();
      expect(e.message, isNotEmpty);
      expect(e.code, 'NETWORK_TIMEOUT');
      expect(e, isA<AppError>());
    });

    test('unreachable has correct message and code', () {
      const e = NetworkError.unreachable(endpoint: 'api.example.com');
      expect(e.message, contains('api.example.com'));
      expect(e.code, 'NETWORK_UNREACHABLE');
    });

    test('proxyFailed has correct message and code', () {
      const e = NetworkError.proxyFailed();
      expect(e.message, isNotEmpty);
      expect(e.code, 'NETWORK_PROXY_FAILED');
    });
  });

  group('AuthError', () {
    test('invalidKey has correct message and code', () {
      const e = AuthError.invalidKey();
      expect(e.message, isNotEmpty);
      expect(e.code, 'AUTH_INVALID_KEY');
      expect(e, isA<AppError>());
    });

    test('expired has correct message and code', () {
      const e = AuthError.expired();
      expect(e.message, isNotEmpty);
      expect(e.code, 'AUTH_EXPIRED');
    });

    test('rateLimited has correct message and code', () {
      const e = AuthError.rateLimited();
      expect(e.message, isNotEmpty);
      expect(e.code, 'AUTH_RATE_LIMITED');
    });
  });

  group('InstallError', () {
    test('nodeMissing has correct message and code', () {
      const e = InstallError.nodeMissing();
      expect(e.message, isNotEmpty);
      expect(e.code, 'INSTALL_NODE_MISSING');
      expect(e.cause, isNull);
      expect(e, isA<AppError>());
    });

    test('openclawFailed has correct message and code', () {
      const e = InstallError.openclawFailed();
      expect(e.message, isNotEmpty);
      expect(e.code, 'INSTALL_OPENCLAW_FAILED');
    });

    test('extractFailed has correct message and code', () {
      const e = InstallError.extractFailed();
      expect(e.message, isNotEmpty);
      expect(e.code, 'INSTALL_EXTRACT_FAILED');
    });

    test('permissionDenied has correct message and code', () {
      const e = InstallError.permissionDenied();
      expect(e.message, isNotEmpty);
      expect(e.code, 'INSTALL_PERMISSION_DENIED');
    });
  });

  group('ServiceError', () {
    test('notRunning has correct message and code', () {
      const e = ServiceError.notRunning();
      expect(e.message, isNotEmpty);
      expect(e.code, 'SERVICE_NOT_RUNNING');
      expect(e.cause, isNull);
      expect(e, isA<AppError>());
    });

    test('startFailed has correct message and code', () {
      const e = ServiceError.startFailed();
      expect(e.message, isNotEmpty);
      expect(e.code, 'SERVICE_START_FAILED');
    });

    test('connectionLost has correct message and code', () {
      const e = ServiceError.connectionLost();
      expect(e.message, isNotEmpty);
      expect(e.code, 'SERVICE_CONNECTION_LOST');
    });
  });

  group('ValidationError', () {
    test('emptyField includes field name in message', () {
      const e = ValidationError.emptyField(field: 'API Key');
      expect(e.message, contains('API Key'));
      expect(e.code, 'VALIDATION_EMPTY');
      expect(e.cause, isNull);
      expect(e, isA<AppError>());
    });

    test('invalidFormat includes field name in message', () {
      const e = ValidationError.invalidFormat(field: 'URL');
      expect(e.message, contains('URL'));
      expect(e.code, 'VALIDATION_FORMAT');
    });

    test('invalidUrl has correct message and code', () {
      const e = ValidationError.invalidUrl();
      expect(e.message, isNotEmpty);
      expect(e.code, 'VALIDATION_URL');
    });
  });

  group('AppError type hierarchy', () {
    test('all subtypes are AppError', () {
      final errors = <AppError>[
        const ConfigError.notFound(),
        const NetworkError.timeout(),
        const AuthError.invalidKey(),
        const InstallError.nodeMissing(),
        const ServiceError.notRunning(),
        const ValidationError.emptyField(field: 'x'),
      ];
      for (final e in errors) {
        expect(e, isA<AppError>());
        expect(e.message, isNotEmpty);
        expect(e.code, isNotEmpty);
      }
    });
  });
}
