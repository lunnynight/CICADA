import '../core/app_error.dart';

/// Result type for operations that can fail with [AppError].
///
/// Usage:
/// ```dart
/// final result = await configRepo.readConfig();
/// switch (result) {
///   case Success(:final data): print(data);
///   case Failure(:final error): showError(error.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Get data or null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  /// Get error or null
  AppError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// Transform success data
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Success(transform(data)),
    Failure(:final error) => Failure(error),
  };

  /// Chain async operations
  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T data) transform) async {
    return switch (this) {
      Success(:final data) => transform(data),
      Failure(:final error) => Failure(error),
    };
  }

  /// Execute callback on success, return self for chaining
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success(:final data)) action(data);
    return this;
  }

  /// Execute callback on failure, return self for chaining
  Result<T> onFailure(void Function(AppError error) action) {
    if (this case Failure(:final error)) action(error);
    return this;
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
