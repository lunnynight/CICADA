import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

import 'accessibility_bridge.dart';

/// Result of a Termux command execution.
class TermuxCommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const TermuxCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

/// Bridge to Termux via Android Intent (RUN_COMMAND).
///
/// On desktop, all methods throw [UnsupportedError].
/// On Android, communicates with Termux through MethodChannel → Kotlin → Intent.
class TermuxBridge {
  static const _channel = MethodChannel('com.cicada/termux');

  TermuxBridge._();

  static void _assertAndroid() {
    if (!Platform.isAndroid) {
      throw UnsupportedError('TermuxBridge is only available on Android');
    }
  }

  /// Check if Termux app is installed.
  static Future<bool> isTermuxInstalled() async {
    _assertAndroid();
    try {
      final result = await _channel.invokeMethod<bool>('isTermuxInstalled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Check if Node.js is installed inside Termux.
  static Future<bool> isNodeInstalled() async {
    final result = await runCommand('node', args: ['--version']);
    return result.isSuccess;
  }

  /// Check if OpenClaw is installed inside Termux.
  static Future<bool> isOpenClawInstalled() async {
    final result = await runCommand('openclaw', args: ['--version']);
    return result.isSuccess;
  }

  /// Execute a command inside Termux via RUN_COMMAND Intent.
  static Future<TermuxCommandResult> runCommand(
    String command, {
    List<String>? args,
    bool background = false,
  }) async {
    _assertAndroid();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'runCommand',
        {
          'command': command,
          'args': args ?? <String>[],
          'background': background,
        },
      );
      return TermuxCommandResult(
        exitCode: result?['exitCode'] as int? ?? -1,
        stdout: result?['stdout'] as String? ?? '',
        stderr: result?['stderr'] as String? ?? '',
      );
    } on PlatformException catch (e) {
      return TermuxCommandResult(
        exitCode: -1,
        stdout: '',
        stderr: e.message ?? 'Unknown error',
      );
    }
  }

  /// Start OpenClaw Gateway in Termux (background).
  static Future<TermuxCommandResult> startGateway() async {
    return runCommand('openclaw', args: ['gateway'], background: true);
  }

  /// Stop OpenClaw Gateway.
  static Future<TermuxCommandResult> stopGateway() async {
    return runCommand('openclaw', args: ['stop']);
  }

  /// Install Node.js in Termux via pkg.
  static Future<TermuxCommandResult> installNode() async {
    return runCommand('pkg', args: ['install', '-y', 'nodejs']);
  }

  /// Install OpenClaw in Termux via npm.
  static Future<TermuxCommandResult> installOpenClaw({
    String? mirrorUrl,
  }) async {
    final args = ['install', '-g', 'openclaw'];
    if (mirrorUrl != null) args.addAll(['--registry', mirrorUrl]);
    return runCommand('npm', args: args);
  }

  /// Configure Termux to allow external apps.
  /// Writes allow-external-apps=true to ~/.termux/termux.properties.
  static Future<TermuxCommandResult> configureExternalApps() async {
    return runCommand('bash', args: [
      '-c',
      'mkdir -p ~/.termux && '
          'grep -q "allow-external-apps" ~/.termux/termux.properties 2>/dev/null '
          '&& sed -i "s/.*allow-external-apps.*/allow-external-apps=true/" ~/.termux/termux.properties '
          '|| echo "allow-external-apps=true" >> ~/.termux/termux.properties',
    ]);
  }

  /// Open Termux app (for initial setup / granting permissions).
  static Future<void> openTermux() async {
    _assertAndroid();
    await _channel.invokeMethod<void>('openTermux');
  }

  /// Open URL in browser (for F-Droid download).
  static Future<void> openUrl(String url) async {
    _assertAndroid();
    await _channel.invokeMethod<void>('openUrl', {'url': url});
  }

  /// Auto-configure Termux via accessibility service.
  ///
  /// Opens Termux, waits for it to appear, then types the command to enable
  /// allow-external-apps. Returns a stream of status messages for UI feedback.
  static Stream<String> autoConfigureTermux() async* {
    _assertAndroid();

    // Step 1: Check accessibility service
    final a11yEnabled = await AccessibilityBridge.isEnabled();
    if (!a11yEnabled) {
      yield '需要开启无障碍服务';
      yield '正在打开无障碍设置...';
      await AccessibilityBridge.openSettings();
      // Wait for user to enable it
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (await AccessibilityBridge.isEnabled()) break;
        if (i == 29) {
          yield '超时：请手动开启 CICADA 无障碍服务后重试';
          return;
        }
      }
      yield '无障碍服务已启用';
    } else {
      yield '无障碍服务已启用';
    }

    // Step 2: Open Termux
    yield '正在启动 Termux...';
    await openTermux();

    // Step 3: Wait for Termux to be foreground
    for (var i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (await AccessibilityBridge.isForegroundTermux()) break;
      if (i == 14) {
        yield '超时：Termux 未能启动，请手动打开 Termux 后重试';
        return;
      }
    }
    yield 'Termux 已启动';

    // Step 4: Wait a moment for Termux terminal to be ready
    await Future.delayed(const Duration(seconds: 2));

    // Step 5: Type the configuration command
    yield '正在输入配置命令...';
    const cmd =
        'mkdir -p ~/.termux && echo "allow-external-apps=true" >> ~/.termux/termux.properties && termux-reload-settings';
    final typed = await AccessibilityBridge.inputText(cmd);
    if (!typed) {
      yield '无法输入文本，请手动在 Termux 中执行以下命令：';
      yield cmd;
      return;
    }

    // Step 6: Brief pause then verify
    await Future.delayed(const Duration(seconds: 2));
    yield '配置命令已输入';
    yield '请确认 Termux 中命令已执行（按回车）';
    yield '完成后点击"重新检测"验证配置';
  }
}
