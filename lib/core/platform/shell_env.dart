import 'dart:io';

/// Resolves the user's real PATH on macOS.
///
/// macOS GUI apps launched from Finder inherit a minimal PATH
/// (`/usr/bin:/bin:/usr/sbin:/sbin`) that excludes Homebrew, nvm,
/// npm globals, etc. This class obtains the real PATH from a login
/// shell and caches it for the lifetime of the process.
class ShellEnv {
  static Map<String, String>? _cached;

  /// Returns an environment map with the user's real PATH on macOS.
  /// Returns `null` on other platforms (use default inherited env).
  static Future<Map<String, String>?> getEnv() async {
    if (!Platform.isMacOS) return null;
    if (_cached != null) return _cached;

    // Primary: ask a login shell for the real PATH.
    // Markers avoid contamination from .zshrc echo/motd output.
    try {
      final result = await Process.run(
        '/bin/zsh',
        ['-ilc', r'echo "___CICADA_PATH___$PATH___CICADA_PATH___"'],
      );
      if (result.exitCode == 0) {
        final stdout = result.stdout as String;
        final match = RegExp(r'___CICADA_PATH___(.*?)___CICADA_PATH___')
            .firstMatch(stdout);
        if (match != null) {
          final realPath = match.group(1)!.trim();
          if (realPath.isNotEmpty) {
            _cached = {...Platform.environment, 'PATH': realPath};
            return _cached;
          }
        }
      }
    } catch (_) {}

    // Fallback: manually prepend common macOS paths.
    final home = Platform.environment['HOME'] ?? '';
    final fallback = [
      '/opt/homebrew/bin',
      '/opt/homebrew/sbin',
      '/usr/local/bin',
      '/usr/local/sbin',
      '$home/.local/bin',
      '$home/.npm-global/bin',
      '$home/.bun/bin',
      Platform.environment['PATH'] ?? '',
    ].where((p) => p.isNotEmpty).join(':');

    _cached = {...Platform.environment, 'PATH': fallback};
    return _cached;
  }

  /// Clear cached env (for testing).
  static void clearCache() => _cached = null;
}
