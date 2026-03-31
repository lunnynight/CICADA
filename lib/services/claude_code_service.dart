import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/json_file.dart';

// ==================== Data Models ====================

class ApiProvider {
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final String? description;

  const ApiProvider({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.description,
  });

  factory ApiProvider.fromJson(Map<String, dynamic> json) => ApiProvider(
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        model: json['model'] as String? ?? '',
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        if (description != null) 'description': description,
      };

  ApiProvider copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    String? description,
  }) =>
      ApiProvider(
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        description: description ?? this.description,
      );
}

class SessionMeta {
  final String sessionId;
  final String project;
  final DateTime timestamp;
  final String? firstMessage;
  final String filePath;

  const SessionMeta({
    required this.sessionId,
    required this.project,
    required this.timestamp,
    this.firstMessage,
    required this.filePath,
  });
}

class SessionMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? uuid;

  const SessionMessage({
    required this.type,
    required this.data,
    required this.timestamp,
    this.uuid,
  });
}

// ==================== Service ====================

class ClaudeCodeService {
  ClaudeCodeService._();

  static String get _homePath =>
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '';

  static String get _claudeDir => '$_homePath/.claude';

  // JSON I/O delegated to shared JsonFile utility
  static Future<Map<String, dynamic>> _readJsonFile(String path) =>
      JsonFile.read(path);
  static Future<void> _writeJsonFile(String path, Map<String, dynamic> data) =>
      JsonFile.write(path, data);

  // ==================== Provider Management ====================
  // Reads/writes ~/.claude/api-configs.json

  static Future<List<ApiProvider>> getProviders() async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    final list = data['apiConfigs'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiProvider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> getCurrentProvider() async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    return data['currentApi'] as String?;
  }

  static Future<void> switchProvider(String name) async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    data['currentApi'] = name;
    await _writeJsonFile('$_claudeDir/api-configs.json', data);

    // Sync env vars in settings.json
    final providers = (data['apiConfigs'] as List<dynamic>? ?? [])
        .map((e) => ApiProvider.fromJson(e as Map<String, dynamic>));
    final target = providers.where((p) => p.name == name).firstOrNull;
    if (target != null) {
      await _syncProviderToSettings(target);
    }
  }

  static Future<void> addProvider(ApiProvider provider) async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    final list = (data['apiConfigs'] as List<dynamic>? ?? []).toList();
    list.add(provider.toJson());
    data['apiConfigs'] = list;
    // If first provider, set as current
    data['currentApi'] ??= provider.name;
    await _writeJsonFile('$_claudeDir/api-configs.json', data);
  }

  static Future<void> updateProvider(
      String oldName, ApiProvider provider) async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    final list = (data['apiConfigs'] as List<dynamic>? ?? []).toList();
    final idx =
        list.indexWhere((e) => (e as Map<String, dynamic>)['name'] == oldName);
    if (idx >= 0) {
      list[idx] = provider.toJson();
      data['apiConfigs'] = list;
      if (data['currentApi'] == oldName) {
        data['currentApi'] = provider.name;
      }
      await _writeJsonFile('$_claudeDir/api-configs.json', data);
    }
  }

  static Future<void> removeProvider(String name) async {
    final data = await _readJsonFile('$_claudeDir/api-configs.json');
    final list = (data['apiConfigs'] as List<dynamic>? ?? []).toList();
    list.removeWhere((e) => (e as Map<String, dynamic>)['name'] == name);
    data['apiConfigs'] = list;
    if (data['currentApi'] == name) {
      data['currentApi'] =
          list.isNotEmpty ? (list.first as Map)['name'] : null;
    }
    await _writeJsonFile('$_claudeDir/api-configs.json', data);
  }

  /// Sync selected provider's credentials into settings.json env block.
  /// Writes both AUTH_TOKEN and API_KEY for compatibility with relays and VS Code.
  static Future<void> _syncProviderToSettings(ApiProvider provider) async {
    final settings = await readSettings();
    final env = Map<String, dynamic>.from(
        settings['env'] as Map<String, dynamic>? ?? {});
    env['ANTHROPIC_BASE_URL'] = provider.baseUrl;
    env['ANTHROPIC_AUTH_TOKEN'] = provider.apiKey;
    env['ANTHROPIC_API_KEY'] = provider.apiKey;
    env['ANTHROPIC_MODEL'] = provider.model;
    settings['env'] = env;
    await writeSettings(settings);
  }

  /// Test if a provider's API endpoint is reachable.
  /// Returns (success, latencyMs). Latency is wall-clock time of the request.
  static Future<({bool success, int latencyMs})> testProvider(
      ApiProvider provider) async {
    final sw = Stopwatch()..start();
    try {
      final response = await http
          .post(
            Uri.parse('${provider.baseUrl}/v1/messages'),
            headers: {
              'x-api-key': provider.apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body:
                '{"model":"${provider.model}","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}',
          )
          .timeout(const Duration(seconds: 10));
      sw.stop();
      final code = response.statusCode;
      // 200 = success, 400/401 = reachable but auth issue (still means endpoint works)
      final ok = code == 200 || code == 400 || code == 401;
      return (success: ok, latencyMs: sw.elapsedMilliseconds);
    } catch (_) {
      sw.stop();
      return (success: false, latencyMs: sw.elapsedMilliseconds);
    }
  }

  // ==================== Settings Management ====================
  // Reads/writes ~/.claude/settings.json

  static Future<Map<String, dynamic>> readSettings() async {
    return _readJsonFile('$_claudeDir/settings.json');
  }

  static Future<void> writeSettings(Map<String, dynamic> settings) async {
    await _writeJsonFile('$_claudeDir/settings.json', settings);
  }

  static Future<Map<String, String>> getEnvVars() async {
    final settings = await readSettings();
    final env = settings['env'] as Map<String, dynamic>? ?? {};
    return env.map((k, v) => MapEntry(k, v.toString()));
  }

  static Future<void> setEnvVar(String key, String value) async {
    final settings = await readSettings();
    final env = Map<String, dynamic>.from(
        settings['env'] as Map<String, dynamic>? ?? {});
    env[key] = value;
    settings['env'] = env;
    await writeSettings(settings);
  }

  static Future<void> removeEnvVar(String key) async {
    final settings = await readSettings();
    final env = Map<String, dynamic>.from(
        settings['env'] as Map<String, dynamic>? ?? {});
    env.remove(key);
    settings['env'] = env;
    await writeSettings(settings);
  }

  static Future<Map<String, dynamic>> getMcpServers() async {
    final settings = await readSettings();
    return Map<String, dynamic>.from(
        settings['mcpServers'] as Map<String, dynamic>? ?? {});
  }

  static Future<Map<String, dynamic>> getHooks() async {
    final settings = await readSettings();
    return Map<String, dynamic>.from(
        settings['hooks'] as Map<String, dynamic>? ?? {});
  }

  // ==================== Session Management ====================
  // Reads ~/.claude/projects/ and ~/.claude/history.jsonl

  static Future<List<SessionMeta>> listSessions({int limit = 50}) async {
    final projectsDir = Directory('$_claudeDir/projects');
    if (!await projectsDir.exists()) return [];

    final sessions = <SessionMeta>[];

    await for (final projectEntry in projectsDir.list()) {
      if (projectEntry is! Directory) continue;
      final projectName = projectEntry.path.split('/').last;

      await for (final file in projectEntry.list()) {
        if (file is! File || !file.path.endsWith('.jsonl')) continue;
        final fileName = file.path.split('/').last;
        final sessionId = fileName.replaceAll('.jsonl', '');

        try {
          final stat = await file.stat();
          String? firstMsg;
          // Read first few lines to find first user message
          final lines = await file
              .openRead()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .take(20)
              .toList();
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final obj = json.decode(line) as Map<String, dynamic>;
              final type = obj['type'] as String?;
              if (type == 'human' || type == 'user') {
                final msg = obj['message'] as Map<String, dynamic>?;
                final content = msg?['content'];
                if (content is String && content.isNotEmpty) {
                  firstMsg = content.length > 100
                      ? '${content.substring(0, 100)}...'
                      : content;
                  break;
                }
              }
            } catch (_) {}
          }

          sessions.add(SessionMeta(
            sessionId: sessionId,
            project: projectName,
            timestamp: stat.modified,
            firstMessage: firstMsg,
            filePath: file.path,
          ));
        } catch (_) {}
      }
    }

    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions.take(limit).toList();
  }

  static Future<List<SessionMessage>> loadSession(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    final messages = <SessionMessage>[];
    final lines = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final obj = json.decode(line) as Map<String, dynamic>;
        final type = obj['type'] as String? ?? 'unknown';
        final ts = obj['timestamp'] as String?;
        messages.add(SessionMessage(
          type: type,
          data: obj,
          timestamp:
              ts != null ? DateTime.parse(ts) : DateTime.now(),
          uuid: obj['uuid'] as String?,
        ));
      } catch (_) {}
    }
    return messages;
  }

}

