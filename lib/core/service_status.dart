import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_status.freezed.dart';
part 'service_status.g.dart';

@freezed
class ServiceStatus with _$ServiceStatus {
  const factory ServiceStatus({
    required bool isRunning,
    required bool isInstalled,
    @Default('') String version,
    @Default('') String webUrl,
    @Default(0) int port,
  }) = _ServiceStatus;

  factory ServiceStatus.fromJson(Map<String, dynamic> json) =>
      _$ServiceStatusFromJson(json);
}

@freezed
class EnvironmentStatus with _$EnvironmentStatus {
  const factory EnvironmentStatus({
    required bool nodeInstalled,
    required bool openclawInstalled,
    required bool ollamaInstalled,
    @Default('') String nodeVersion,
    @Default('') String openclawVersion,
    @Default([]) List<String> ollamaModels,
  }) = _EnvironmentStatus;

  factory EnvironmentStatus.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentStatusFromJson(json);
}
