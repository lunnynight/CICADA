import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/installer_service.dart';
import '../services/config_service.dart';
import '../widgets/terminal_output.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<bool>? onServiceStatusChanged;

  const DashboardPage({super.key, this.onServiceStatusChanged});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _nodeVersion = '检测中...';
  String _openclawVersion = '检测中...';
  bool _serviceRunning = false;
  bool _actionLoading = false;
  Set<String> _configuredProviders = {};
  Timer? _pollTimer;
  final List<String> _serviceLog = [];

  @override
  void initState() {
    super.initState();
    _detectEnvironment();
    _loadConfiguredProviders();
    _checkServiceStatus();
    // Poll service status every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkServiceStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _detectEnvironment() async {
    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    if (!mounted) return;
    setState(() {
      _nodeVersion = nodeResult.exitCode == 0
          ? (nodeResult.stdout as String).trim()
          : '未安装';
      _openclawVersion = clawResult.exitCode == 0
          ? (clawResult.stdout as String).trim()
          : '未安装';
    });
  }

  Future<void> _loadConfiguredProviders() async {
    final configured = await ConfigService.getConfiguredProviders();
    if (!mounted) return;
    setState(() => _configuredProviders = configured);
  }

  Future<void> _checkServiceStatus() async {
    final running = await InstallerService.isServiceRunning();
    if (!mounted) return;
    if (running != _serviceRunning) {
      setState(() => _serviceRunning = running);
      widget.onServiceStatusChanged?.call(running);
    }
  }

  Future<void> _toggleService() async {
    setState(() {
      _actionLoading = true;
      _serviceLog.clear();
    });
    try {
      ProcessResult result;
      if (_serviceRunning) {
        setState(() => _serviceLog.add('>>> 正在停止服务...'));
        result = await InstallerService.stopService();
      } else {
        setState(() => _serviceLog.add('>>> 正在启动服务...'));
        result = await InstallerService.startService();
      }

      if (!mounted) return;
      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();
      if (stdout.isNotEmpty) setState(() => _serviceLog.add(stdout));
      if (stderr.isNotEmpty) setState(() => _serviceLog.add(stderr));

      if (result.exitCode == 0) {
        setState(() => _serviceLog.add(_serviceRunning ? '✓ 服务已停止' : '✓ 服务已启动'));
        // Wait a moment then check actual status
        await Future.delayed(const Duration(seconds: 2));
        await _checkServiceStatus();
      } else {
        setState(() => _serviceLog.add('✗ 操作失败 (exit: ${result.exitCode})'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _serviceLog.add('错误: $e'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '仪表盘',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildServiceCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildEnvCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildModelsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickActionsCard()),
            ],
          ),
          if (_serviceLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('服务日志', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TerminalOutput(lines: _serviceLog, height: 150),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud, size: 20),
                SizedBox(width: 8),
                Text(
                  'OpenClaw 服务状态',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _serviceRunning ? Colors.green : Colors.red,
                    boxShadow: _serviceRunning
                        ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceRunning ? '运行中' : '已停止',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _serviceRunning ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                if (_serviceRunning)
                  Text('http://127.0.0.1:18789',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _actionLoading ? null : _toggleService,
                icon: _actionLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_serviceRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_serviceRunning ? '停止服务' : '启动服务'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _serviceRunning ? Colors.red[700] : const Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  '环境信息',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _envRow('Node.js', _nodeVersion),
            const SizedBox(height: 8),
            _envRow('OpenClaw', _openclawVersion),
            const SizedBox(height: 8),
            _envRow('配置文件', ConfigService.configPath),
            const SizedBox(height: 8),
            _envRow('操作系统', Platform.operatingSystemVersion),
          ],
        ),
      ),
    );
  }

  Widget _envRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400])),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildModelsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy, size: 20),
                SizedBox(width: 8),
                Text(
                  '已配置模型',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_configuredProviders.isEmpty)
              Text('暂未配置任何模型', style: TextStyle(color: Colors.grey[500]))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _configuredProviders
                    .map(
                      (p) => Chip(
                        label: Text(p),
                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        backgroundColor: const Color(0xFF0D1117),
                        side: const BorderSide(color: Color(0xFF30363D)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, size: 20),
                SizedBox(width: 8),
                Text(
                  '快捷操作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _serviceRunning
                    ? () => launchUrl(Uri.parse('http://127.0.0.1:18789/'))
                    : null,
                icon: const Icon(Icons.open_in_browser),
                label: Text(_serviceRunning ? '打开 OpenClaw 面板' : '启动服务后可打开面板'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (Platform.isWindows) {
                    Process.run('cmd', ['/c', 'start', 'cmd']);
                  }
                },
                icon: const Icon(Icons.terminal),
                label: const Text('打开终端'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final dir = ConfigService.configDir;
                  if (Platform.isWindows) {
                    Process.run('explorer', [dir.replaceAll('/', '\\')]);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('打开配置目录'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
