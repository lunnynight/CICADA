import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/config_repository.dart';
import '../services/mcp_service.dart';
import '../services/proxy_service.dart';
import '../models/mcp_server.dart';
import '../models/proxy_config.dart';

/// Singleton ConfigRepository provider
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository();
});

/// Config data provider (auto-refreshable)
final configDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(configRepositoryProvider);
  final result = await repo.readConfig();
  return result.dataOrNull ?? {};
});

/// Configured provider IDs
final configuredProvidersProvider = FutureProvider<Set<String>>((ref) async {
  final config = await ref.watch(configDataProvider.future);
  final providers = config['providers'] as Map<String, dynamic>?;
  return providers?.keys.toSet() ?? {};
});

/// MCP servers list provider
final mcpServersProvider = FutureProvider<List<McpServer>>((ref) async {
  return McpService.getAll();
});

/// MCP enabled count
final mcpEnabledCountProvider = FutureProvider<int>((ref) async {
  final servers = await ref.watch(mcpServersProvider.future);
  return servers.where((s) => s.enabled).length;
});

/// Proxy config provider
final proxyConfigProvider = FutureProvider<ProxyConfig>((ref) async {
  return ProxyService.loadConfig();
});
