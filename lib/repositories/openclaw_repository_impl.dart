import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/result.dart';
import '../core/service_status.dart';
import '../core/error_handler.dart';
import 'openclaw_repository.dart';

class OpenClawRepositoryImpl implements OpenClawRepository {
  final http.Client _httpClient;
  final int _defaultPort = 3000;

  OpenClawRepositoryImpl({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<Result<ServiceStatus>> getStatus() async {
    try {
      final isInstalled = await _checkInstalled();
      if (!isInstalled) {
        return Success(ServiceStatus(
          isRunning: false,
          isInstalled: false,
        ));
      }

      final version = await _getVersionString();
      final isRunning = await _checkRunning();

      return Success(ServiceStatus(
        isRunning: isRunning,
        isInstalled: true,
        version: version,
        webUrl: isRunning ? 'http://localhost:$_defaultPort' : '',
        port: _defaultPort,
      ));
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'getStatus');
      return Failure('获取服务状态失败', error: e, stackTrace: stack);
    }
  }

  @override
  Future<Result<void>> start() async {
    try {
      final result = await Process.run(
        'openclaw',
        ['start'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return const Success(null);
      } else {
        return Failure('启动失败: ${result.stderr}');
      }
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'start');
      return Failure('启动服务失败', error: e, stackTrace: stack);
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      final result = await Process.run(
        'openclaw',
        ['stop'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return const Success(null);
      } else {
        return Failure('停止失败: ${result.stderr}');
      }
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'stop');
      return Failure('停止服务失败', error: e, stackTrace: stack);
    }
  }

  @override
  Future<Result<bool>> isInstalled() async {
    try {
      final installed = await _checkInstalled();
      return Success(installed);
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'isInstalled');
      return Failure('检查安装状态失败', error: e, stackTrace: stack);
    }
  }

  @override
  Future<Result<String>> getVersion() async {
    try {
      final version = await _getVersionString();
      return Success(version);
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'getVersion');
      return Failure('获取版本失败', error: e, stackTrace: stack);
    }
  }

  @override
  Future<Result<void>> install() async {
    try {
      final result = await Process.run(
        'npm',
        ['install', '-g', '@openclaw/cli'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return const Success(null);
      } else {
        return Failure('安装失败: ${result.stderr}');
      }
    } catch (e, stack) {
      ErrorHandler.handle(e, stack, context: 'install');
      return Failure('安装OpenClaw失败', error: e, stackTrace: stack);
    }
  }

  // Private helper methods
  Future<bool> _checkInstalled() async {
    try {
      final result = await Process.run(
        'openclaw',
        ['--version'],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<String> _getVersionString() async {
    try {
      final result = await Process.run(
        'openclaw',
        ['--version'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return '';
  }

  Future<bool> _checkRunning() async {
    try {
      final uri = Uri.parse('http://localhost:$_defaultPort/health');
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
