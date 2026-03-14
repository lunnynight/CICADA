import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Feishu (Lark) integration service.
/// Direct REST API calls to open.feishu.cn — no official Dart SDK.
class FeishuService {
  static const String _baseUrl = 'https://open.feishu.cn/open-apis';
  static const String _prefsAppId = 'feishu_app_id';
  static const String _prefsAppSecret = 'feishu_app_secret';
  static const String _prefsWebhook = 'feishu_webhook';

  /// Get stored credentials.
  static Future<FeishuCredentials?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString(_prefsAppId);
    final appSecret = prefs.getString(_prefsAppSecret);
    final webhook = prefs.getString(_prefsWebhook);

    if (appId == null || appSecret == null) return null;

    return FeishuCredentials(
      appId: appId,
      appSecret: appSecret,
      webhookUrl: webhook,
    );
  }

  /// Save credentials.
  static Future<void> saveCredentials(FeishuCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAppId, creds.appId);
    await prefs.setString(_prefsAppSecret, creds.appSecret);
    if (creds.webhookUrl != null) {
      await prefs.setString(_prefsWebhook, creds.webhookUrl!);
    }
  }

  /// Clear credentials.
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAppId);
    await prefs.remove(_prefsAppSecret);
    await prefs.remove(_prefsWebhook);
  }

  /// Get tenant access token.
  /// https://open.feishu.cn/document/server-docs/authentication-management/access-token/get-tenant-access-token
  static Future<FeishuTokenResult> getTenantAccessToken(
    String appId,
    String appSecret,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/v3/tenant_access_token/internal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_id': appId,
          'app_secret': appSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          return FeishuTokenResult.success(
            token: data['tenant_access_token'],
            expire: data['expire'],
          );
        } else {
          return FeishuTokenResult.error('${data['code']}: ${data['msg']}');
        }
      } else {
        return FeishuTokenResult.error('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return FeishuTokenResult.error(e.toString());
    }
  }

  /// Test connection with credentials.
  static Future<FeishuTestResult> testConnection(
    String appId,
    String appSecret,
  ) async {
    final startTime = DateTime.now();
    final tokenResult = await getTenantAccessToken(appId, appSecret);
    final latency = DateTime.now().difference(startTime).inMilliseconds;

    if (!tokenResult.success) {
      return FeishuTestResult.failure(tokenResult.error!, latency);
    }

    // Try to get bot info as verification
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bot/v3/bot_info'),
        headers: {'Authorization': 'Bearer ${tokenResult.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final bot = data['bot'] ?? {};
          return FeishuTestResult.success(
            botName: bot['app_name'] ?? 'Unknown',
            latency: latency,
          );
        }
      }
      return FeishuTestResult.success(latency: latency);
    } catch (e) {
      return FeishuTestResult.success(latency: latency);
    }
  }

  /// Send message via webhook.
  /// https://open.feishu.cn/document/client-docs/bot-v3/add-custom-bot
  static Future<bool> sendWebhookMessage(
    String webhookUrl,
    String content, {
    String title = 'CICADA 通知',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'msg_type': 'interactive',
          'card': {
            'config': {'wide_screen_mode': true},
            'header': {
              'title': {'tag': 'plain_text', 'content': title},
              'template': 'blue',
            },
            'elements': [
              {
                'tag': 'div',
                'text': {'tag': 'plain_text', 'content': content},
              },
            ],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'] == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send text message to user (requires user_open_id).
  static Future<bool> sendMessage(
    String token,
    String userOpenId,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/im/v1/messages?receive_id_type=open_id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receive_id': userOpenId,
          'msg_type': 'text',
          'content': jsonEncode({'text': content}),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'] == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Feishu credentials.
class FeishuCredentials {
  final String appId;
  final String appSecret;
  final String? webhookUrl;

  const FeishuCredentials({
    required this.appId,
    required this.appSecret,
    this.webhookUrl,
  });
}

/// Token result.
class FeishuTokenResult {
  final bool success;
  final String? token;
  final int? expire;
  final String? error;

  FeishuTokenResult.success({required this.token, required this.expire})
      : success = true,
        error = null;

  FeishuTokenResult.error(this.error)
      : success = false,
        token = null,
        expire = null;
}

/// Test connection result.
class FeishuTestResult {
  final bool success;
  final String? botName;
  final String? error;
  final int latency;

  FeishuTestResult.success({this.botName, required this.latency})
      : success = true,
        error = null;

  FeishuTestResult.failure(this.error, this.latency)
      : success = false,
        botName = null;
}

/// Placeholder for future integrations (QQ, DingTalk).
abstract class IntegrationService {
  Future<bool> isConfigured();
  Future<bool> testConnection();
  Future<bool> sendNotification(String content);
}
