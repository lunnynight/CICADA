import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../core/platform/platform_info.dart';
import '../core/platform/shell_env.dart';
import 'termux_bridge.dart';

/// Service for communicating with OpenClaw Gateway WebSocket API
class GatewayService {
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 18789;
  static String get _baseUrl => 'http://$_defaultHost:$_defaultPort';
  static String get _wsUrl => 'ws://$_defaultHost:$_defaultPort/ws';

  static WebSocketChannel? _channel;
  static final _messageController =
      StreamController<GatewayMessage>.broadcast();
  static final _logController = StreamController<LogEntry>.broadcast();
  static final _statusController = StreamController<GatewayStatus>.broadcast();

  /// Stream of incoming gateway messages
  static Stream<GatewayMessage> get messageStream => _messageController.stream;

  /// Stream of log entries
  static Stream<LogEntry> get logStream => _logController.stream;

  /// Stream of gateway status updates
  static Stream<GatewayStatus> get statusStream => _statusController.stream;

  static void _log(String message, {String level = 'info'}) {
    developer.log('[Gateway] $message', name: 'cicada.gateway');
  }

  /// Check if gateway is running
  static Future<bool> isRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get gateway health status
  static Future<HealthStatus?> getHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthStatus.fromJson(data);
      }
    } catch (e) {
      _log('Failed to get health: $e', level: 'error');
    }
    return null;
  }

  /// Connect to gateway WebSocket
  static Future<void> connect() async {
    if (_channel != null) return;

    try {
      _channel = IOWebSocketChannel.connect(_wsUrl);
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) => _log('WebSocket error: $error', level: 'error'),
        onDone: () {
          _log('WebSocket connection closed');
          _channel = null;
          _statusController.add(GatewayStatus.disconnected);
        },
      );
      _statusController.add(GatewayStatus.connected);
      _log('Connected to gateway WebSocket');
    } catch (e) {
      _log('Failed to connect: $e', level: 'error');
      _statusController.add(GatewayStatus.error);
      rethrow;
    }
  }

  /// Disconnect from gateway
  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _statusController.add(GatewayStatus.disconnected);
  }

  /// Send a message through the gateway
  static void sendMessage(
    String target,
    String message, {
    Map<String, dynamic>? options,
  }) {
    if (_channel == null) {
      throw StateError('Not connected to gateway');
    }

    final payload = {
      'type': 'message',
      'target': target,
      'content': message,
      if (options != null) 'options': options,
    };

    _channel!.sink.add(json.encode(payload));
  }

  /// Handle incoming WebSocket message
  static void _handleMessage(dynamic data) {
    try {
      final decoded = json.decode(data.toString());
      final message = GatewayMessage.fromJson(decoded);
      _messageController.add(message);

      // Also route to specific streams based on type
      switch (message.type) {
        case 'log':
          if (decoded['entry'] != null) {
            _logController.add(LogEntry.fromJson(decoded['entry']));
          }
          break;
        case 'status':
          _statusController.add(
            GatewayStatus.values.firstWhere(
              (s) => s.name == (decoded['status'] ?? 'unknown'),
              orElse: () => GatewayStatus.unknown,
            ),
          );
          break;
      }
    } catch (e) {
      _log('Failed to parse message: $e', level: 'error');
    }
  }

  /// Get active sessions
  static Future<List<Session>> getSessions() async {
    try {
      final String output;
      if (PlatformInfo.needsTermux) {
        final r = await TermuxBridge.runCommand('openclaw', args: ['sessions', '--json']);
        output = r.stdout;
      } else {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('openclaw', ['sessions', '--json'],
            runInShell: true, environment: env);
        if (result.exitCode != 0) return [];
        output = result.stdout.toString();
      }
      final data = json.decode(output);
      final List<dynamic> sessions = data['sessions'] ?? [];
      return sessions.map((s) => Session.fromJson(s)).toList();
    } catch (e) {
      _log('Failed to get sessions: $e', level: 'error');
    }
    return [];
  }

  /// Get channels
  static Future<List<Channel>> getChannels() async {
    try {
      final String output;
      if (PlatformInfo.needsTermux) {
        final r = await TermuxBridge.runCommand('openclaw', args: ['channels', 'list', '--json']);
        output = r.stdout;
      } else {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('openclaw', ['channels', 'list', '--json'],
            runInShell: true, environment: env);
        if (result.exitCode != 0) return [];
        output = result.stdout.toString();
      }
      final data = json.decode(output);
      final List<dynamic> channels = data['channels'] ?? [];
      return channels.map((c) => Channel.fromJson(c)).toList();
    } catch (e) {
      _log('Failed to get channels: $e', level: 'error');
    }
    return [];
  }

  /// Login to a channel
  static Future<bool> channelLogin(
    String channel, {
    bool verbose = false,
  }) async {
    try {
      if (PlatformInfo.needsTermux) {
        final args = ['channels', 'login', '--channel', channel];
        if (verbose) args.add('--verbose');
        final r = await TermuxBridge.runCommand('openclaw', args: args);
        return r.isSuccess;
      }

      final args = ['channels', 'login', '--channel', channel];
      if (verbose) args.add('--verbose');

      final env = await ShellEnv.getEnv();
      final process = await Process.start('openclaw', args,
          runInShell: true, environment: env);
      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
      return exitCode == 0;
    } catch (e) {
      _log('Failed to login to channel: $e', level: 'error');
      return false;
    }
  }

  /// Search memory
  static Future<List<MemoryEntry>> searchMemory(
    String query, {
    int limit = 20,
  }) async {
    try {
      final String output;
      if (PlatformInfo.needsTermux) {
        final r = await TermuxBridge.runCommand('openclaw', args: [
          'memory', 'search', query, '--limit', limit.toString(), '--json',
        ]);
        output = r.stdout;
      } else {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('openclaw', [
          'memory', 'search', query, '--limit', limit.toString(), '--json',
        ], runInShell: true, environment: env);
        if (result.exitCode != 0) return [];
        output = result.stdout.toString();
      }
      final data = json.decode(output);
      final List<dynamic> entries = data['results'] ?? [];
      return entries.map((e) => MemoryEntry.fromJson(e)).toList();
    } catch (e) {
      _log('Failed to search memory: $e', level: 'error');
    }
    return [];
  }

  /// Get logs via RPC
  static Future<List<LogEntry>> getLogs({int lines = 100}) async {
    try {
      final String output;
      if (PlatformInfo.needsTermux) {
        final r = await TermuxBridge.runCommand('openclaw', args: [
          'logs', '--lines', lines.toString(), '--json',
        ]);
        output = r.stdout;
      } else {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('openclaw', [
          'logs', '--lines', lines.toString(), '--json',
        ], runInShell: true, environment: env);
        if (result.exitCode != 0) return [];
        output = result.stdout.toString();
      }
      final data = json.decode(output);
      final List<dynamic> entries = data['logs'] ?? [];
      return entries.map((l) => LogEntry.fromJson(l)).toList();
    } catch (e) {
      _log('Failed to get logs: $e', level: 'error');
    }
    return [];
  }

  /// Stream logs in real-time
  static Stream<LogEntry> streamLogs() async* {
    if (PlatformInfo.needsTermux) {
      // On Android, poll logs periodically instead of streaming
      while (true) {
        final logs = await getLogs(lines: 20);
        for (final log in logs) {
          yield log;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    try {
      final env = await ShellEnv.getEnv();
      final process = await Process.start('openclaw', [
        'logs', '--follow', '--json',
      ], runInShell: true, environment: env);

      await for (final line in process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())) {
        try {
          final data = json.decode(line);
          yield LogEntry.fromJson(data);
        } catch (_) {}
      }
    } catch (e) {
      _log('Failed to stream logs: $e', level: 'error');
    }
  }

  /// Run agent with message
  static Future<AgentResult?> runAgent({
    String? to,
    String? message,
    bool deliver = false,
  }) async {
    try {
      final args = <String>['agent'];
      if (to != null) args.addAll(['--to', to]);
      if (message != null) args.addAll(['--message', message]);
      if (deliver) args.add('--deliver');
      args.add('--json');

      final String output;
      if (PlatformInfo.needsTermux) {
        final r = await TermuxBridge.runCommand('openclaw', args: args);
        if (!r.isSuccess) return null;
        output = r.stdout;
      } else {
        final env = await ShellEnv.getEnv();
        final result = await Process.run('openclaw', args,
            runInShell: true, environment: env);
        if (result.exitCode != 0) return null;
        output = result.stdout.toString();
      }
      final data = json.decode(output);
      return AgentResult.fromJson(data);
    } catch (e) {
      _log('Failed to run agent: $e', level: 'error');
    }
    return null;
  }

  /// Dispose all streams
  static void dispose() {
    disconnect();
    _messageController.close();
    _logController.close();
    _statusController.close();
  }
}

/// Gateway connection status
enum GatewayStatus { connected, disconnected, error, unknown }

/// Gateway message
class GatewayMessage {
  final String type;
  final dynamic content;
  final Map<String, dynamic> raw;

  GatewayMessage({
    required this.type,
    required this.content,
    required this.raw,
  });

  factory GatewayMessage.fromJson(Map<String, dynamic> json) {
    return GatewayMessage(
      type: json['type'] ?? 'unknown',
      content: json['content'],
      raw: json,
    );
  }
}

/// Health status from gateway
class HealthStatus {
  final String status;
  final Map<String, dynamic> services;
  final DateTime timestamp;

  HealthStatus({
    required this.status,
    required this.services,
    required this.timestamp,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] ?? 'unknown',
      services: json['services'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isHealthy => status == 'healthy' || status == 'ok';
}

/// Session information
class Session {
  final String id;
  final String? recipient;
  final String? channel;
  final DateTime lastActivity;
  final int messageCount;

  Session({
    required this.id,
    this.recipient,
    this.channel,
    required this.lastActivity,
    required this.messageCount,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      recipient: json['recipient'],
      channel: json['channel'],
      lastActivity:
          DateTime.tryParse(json['last_activity'] ?? '') ?? DateTime.now(),
      messageCount: json['message_count'] ?? 0,
    );
  }
}

/// Channel information
class Channel {
  final String name;
  final String type;
  final bool connected;
  final String? status;

  Channel({
    required this.name,
    required this.type,
    required this.connected,
    this.status,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json['name'] ?? '',
      type: json['type'] ?? 'unknown',
      connected: json['connected'] ?? false,
      status: json['status'],
    );
  }
}

/// Memory entry
class MemoryEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final double? relevance;
  final Map<String, dynamic> metadata;

  MemoryEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    this.relevance,
    required this.metadata,
  });

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      relevance: json['relevance']?.toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Log entry
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? source;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      level: json['level'] ?? 'info',
      message: json['message'] ?? '',
      source: json['source'],
    );
  }

  Color get color {
    switch (level.toLowerCase()) {
      case 'error':
      case 'fatal':
        return const Color(0xFFE53935);
      case 'warn':
      case 'warning':
        return const Color(0xFFFFA726);
      case 'debug':
        return const Color(0xFF42A5F5);
      case 'trace':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF66BB6A);
    }
  }
}

/// Agent run result
class AgentResult {
  final String response;
  final bool delivered;
  final Map<String, dynamic> metadata;

  AgentResult({
    required this.response,
    required this.delivered,
    required this.metadata,
  });

  factory AgentResult.fromJson(Map<String, dynamic> json) {
    return AgentResult(
      response: json['response'] ?? '',
      delivered: json['delivered'] ?? false,
      metadata: json['metadata'] ?? {},
    );
  }
}
