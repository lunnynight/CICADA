import '../core/result.dart';
import '../core/service_status.dart';

/// Abstract repository for environment checks
abstract class EnvironmentRepository {
  /// Check Node.js installation
  Future<Result<bool>> isNodeInstalled();

  /// Get Node.js version
  Future<Result<String>> getNodeVersion();

  /// Install Node.js
  Future<Result<void>> installNode();

  /// Check Ollama installation
  Future<Result<bool>> isOllamaInstalled();

  /// Get available Ollama models
  Future<Result<List<String>>> getOllamaModels();

  /// Get complete environment status
  Future<Result<EnvironmentStatus>> getEnvironmentStatus();
}
