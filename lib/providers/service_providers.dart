import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/openclaw_repository.dart';
import '../repositories/openclaw_repository_impl.dart';
import '../repositories/environment_repository.dart';
import '../core/service_status.dart';
import '../core/result.dart';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Repository Providers
final openclawRepositoryProvider = Provider<OpenClawRepository>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return OpenClawRepositoryImpl(httpClient: httpClient);
});

final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  throw UnimplementedError('EnvironmentRepository not implemented yet');
});

// Service Status Provider (auto-refresh every 5 seconds)
final serviceStatusProvider = StreamProvider<ServiceStatus>((ref) async* {
  final repository = ref.watch(openclawRepositoryProvider);

  while (true) {
    final result = await repository.getStatus();
    yield result.when(
      success: (status) => status,
      failure: (_) => const ServiceStatus(
        isRunning: false,
        isInstalled: false,
      ),
    );
    await Future.delayed(const Duration(seconds: 5));
  }
});

// Service Control Providers
final startServiceProvider = FutureProvider.autoDispose<Result<void>>((ref) async {
  final repository = ref.watch(openclawRepositoryProvider);
  return await repository.start();
});

final stopServiceProvider = FutureProvider.autoDispose<Result<void>>((ref) async {
  final repository = ref.watch(openclawRepositoryProvider);
  return await repository.stop();
});

// Manual refresh trigger
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

final manualServiceStatusProvider = FutureProvider<ServiceStatus>((ref) async {
  // Watch refresh trigger to invalidate cache
  ref.watch(refreshTriggerProvider);

  final repository = ref.watch(openclawRepositoryProvider);
  final result = await repository.getStatus();

  return result.when(
    success: (status) => status,
    failure: (_) => const ServiceStatus(
      isRunning: false,
      isInstalled: false,
    ),
  );
});
