// MCP (Model Context Protocol) server configuration model.

enum McpTransport { stdio, sse }

class McpServer {
  final String id;
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final bool enabled;
  final McpTransport transport;
  final String? url; // SSE mode URL
  final String? description;
  final String? source; // clawhub / manual / imported / preset
  final DateTime? createdAt;

  const McpServer({
    required this.id,
    required this.name,
    required this.command,
    this.args = const [],
    this.env = const {},
    this.enabled = true,
    this.transport = McpTransport.stdio,
    this.url,
    this.description,
    this.source,
    this.createdAt,
  });

  McpServer copyWith({
    String? id,
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    bool? enabled,
    McpTransport? transport,
    String? url,
    String? description,
    String? source,
    DateTime? createdAt,
  }) {
    return McpServer(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      enabled: enabled ?? this.enabled,
      transport: transport ?? this.transport,
      url: url ?? this.url,
      description: description ?? this.description,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory McpServer.fromJson(Map<String, dynamic> json) {
    return McpServer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      command: json['command'] as String? ?? '',
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? const [],
      env: (json['env'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
      enabled: json['enabled'] as bool? ?? true,
      transport: json['transport'] == 'sse' ? McpTransport.sse : McpTransport.stdio,
      url: json['url'] as String?,
      description: json['description'] as String?,
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'args': args,
      'env': env,
      'enabled': enabled,
      'transport': transport == McpTransport.sse ? 'sse' : 'stdio',
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Convert to OpenClaw mcp.json format (command + args + env only)
  Map<String, dynamic> toOpenClawFormat() {
    if (transport == McpTransport.sse) {
      return {
        'transport': 'sse',
        'url': url ?? '',
        if (env.isNotEmpty) 'env': env,
      };
    }
    return {
      'command': command,
      'args': args,
      if (env.isNotEmpty) 'env': env,
    };
  }
}

/// Preset template for quick MCP server setup
class McpPreset {
  final String name;
  final String command;
  final List<String> args;
  final List<String> envKeys; // required env var names
  final String description;
  final String category;

  const McpPreset({
    required this.name,
    required this.command,
    required this.args,
    this.envKeys = const [],
    required this.description,
    this.category = '通用',
  });

  /// Create an McpServer from this preset with provided env values
  McpServer toServer({
    required String id,
    Map<String, String> env = const {},
  }) {
    return McpServer(
      id: id,
      name: name,
      command: command,
      args: args,
      env: env,
      description: description,
      source: 'preset',
      createdAt: DateTime.now(),
    );
  }
}
