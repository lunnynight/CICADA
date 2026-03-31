import 'dart:io';

import '../core/app_error.dart';
import '../core/result.dart';
import '../models/proxy_config.dart';
import 'config_service.dart';

/// Manages proxy configuration for China deployment.
///
/// Handles:
/// - Proxy config persistence (in openclaw.json)
/// - Connectivity testing through proxy
/// - Environment variable generation for OpenClaw launch
class ProxyService {
  /// Load proxy config from openclaw.json
  static Future<ProxyConfig> loadConfig() async {
    try {
      final config = await ConfigService.readConfig();
      final proxyJson = config['proxy'] as Map<String, dynamic>?;
      if (proxyJson == null) return const ProxyConfig.disabled();
      return ProxyConfig.fromJson(proxyJson);
    } catch (_) {
      return const ProxyConfig.disabled();
    }
  }

  /// Save proxy config to openclaw.json
  static Future<Result<void>> saveConfig(ProxyConfig proxy) async {
    try {
      final config = await ConfigService.readConfig();
      config['proxy'] = proxy.toJson();
      await ConfigService.writeConfig(config);
      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Test connectivity to a URL through the configured proxy.
  ///
  /// Returns (success, latencyMs, errorMessage).
  static Future<({bool ok, int latencyMs, String? error})> testConnectivity(
    String testUrl, {
    ProxyConfig? proxy,
  }) async {
    final config = proxy ?? await loadConfig();
    final sw = Stopwatch()..start();

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);

      // Set proxy if configured
      if (config.isConfigured && config.enabled) {
        client.findProxy = (uri) => 'PROXY ${config.toEnvUrl()}';
      }

      final request = await client.getUrl(Uri.parse(testUrl));
      final response = await request.close();
      sw.stop();
      client.close();

      final code = response.statusCode;
      if (code == 200 || code == 301 || code == 302 || code == 304) {
        return (ok: true, latencyMs: sw.elapsedMilliseconds, error: null);
      }
      return (ok: false, latencyMs: sw.elapsedMilliseconds, error: 'HTTP $code');
    } catch (e) {
      sw.stop();
      return (ok: false, latencyMs: sw.elapsedMilliseconds, error: e.toString());
    }
  }

  /// Test connectivity to major API endpoints.
  ///
  /// Returns a map of endpoint → test result.
  static Future<Map<String, ({bool ok, int latencyMs, String? error})>>
      testApiEndpoints({ProxyConfig? proxy}) async {
    const endpoints = {
      'Anthropic': 'https://api.anthropic.com',
      'OpenAI': 'https://api.openai.com',
      'Google AI': 'https://generativelanguage.googleapis.com',
      'npm 镜像': 'https://registry.npmmirror.com',
    };

    final results = <String, ({bool ok, int latencyMs, String? error})>{};
    for (final entry in endpoints.entries) {
      results[entry.key] = await testConnectivity(entry.value, proxy: proxy);
    }
    return results;
  }

  /// Get environment variables to inject when launching OpenClaw.
  static Future<Map<String, String>> getProxyEnvVars() async {
    final config = await loadConfig();
    return config.toEnvVars();
  }
}
