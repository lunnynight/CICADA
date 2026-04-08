import 'dart:io';

/// Abstract interface for running shell processes.
/// Production code uses [RealProcessRunner]; tests use [FakeProcessRunner].
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
    Map<String, String>? environment,
  });
}

/// Default implementation that delegates to [Process.run].
class RealProcessRunner implements ProcessRunner {
  const RealProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
    Map<String, String>? environment,
  }) =>
      Process.run(
        executable,
        arguments,
        runInShell: runInShell,
        environment: environment,
      );
}

/// Fake for tests: returns pre-configured results by command key.
class FakeProcessRunner implements ProcessRunner {
  final Map<String, ProcessResult> _results;

  FakeProcessRunner(this._results);

  /// Key format: "$executable ${arguments.join(' ')}"
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
    Map<String, String>? environment,
  }) async {
    final key = '$executable ${arguments.join(' ')}';
    return _results[key] ??
        ProcessResult(0, 1, '', 'FakeProcessRunner: no stub for "$key"');
  }
}
