import 'dart:io' show Platform;

/// Platform detection utilities for conditional behavior.
class PlatformInfo {
  PlatformInfo._();

  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Desktop can run Process.run directly
  static bool get canRunProcesses => isDesktop;

  /// Android needs Termux as Node.js runtime
  static bool get needsTermux => Platform.isAndroid;
}
