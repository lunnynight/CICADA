import '../core/result.dart';
import '../core/service_status.dart';

/// Abstract repository for OpenClaw service operations
abstract class OpenClawRepository {
  /// Get current service status
  Future<Result<ServiceStatus>> getStatus();

  /// Start OpenClaw service
  Future<Result<void>> start();

  /// Stop OpenClaw service
  Future<Result<void>> stop();

  /// Check if OpenClaw is installed
  Future<Result<bool>> isInstalled();

  /// Get OpenClaw version
  Future<Result<String>> getVersion();

  /// Install OpenClaw via npm
  Future<Result<void>> install();
}
