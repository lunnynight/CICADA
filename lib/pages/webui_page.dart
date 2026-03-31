import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/theme/cicada_colors.dart';
import '../services/installer_service.dart';

/// Embedded WebView container for OpenClaw WebUI.
///
/// Loads http://127.0.0.1:18789 with custom navigation bar,
/// loading state, and error handling when OpenClaw is not running.
class WebUIPage extends StatefulWidget {
  const WebUIPage({super.key});

  @override
  State<WebUIPage> createState() => _WebUIPageState();
}

class _WebUIPageState extends State<WebUIPage> {
  static const _openclawUrl = 'http://127.0.0.1:18789';

  WebViewController? _controller;
  bool _loading = true;
  bool _serviceRunning = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentUrl = _openclawUrl;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    final running = await InstallerService.isServiceRunning();
    if (!mounted) return;

    setState(() => _serviceRunning = running);

    if (running) {
      _initWebView();
    } else {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'OpenClaw 服务未运行';
      });
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (url) {
          if (mounted) {
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
          }
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _loading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(_openclawUrl));

    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNavBar(),
        const Divider(height: 1, color: CicadaColors.border),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 44,
      color: CicadaColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: CicadaColors.textSecondary,
            onPressed: () => _controller?.goBack(),
            tooltip: '后退',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 18),
            color: CicadaColors.textSecondary,
            onPressed: () => _controller?.goForward(),
            tooltip: '前进',
          ),
          IconButton(
            icon: Icon(
              _loading ? Icons.close : Icons.refresh,
              size: 18,
            ),
            color: CicadaColors.textSecondary,
            onPressed: () {
              if (_loading) {
                // Can't easily stop loading in webview_flutter
              } else {
                _controller?.reload();
              }
            },
            tooltip: _loading ? '停止' : '刷新',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: CicadaColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CicadaColors.border),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                _currentUrl,
                style: const TextStyle(
                  fontSize: 11,
                  color: CicadaColors.textTertiary,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _serviceRunning ? CicadaColors.ok : CicadaColors.error,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError || !_serviceRunning) {
      return _buildErrorState();
    }

    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: CicadaColors.data),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(CicadaColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _serviceRunning ? Icons.error_outline : Icons.power_off,
            size: 64,
            color: CicadaColors.border,
          ),
          const SizedBox(height: 16),
          Text(
            _serviceRunning ? '页面加载失败' : 'OpenClaw 服务未运行',
            style: const TextStyle(
              fontSize: 18,
              color: CicadaColors.textSecondary,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _serviceRunning
                ? _errorMessage
                : '请先在仪表盘启动 OpenClaw 服务',
            style: const TextStyle(
              fontSize: 13,
              color: CicadaColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _checkAndLoad,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CicadaColors.accent,
              side: const BorderSide(color: CicadaColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
