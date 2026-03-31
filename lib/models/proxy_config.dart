// Proxy configuration model for China deployment.

enum ProxyType { none, http, socks5, system }

class ProxyConfig {
  final ProxyType type;
  final String host;
  final int port;
  final String? username;
  final String? password;
  final bool enabled;

  const ProxyConfig({
    this.type = ProxyType.none,
    this.host = '',
    this.port = 0,
    this.username,
    this.password,
    this.enabled = false,
  });

  const ProxyConfig.disabled()
      : type = ProxyType.none,
        host = '',
        port = 0,
        username = null,
        password = null,
        enabled = false;

  bool get isConfigured => type != ProxyType.none && host.isNotEmpty && port > 0;

  /// Format as environment variable value: `http://[user:pass@]host:port`
  String toEnvUrl() {
    if (!isConfigured) return '';
    final scheme = type == ProxyType.socks5 ? 'socks5' : 'http';
    final auth = (username != null && username!.isNotEmpty)
        ? '$username${password != null ? ':$password' : ''}@'
        : '';
    return '$scheme://$auth$host:$port';
  }

  /// Environment variables to inject when launching OpenClaw
  Map<String, String> toEnvVars() {
    if (!enabled || !isConfigured) return {};
    final url = toEnvUrl();
    return {
      'HTTP_PROXY': url,
      'HTTPS_PROXY': url,
      'http_proxy': url,
      'https_proxy': url,
    };
  }

  ProxyConfig copyWith({
    ProxyType? type,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? enabled,
  }) {
    return ProxyConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      enabled: enabled ?? this.enabled,
    );
  }

  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      type: _parseType(json['type'] as String?),
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      username: json['username'] as String?,
      password: json['password'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'host': host,
      'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      'enabled': enabled,
    };
  }

  static ProxyType _parseType(String? s) {
    return switch (s) {
      'http' => ProxyType.http,
      'socks5' => ProxyType.socks5,
      'system' => ProxyType.system,
      _ => ProxyType.none,
    };
  }
}
