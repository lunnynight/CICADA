import 'dart:io';

import 'package:flutter/services.dart';

/// Bridge to CicadaAccessibilityService on Android.
/// Used for automated Termux configuration.
class AccessibilityBridge {
  static const _channel = MethodChannel('com.cicada/accessibility');

  /// Check if the accessibility service is enabled.
  static Future<bool> isEnabled() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>('isEnabled');
    return result ?? false;
  }

  /// Open system accessibility settings so user can enable the service.
  static Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openSettings');
  }

  /// Check if Termux is the foreground app.
  static Future<bool> isForegroundTermux() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>('isForegroundTermux');
    return result ?? false;
  }

  /// Input text into the currently focused field via accessibility.
  static Future<bool> inputText(String text) async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>(
      'inputText',
      {'text': text},
    );
    return result ?? false;
  }

  /// Find a UI node by text and click it. Returns coordinates if found.
  static Future<Map<String, int>?> clickNodeByText(String text) async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'clickNodeByText',
      {'text': text},
    );
    if (result == null) return null;
    return {
      'x': result['x'] as int,
      'y': result['y'] as int,
    };
  }

  /// Capture the current screen's UI hierarchy as text.
  static Future<String> captureHierarchy() async {
    if (!Platform.isAndroid) return '';
    final result = await _channel.invokeMethod<String>('captureHierarchy');
    return result ?? '';
  }
}
