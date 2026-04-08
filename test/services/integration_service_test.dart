import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/integration_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FeishuCredentials', () {
    test('data class fields are accessible', () {
      const creds = FeishuCredentials(appId: 'cli_test123', appSecret: 'secret_abc');
      expect(creds.appId, 'cli_test123');
      expect(creds.appSecret, 'secret_abc');
      expect(creds.webhookUrl, isNull);
    });

    test('webhookUrl field is accessible when set', () {
      const creds = FeishuCredentials(
        appId: 'cli_test123',
        appSecret: 'secret_abc',
        webhookUrl: 'https://open.feishu.cn/hook/test',
      );
      expect(creds.webhookUrl, 'https://open.feishu.cn/hook/test');
    });
  });

  group('FeishuTokenResult', () {
    test('success has success=true and token', () {
      final result = FeishuTokenResult.success(token: 'token_xyz', expire: 7200);
      expect(result.success, isTrue);
      expect(result.token, 'token_xyz');
      expect(result.expire, 7200);
    });

    test('error has success=false and error message', () {
      final result = FeishuTokenResult.error('auth failed');
      expect(result.success, isFalse);
      expect(result.error, 'auth failed');
      expect(result.token, isNull);
    });
  });

  group('FeishuTestResult', () {
    test('success has success=true', () {
      final result = FeishuTestResult.success(latency: 150);
      expect(result.success, isTrue);
      expect(result.latency, 150);
    });

    test('success with botName', () {
      final result = FeishuTestResult.success(botName: 'TestBot', latency: 200);
      expect(result.success, isTrue);
      expect(result.botName, 'TestBot');
    });

    test('failure has success=false and error', () {
      final result = FeishuTestResult.failure('connection refused', 500);
      expect(result.success, isFalse);
      expect(result.error, 'connection refused');
      expect(result.latency, 500);
    });
  });

  group('FeishuService credentials', () {
    test('getCredentials returns null when nothing saved', () async {
      final creds = await FeishuService.getCredentials();
      expect(creds, isNull);
    });

    test('saveCredentials then getCredentials returns saved values', () async {
      const creds = FeishuCredentials(appId: 'cli_test', appSecret: 'secret_test');
      await FeishuService.saveCredentials(creds);
      final loaded = await FeishuService.getCredentials();
      expect(loaded, isNotNull);
      expect(loaded!.appId, 'cli_test');
      expect(loaded.appSecret, 'secret_test');
    });

    test('saveCredentials with webhook persists webhook', () async {
      const creds = FeishuCredentials(
        appId: 'cli_test',
        appSecret: 'secret_test',
        webhookUrl: 'https://open.feishu.cn/hook/abc',
      );
      await FeishuService.saveCredentials(creds);
      final loaded = await FeishuService.getCredentials();
      expect(loaded!.webhookUrl, 'https://open.feishu.cn/hook/abc');
    });

    test('clearCredentials removes saved credentials', () async {
      const creds = FeishuCredentials(appId: 'cli_test', appSecret: 'secret_test');
      await FeishuService.saveCredentials(creds);
      await FeishuService.clearCredentials();
      final loaded = await FeishuService.getCredentials();
      expect(loaded, isNull);
    });
  });
}
