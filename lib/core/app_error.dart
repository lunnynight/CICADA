sealed class AppError {
  String get message;
  String get code;
  Object? get cause;

  const AppError();

  @override
  String toString() => '[$code] $message';
}

class ConfigError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const ConfigError({
    required this.message,
    this.code = 'CONFIG_ERROR',
    this.cause,
  });

  const ConfigError.readFailed({this.cause})
      : message = '无法读取配置文件',
        code = 'CONFIG_READ_FAILED';

  const ConfigError.writeFailed({this.cause})
      : message = '无法写入配置文件',
        code = 'CONFIG_WRITE_FAILED';

  const ConfigError.parseFailed({this.cause})
      : message = '配置文件格式错误',
        code = 'CONFIG_PARSE_FAILED';

  const ConfigError.notFound()
      : message = '配置文件不存在',
        code = 'CONFIG_NOT_FOUND',
        cause = null;
}

class NetworkError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const NetworkError({
    required this.message,
    this.code = 'NETWORK_ERROR',
    this.cause,
  });

  const NetworkError.timeout({this.cause})
      : message = '网络连接超时，请检查网络设置',
        code = 'NETWORK_TIMEOUT';

  const NetworkError.unreachable({required String endpoint, this.cause})
      : message = '无法连接到 $endpoint',
        code = 'NETWORK_UNREACHABLE';

  const NetworkError.proxyFailed({this.cause})
      : message = '代理连接失败，请检查代理设置',
        code = 'NETWORK_PROXY_FAILED';
}

class AuthError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const AuthError({
    required this.message,
    this.code = 'AUTH_ERROR',
    this.cause,
  });

  const AuthError.invalidKey({this.cause})
      : message = 'API Key 无效，请检查后重试',
        code = 'AUTH_INVALID_KEY';

  const AuthError.expired({this.cause})
      : message = 'API Key 已过期',
        code = 'AUTH_EXPIRED';

  const AuthError.rateLimited({this.cause})
      : message = '请求过于频繁，请稍后再试',
        code = 'AUTH_RATE_LIMITED';
}

class InstallError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const InstallError({
    required this.message,
    this.code = 'INSTALL_ERROR',
    this.cause,
  });

  const InstallError.nodeMissing()
      : message = 'Node.js 未安装，请先完成安装向导',
        code = 'INSTALL_NODE_MISSING',
        cause = null;

  const InstallError.openclawFailed({this.cause})
      : message = 'OpenClaw 安装失败',
        code = 'INSTALL_OPENCLAW_FAILED';

  const InstallError.extractFailed({this.cause})
      : message = '离线包解压失败',
        code = 'INSTALL_EXTRACT_FAILED';

  const InstallError.permissionDenied({this.cause})
      : message = '权限不足，请以管理员身份运行',
        code = 'INSTALL_PERMISSION_DENIED';
}

class ServiceError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const ServiceError({
    required this.message,
    this.code = 'SERVICE_ERROR',
    this.cause,
  });

  const ServiceError.notRunning()
      : message = 'OpenClaw 服务未运行，请先启动服务',
        code = 'SERVICE_NOT_RUNNING',
        cause = null;

  const ServiceError.startFailed({this.cause})
      : message = 'OpenClaw 服务启动失败',
        code = 'SERVICE_START_FAILED';

  const ServiceError.connectionLost({this.cause})
      : message = '与 OpenClaw 服务的连接已断开',
        code = 'SERVICE_CONNECTION_LOST';
}

class ValidationError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final Object? cause;

  const ValidationError({
    required this.message,
    this.code = 'VALIDATION_ERROR',
    this.cause,
  });

  const ValidationError.emptyField({required String field})
      : message = '$field 不能为空',
        code = 'VALIDATION_EMPTY',
        cause = null;

  const ValidationError.invalidFormat({required String field, this.cause})
      : message = '$field 格式不正确',
        code = 'VALIDATION_FORMAT';

  const ValidationError.invalidUrl({this.cause})
      : message = 'URL 格式不正确',
        code = 'VALIDATION_URL';
}
