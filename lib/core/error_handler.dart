import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ErrorHandler {
  /// Handle and log errors
  static void handle(Object error, StackTrace stackTrace, {String? context}) {
    final message = context != null ? '[$context] $error' : error.toString();

    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        name: 'Cicada',
      );
    }

    // TODO: Add Sentry integration for production
    // TODO: Add user-friendly error notifications
  }

  /// Convert exception to user-friendly message
  static String getUserMessage(Object error) {
    if (error is NetworkException) {
      return '网络连接失败，请检查网络设置';
    } else if (error is ConfigException) {
      return '配置文件错误：${error.message}';
    } else if (error is ServiceException) {
      return '服务异常：${error.message}';
    }
    return '操作失败，请重试';
  }
}

/// Custom exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ConfigException implements Exception {
  final String message;
  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}

class ServiceException implements Exception {
  final String message;
  ServiceException(this.message);

  @override
  String toString() => 'ServiceException: $message';
}
