import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../core/result.dart';

// Config Service Provider
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});

// Config State Provider
final configProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ConfigService.readConfig();
});

// Configured Providers List
final configuredProvidersProvider = FutureProvider<List<String>>((ref) async {
  return await ConfigService.getConfiguredProviders();
});

// Provider Actions
class ConfigActions {
  final Ref ref;

  ConfigActions(this.ref);

  Future<Result<void>> setProvider({
    required String providerId,
    required String apiKey,
    required String apiBase,
    required String defaultModel,
  }) async {
    try {
      await ConfigService.setProvider(
        providerId: providerId,
        apiKey: apiKey,
        apiBase: apiBase,
        defaultModel: defaultModel,
      );
      // Invalidate config cache
      ref.invalidate(configProvider);
      ref.invalidate(configuredProvidersProvider);
      return const Success(null);
    } catch (e, stack) {
      return Failure('保存配置失败', error: e, stackTrace: stack);
    }
  }

  Future<Result<void>> removeProvider(String providerId) async {
    try {
      await ConfigService.removeProvider(providerId);
      ref.invalidate(configProvider);
      ref.invalidate(configuredProvidersProvider);
      return const Success(null);
    } catch (e, stack) {
      return Failure('删除配置失败', error: e, stackTrace: stack);
    }
  }

  Future<Result<bool>> testConnection({
    required String apiBase,
    required String apiKey,
    required String model,
  }) async {
    try {
      final result = await ConfigService.testConnection(
        apiBase: apiBase,
        apiKey: apiKey,
        model: model,
      );
      return Success(result);
    } catch (e, stack) {
      return Failure('连接测试失败', error: e, stackTrace: stack);
    }
  }
}

final configActionsProvider = Provider<ConfigActions>((ref) {
  return ConfigActions(ref);
});
