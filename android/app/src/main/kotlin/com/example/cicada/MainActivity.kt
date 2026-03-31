package com.example.cicada

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TERMUX_CHANNEL = "com.cicada/termux"
    private val A11Y_CHANNEL = "com.cicada/accessibility"
    private val TERMUX_PKG = "com.termux"
    private val TERMUX_RUN_COMMAND_SERVICE = "com.termux.app.RunCommandService"
    private val TERMUX_RUN_COMMAND_ACTION = "com.termux.RUN_COMMAND"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Termux bridge channel (existing)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TERMUX_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTermuxInstalled" -> handleIsTermuxInstalled(result)
                    "runCommand" -> handleRunCommand(call, result)
                    "openTermux" -> handleOpenTermux(result)
                    "openUrl" -> handleOpenUrl(call, result)
                    else -> result.notImplemented()
                }
            }

        // Accessibility service channel (new)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, A11Y_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> handleA11yIsEnabled(result)
                    "openSettings" -> handleA11yOpenSettings(result)
                    "isForegroundTermux" -> handleA11yIsForegroundTermux(result)
                    "inputText" -> handleA11yInputText(call, result)
                    "clickNodeByText" -> handleA11yClickNodeByText(call, result)
                    "captureHierarchy" -> handleA11yCaptureHierarchy(result)
                    else -> result.notImplemented()
                }
            }
    }

    // ── Termux handlers ──

    private fun handleIsTermuxInstalled(result: MethodChannel.Result) {
        try {
            packageManager.getPackageInfo(TERMUX_PKG, 0)
            result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(false)
        }
    }

    private fun handleRunCommand(call: MethodCall, result: MethodChannel.Result) {
        val command = call.argument<String>("command") ?: ""
        val args = call.argument<List<String>>("args") ?: emptyList()
        val background = call.argument<Boolean>("background") ?: false

        try {
            val intent = Intent(TERMUX_RUN_COMMAND_ACTION).apply {
                component = ComponentName(TERMUX_PKG, TERMUX_RUN_COMMAND_SERVICE)
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/$command")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", args.toTypedArray())
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
                putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
            }

            startService(intent)

            result.success(mapOf(
                "exitCode" to 0,
                "stdout" to "",
                "stderr" to ""
            ))
        } catch (e: Exception) {
            result.success(mapOf(
                "exitCode" to -1,
                "stdout" to "",
                "stderr" to (e.message ?: "Failed to send command to Termux")
            ))
        }
    }

    private fun handleOpenTermux(result: MethodChannel.Result) {
        try {
            val intent = packageManager.getLaunchIntentForPackage(TERMUX_PKG)
            if (intent != null) {
                startActivity(intent)
                result.success(null)
            } else {
                result.error("NOT_FOUND", "Termux not installed", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun handleOpenUrl(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url") ?: ""
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    // ── Accessibility handlers ──

    private fun handleA11yIsEnabled(result: MethodChannel.Result) {
        val serviceName = "${packageName}/${CicadaAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: ""
        val enabled = TextUtils.SimpleStringSplitter(':').run {
            setString(enabledServices)
            var found = false
            while (hasNext()) {
                if (next().equals(serviceName, ignoreCase = true)) {
                    found = true
                    break
                }
            }
            found
        }
        result.success(enabled)
    }

    private fun handleA11yOpenSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun handleA11yIsForegroundTermux(result: MethodChannel.Result) {
        val svc = CicadaAccessibilityService.instance
        if (svc == null) {
            result.success(false)
            return
        }
        result.success(svc.isForegroundTermux())
    }

    private fun handleA11yInputText(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text") ?: ""
        val svc = CicadaAccessibilityService.instance
        if (svc == null) {
            result.error("NOT_RUNNING", "Accessibility service not running", null)
            return
        }
        result.success(svc.inputText(text))
    }

    private fun handleA11yClickNodeByText(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text") ?: ""
        val svc = CicadaAccessibilityService.instance
        if (svc == null) {
            result.error("NOT_RUNNING", "Accessibility service not running", null)
            return
        }
        val coords = svc.findNodeByText(text)
        if (coords != null) {
            svc.click(coords.first, coords.second)
            result.success(mapOf("x" to coords.first, "y" to coords.second))
        } else {
            result.success(null)
        }
    }

    private fun handleA11yCaptureHierarchy(result: MethodChannel.Result) {
        val svc = CicadaAccessibilityService.instance
        if (svc == null) {
            result.error("NOT_RUNNING", "Accessibility service not running", null)
            return
        }
        result.success(svc.captureScreenHierarchy())
    }
}
