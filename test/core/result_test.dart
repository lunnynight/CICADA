import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/core/result.dart';
import 'package:cicada/core/app_error.dart';

void main() {
  group('Result.isSuccess / isFailure', () {
    test('Success.isSuccess is true', () {
      const result = Success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
    });

    test('Failure.isFailure is true', () {
      final result = Failure<int>(const ConfigError.notFound());
      expect(result.isFailure, true);
      expect(result.isSuccess, false);
    });
  });

  group('Result.dataOrNull / errorOrNull', () {
    test('Success.dataOrNull returns data', () {
      const result = Success('hello');
      expect(result.dataOrNull, 'hello');
      expect(result.errorOrNull, isNull);
    });

    test('Failure.errorOrNull returns error', () {
      const error = ConfigError.readFailed();
      final result = Failure<String>(error);
      expect(result.errorOrNull, error);
      expect(result.dataOrNull, isNull);
    });
  });

  group('Result.map', () {
    test('Success.map transforms data', () {
      const result = Success(21);
      final mapped = result.map((v) => v * 2);
      expect(mapped, isA<Success<int>>());
      expect((mapped as Success<int>).data, 42);
    });

    test('Failure.map returns Failure unchanged', () {
      const error = ConfigError.notFound();
      final result = Failure<int>(error);
      final mapped = result.map((v) => v * 2);
      expect(mapped, isA<Failure<int>>());
      expect((mapped as Failure<int>).error, error);
    });

    test('map can change type', () {
      const result = Success(42);
      final mapped = result.map((v) => v.toString());
      expect(mapped, isA<Success<String>>());
      expect((mapped as Success<String>).data, '42');
    });
  });

  group('Result.flatMap', () {
    test('Success.flatMap chains to another Success', () async {
      const result = Success(10);
      final chained = await result.flatMap((v) async => Success(v + 5));
      expect(chained, isA<Success<int>>());
      expect((chained as Success<int>).data, 15);
    });

    test('Success.flatMap can chain to Failure', () async {
      const result = Success(10);
      final chained = await result.flatMap<int>(
        (v) async => Failure(const ConfigError.notFound()),
      );
      expect(chained, isA<Failure<int>>());
    });

    test('Failure.flatMap is not called, returns Failure', () async {
      var called = false;
      final result = Failure<int>(const ConfigError.notFound());
      final chained = await result.flatMap<int>((v) async {
        called = true;
        return Success(v);
      });
      expect(called, false);
      expect(chained, isA<Failure<int>>());
    });
  });

  group('Result.onSuccess', () {
    test('callback invoked for Success', () {
      var received = 0;
      const result = Success(99);
      result.onSuccess((v) => received = v);
      expect(received, 99);
    });

    test('callback not invoked for Failure', () {
      var called = false;
      final result = Failure<int>(const ConfigError.notFound());
      result.onSuccess((_) => called = true);
      expect(called, false);
    });

    test('returns self for chaining', () {
      const result = Success(1);
      final returned = result.onSuccess((_) {});
      expect(identical(result, returned), true);
    });
  });

  group('Result.onFailure', () {
    test('callback invoked for Failure', () {
      AppError? received;
      const error = ConfigError.readFailed();
      final result = Failure<int>(error);
      result.onFailure((e) => received = e);
      expect(received, error);
    });

    test('callback not invoked for Success', () {
      var called = false;
      const result = Success(1);
      result.onFailure((_) => called = true);
      expect(called, false);
    });
  });

  group('Result pattern matching', () {
    test('switch on Success extracts value', () {
      const Result<int> result = Success(42);
      final output = switch (result) {
        Success(:final data) => 'success:$data',
        Failure(:final error) => 'failure:${error.code}',
      };
      expect(output, 'success:42');
    });

    test('switch on Failure extracts error', () {
      final Result<int> result = Failure(const ConfigError.notFound());
      final output = switch (result) {
        Success(:final data) => 'success:$data',
        Failure(:final error) => 'failure:${error.code}',
      };
      expect(output, 'failure:CONFIG_NOT_FOUND');
    });
  });
}
