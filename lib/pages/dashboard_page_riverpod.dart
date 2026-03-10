import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/service_providers.dart';
import '../providers/config_providers.dart';
import '../services/config_service.dart';
import '../widgets/terminal_output.dart';
import '../core/service_status.dart';

class DashboardPageNew extends ConsumerStatefulWidget {
  final ValueChanged<bool>? onServiceStatusChanged;

  const DashboardPageNew({super.key, this.onServiceStatusChanged});

  @override
  ConsumerState<DashboardPageNew> createState() => _DashboardPageNewState();
}

class _DashboardPageNewState extends ConsumerState<DashboardPageNew> {
  bool _actionLoading = false;
  final List<String> _serviceLog = [];

  Future<void> _toggleService(ServiceStatus currentStatus) async {
    setState(() {
      _actionLoading = true;
      _serviceLog.clear();
    });

    try {
      final repository = ref.read(openclawRepositoryProvider);

      if (currentStatus.isRunning) {
        setState(() => _serviceLog.add('>>> 正在停止服务...'));
        final result = await repository.stop();

        result.when(
          success: (_) {
            setState(() => _serviceLog.add('✓ 服务已停止'));
            // Refresh status
            ref.invalidate(serviceStatusProvider);
          },
          failure: (message) {
            setState(() => _serviceLog.add('✗ 停止失败: $message'));
          },
        );
      } else {
        setState(() => _serviceLog.add('>>> 正在启动服务...'));
        final result = await repository.start();

        result.when(
          success: (_) {
            setState(() => _serviceLog.add('✓ 服务已启动'));
            // Refresh status
            ref.invalidate(serviceStatusProvider);
          },
          failure: (message) {
            setState(() => _serviceLog.add('✗ 启动失败: $message'));
          },
        );
      }
    } catch (e) {
      setState(() => _serviceLog.add('错误: $e'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceStatusAsync = ref.watch(serviceStatusProvider);
    final configuredProvidersAsync = ref.watch(configuredProvidersProvider);

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
              Expanded(
                child: serviceStatusAsync.when(
                  data: (status) => _buildServiceCard(status),
                  loading: () => _buildLoadingCard('服务状态'),
                  error: (err, stack) => _buildErrorCard('服务状态', err.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: serviceStatusAsync.when(
                  data: (status) => _buildEnvCard(status),
                  loading: () => _buildLoadingCard('环境信息'),
                  error: (err, stack) => _buildErrorCard('环境信息', err.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: configuredProvidersAsync.when(
                  data: (providers) => _buildModelsCard(providers),
                  loading: () => _buildLoadingCard('已配置模型'),
                  error: (err, stack) => _buildErrorCard('已配置模型', err.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: serviceStatusAsync.when(
                  data: (status) => _buildQuickActionsCard(status),
                  loading: () => _buildLoadingCard('快捷操作'),
                  error: (err, stack) => _buildErrorCard('快捷操作', err.toString()),
                ),
              ),
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

  Widget _buildLoadingCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String error) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('错误: $error', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceStatus status) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onServiceStatusChanged?.call(status.isRunning);
    });

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
                Text('OpenClaw 服务状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.isRunning ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.isRunning ? '运行中' : '已停止',
                  style: TextStyle(
                    color: status.isRunning ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : () => _toggleService(status),
                icon: _actionLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(status.isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_actionLoading ? '处理中...' : (status.isRunning ? '停止服务' : '启动服务')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status.isRunning ? Colors.red : const Color(0xFF7C3AED),
                ),
              ),
            ),
            if (status.isRunning && status.webUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(status.webUrl)),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('打开 Web UI'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF30363D))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvCard(ServiceStatus status) {
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
                Icon(Icons.settings, size: 20),
                SizedBox(width: 8),
                Text('环境信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('OpenClaw', status.isInstalled ? status.version : '未安装'),
            const SizedBox(height: 8),
            _buildInfoRow('端口', status.port > 0 ? status.port.toString() : '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsCard(List<String> providers) {
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
                Icon(Icons.psychology, size: 20),
                SizedBox(width: 8),
                Text('已配置模型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            if (providers.isEmpty)
              const Text('暂无配置', style: TextStyle(color: Colors.grey))
            else
              ...providers.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(p),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ServiceStatus status) {
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
                Text('快捷操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
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
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF30363D))),
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
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF30363D))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
