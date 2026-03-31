import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_error.dart';
import '../core/json_file.dart';
import '../core/platform/shell_env.dart';
import '../core/result.dart';
import '../models/mcp_server.dart';

/// MCP server CRUD service.
///
/// Manages MCP server configurations stored in `~/.openclaw/mcp.json`.
class McpService {
  static String get _homePath =>
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  static String get _mcpConfigPath => '$_homePath/.openclaw/mcp.json';

  /// Get all configured MCP servers.
  static Future<List<McpServer>> getAll() async {
    try {
      final file = File(_mcpConfigPath);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final data = json.decode(content) as Map<String, dynamic>;
      final mcpServers = data['mcpServers'] as Map<String, dynamic>? ?? {};

      return mcpServers.entries.map((e) {
        final serverJson = e.value as Map<String, dynamic>;
        return McpServer.fromJson({...serverJson, 'id': e.key, 'name': serverJson['name'] ?? e.key});
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new MCP server.
  static Future<Result<void>> add(McpServer server) async {
    try {
      final servers = await _readRaw();
      if (servers.containsKey(server.id)) {
        return Failure(ValidationError(
          message: '插件 "${server.name}" 已存在',
          code: 'MCP_DUPLICATE',
        ));
      }
      servers[server.id] = server.toOpenClawFormat();
      // Store metadata alongside
      servers[server.id]['name'] = server.name;
      if (server.description != null) servers[server.id]['description'] = server.description;
      if (server.source != null) servers[server.id]['source'] = server.source;
      servers[server.id]['enabled'] = server.enabled;
      await _writeRaw(servers);
      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Update an existing MCP server.
  static Future<Result<void>> update(McpServer server) async {
    try {
      final servers = await _readRaw();
      servers[server.id] = server.toOpenClawFormat();
      servers[server.id]['name'] = server.name;
      if (server.description != null) servers[server.id]['description'] = server.description;
      if (server.source != null) servers[server.id]['source'] = server.source;
      servers[server.id]['enabled'] = server.enabled;
      await _writeRaw(servers);
      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Remove an MCP server by ID.
  static Future<Result<void>> remove(String id) async {
    try {
      final servers = await _readRaw();
      servers.remove(id);
      await _writeRaw(servers);
      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Toggle enabled/disabled state.
  static Future<Result<void>> toggle(String id, bool enabled) async {
    try {
      final servers = await _readRaw();
      if (!servers.containsKey(id)) {
        return Failure(ConfigError(message: '插件 "$id" 不存在'));
      }
      (servers[id] as Map<String, dynamic>)['enabled'] = enabled;
      await _writeRaw(servers);
      return const Success(null);
    } catch (e) {
      return Failure(ConfigError.writeFailed(cause: e));
    }
  }

  /// Test MCP server connectivity by attempting to start it briefly.
  static Future<Result<String>> test(McpServer server) async {
    if (server.transport == McpTransport.sse) {
      // SSE: HTTP health check
      try {
        final response = await http.get(
          Uri.parse(server.url ?? ''),
        ).timeout(const Duration(seconds: 5));
        final code = response.statusCode;
        if (code == 200 || code == 301 || code == 302) {
          return Success('SSE 端点可访问 (HTTP $code)');
        }
        return Failure(NetworkError(message: 'SSE 端点不可访问 (HTTP $code)'));
      } catch (e) {
        return Failure(NetworkError(message: '连接失败: $e'));
      }
    }

    // stdio: try to start the command and check it doesn't immediately crash
    try {
      final shellEnv = await ShellEnv.getEnv();
      final env = <String, String>{
        ...?shellEnv,
        ...server.env,
      };
      final process = await Process.start(
        server.command,
        server.args,
        environment: env,
        runInShell: true,
      );

      // Wait briefly for startup
      final exitFuture = process.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          process.kill();
          return -999; // sentinel: still running = good
        },
      );

      final exitCode = await exitFuture;
      if (exitCode == -999) {
        return const Success('插件启动正常');
      }
      if (exitCode == 0) {
        return const Success('插件可用');
      }
      return Failure(ServiceError(message: '插件启动失败 (exit: $exitCode)'));
    } catch (e) {
      return Failure(InstallError(
        message: '无法启动插件命令 "${server.command}": $e',
        code: 'MCP_START_FAILED',
        cause: e,
      ));
    }
  }

  /// Get count of enabled servers.
  static Future<int> enabledCount() async {
    final all = await getAll();
    return all.where((s) => s.enabled).length;
  }

  // ── Private I/O ──

  static Future<Map<String, dynamic>> _readRaw() async {
    final data = await JsonFile.read(_mcpConfigPath);
    return data['mcpServers'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> _writeRaw(Map<String, dynamic> servers) async {
    final data = await JsonFile.read(_mcpConfigPath);
    data['mcpServers'] = servers;
    await JsonFile.write(_mcpConfigPath, data);
  }
}
