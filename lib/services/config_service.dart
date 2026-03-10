import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ConfigService {
  static String get _homePath =>
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';

  static String get configDir => '$_homePath/.openclaw';
  static String get configPath => '$configDir/openclaw.json';

  static Future<Map<String, dynamic>> readConfig() async {
    final file = File(configPath);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> writeConfig(Map<String, dynamic> config) async {
    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(configPath);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(config));
  }

  /// Add or update a provider in openclaw.json
  static Future<void> setProvider({
    required String providerId,
    required String apiKey,
    required String apiBase,
    required String defaultModel,
  }) async {
    final config = await readConfig();

    // Ensure providers map exists
    final providers = (config['providers'] as Map<String, dynamic>?) ?? {};
    providers[providerId] = {
      'apiKey': apiKey,
      'apiBase': apiBase,
      'defaultModel': defaultModel,
    };
    config['providers'] = providers;

    // Set as default if none configured
    if (config['defaultProvider'] == null) {
      config['defaultProvider'] = providerId;
      config['defaultModel'] = defaultModel;
    }

    await writeConfig(config);
  }

  /// Remove a provider from openclaw.json
  static Future<void> removeProvider(String providerId) async {
    final config = await readConfig();
    final providers = (config['providers'] as Map<String, dynamic>?) ?? {};
    providers.remove(providerId);
    config['providers'] = providers;

    if (config['defaultProvider'] == providerId) {
      if (providers.isNotEmpty) {
        config['defaultProvider'] = providers.keys.first;
      } else {
        config.remove('defaultProvider');
        config.remove('defaultModel');
      }
    }

    await writeConfig(config);
  }

  /// Get configured provider IDs
  static Future<Set<String>> getConfiguredProviders() async {
    final config = await readConfig();
    final providers = config['providers'] as Map<String, dynamic>?;
    if (providers == null) return {};
    return providers.keys.toSet();
  }

  /// Test API connectivity
  static Future<(bool, String)> testConnection({
    required String apiBase,
    required String apiKey,
    required String model,
    required String provider,
  }) async {
    final client = http.Client();
    try {
      if (provider == 'ollama') {
        // Ollama: check /api/tags with 5s timeout
        final uri = Uri.parse('$apiBase/api/tags');
        final response = await client
            .get(uri)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) return (true, 'Ollama 连接成功');
        return (false, 'Ollama 未响应 (HTTP ${response.statusCode})');
      }

      // Build URL and headers per provider
      final String effectiveUrl;
      final Map<String, String> headers;
      final String body;

      if (provider == 'anthropic') {
        effectiveUrl = '$apiBase/v1/messages';
        headers = {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        };
        body = json.encode({
          'model': model,
          'max_tokens': 5,
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
        });
      } else if (provider == 'google') {
        effectiveUrl =
            '$apiBase/models/$model:generateContent?key=$apiKey';
        headers = {'Content-Type': 'application/json'};
        body = json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'hi'}
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 5},
        });
      } else {
        // OpenAI-compatible
        final String url;
        if (apiBase.endsWith('/v1')) {
          url = '$apiBase/chat/completions';
        } else if (apiBase.contains('/v1/')) {
          url = '${apiBase}chat/completions';
        } else {
          url = '$apiBase/v1/chat/completions';
        }
        effectiveUrl = url;
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
        body = json.encode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
          'max_tokens': 5,
        });
      }

      final uri = Uri.parse(effectiveUrl);
      final response = await client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        return (true, '连接成功 (HTTP $code)');
      } else if (code == 401 || code == 403) {
        return (false, 'API Key 无效 (HTTP $code)');
      } else if (code == 429) {
        // Rate limited but key is valid
        return (true, 'Key 有效，当前限流 (HTTP 429)');
      } else {
        return (false, '请求失败 (HTTP $code)');
      }
    } catch (e) {
      return (false, '连接失败: $e');
    } finally {
      client.close();
    }
  }

  /// Detect locally installed Ollama models.
  /// Tries `ollama list` CLI first, falls back to GET http://localhost:11434/api/tags.
  static Future<List<String>> detectOllamaModels() async {
    // Primary: CLI
    try {
      final result = await Process.run('ollama', ['list'], runInShell: true);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        final models = <String>[];
        for (final line in lines.skip(1)) {
          final name = line.split(RegExp(r'\s+')).firstOrNull?.trim();
          if (name != null && name.isNotEmpty) models.add(name);
        }
        if (models.isNotEmpty) return models;
      }
    } catch (_) {
      // Fall through to HTTP fallback
    }

    // Fallback: HTTP API
    try {
      final uri = Uri.parse('http://localhost:11434/api/tags');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final modelList = data['models'] as List<dynamic>? ?? [];
        return modelList
            .map((m) => (m as Map<String, dynamic>)['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Both methods failed
    }

    return [];
  }
}
