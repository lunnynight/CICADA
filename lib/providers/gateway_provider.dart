import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/gateway_service.dart';
import '../services/config_service.dart';
import '../services/preset_service.dart';

/// Gateway running status (cached across page switches)
final gatewayStatusProvider = FutureProvider<bool>((ref) async {
  ref.keepAlive();
  return GatewayService.isRunning();
});

/// Active sessions list (cached, invalidate to refresh)
final gatewaySessionsProvider = FutureProvider<List<Session>>((ref) async {
  ref.keepAlive();
  return GatewayService.getSessions();
});

/// Model presets: merged CN + Intl models
final gatewayModelsProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  ref.keepAlive();
  final cn = await PresetService.loadCnModels();
  final intl = await PresetService.loadIntlModels();

  final result = <String, List<Map<String, dynamic>>>{};
  for (final entry in {...cn, ...intl}.entries) {
    if (entry.value is List) {
      result[entry.key] = (entry.value as List).cast<Map<String, dynamic>>();
    }
  }
  return result;
});

/// Current default provider ID from config
final currentProviderIdProvider = FutureProvider<String?>((ref) async {
  ref.keepAlive();
  final config = await ConfigService.readConfig();
  return config['defaultProvider'] as String?;
});

/// Configured provider map from config
final configuredProviderMapProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  final config = await ConfigService.readConfig();
  return (config['providers'] as Map<String, dynamic>?) ?? {};
});
