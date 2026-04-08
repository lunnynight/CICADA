import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/terminal_dialog.dart';
import '../services/config_service.dart';
import '../services/installer_service.dart';
import '../services/update_service.dart';
import '../services/integration_service.dart';
import '../services/proxy_service.dart';
import '../models/proxy_config.dart';
import 'settings_dialogs.dart';
import 'settings_proxy_section.dart';
import 'settings_integration_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _configPath = '';
  String _selectedMirror = 'https://registry.npmmirror.com';
  bool _checkingUpdate = false;
  UpdateInfo? _updateInfo;
  BackupInfo? _latestBackup;

  // Update progress
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;

  // Feishu integration state
  FeishuCredentials? _feishuCreds;

  // Proxy state
  ProxyConfig _proxyConfig = const ProxyConfig.disabled();
  bool _testingProxy = false;
  Map<String, ({bool ok, int latencyMs, String? error})>? _proxyTestResults;
  final _proxyHostCtrl = TextEditingController();
  final _proxyPortCtrl = TextEditingController();
  final _proxyUserCtrl = TextEditingController();
  final _proxyPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _proxyHostCtrl.dispose();
    _proxyPortCtrl.dispose();
    _proxyUserCtrl.dispose();
    _proxyPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '';
    final config = await ConfigService.readConfig();
    final feishuCreds = await FeishuService.getCredentials();
    final backup = await UpdateService.getLatestBackup();
    final proxyConfig = await ProxyService.loadConfig();
    if (!mounted) return;
    setState(() {
      _configPath = '$home/.openclaw/openclaw.json';
      _selectedMirror =
          config['npmMirror'] as String? ?? 'https://registry.npmmirror.com';
      _feishuCreds = feishuCreds;
      _latestBackup = backup;
      _proxyConfig = proxyConfig;
      _proxyHostCtrl.text = proxyConfig.host;
      _proxyPortCtrl.text = proxyConfig.port > 0 ? proxyConfig.port.toString() : '';
      _proxyUserCtrl.text = proxyConfig.username ?? '';
      _proxyPassCtrl.text = proxyConfig.password ?? '';
    });
  }

  Future<void> _saveMirror(String url) async {
    final config = await ConfigService.readConfig();
    config['npmMirror'] = url;
    await ConfigService.writeConfig(config);
    setState(() => _selectedMirror = url);
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateInfo = null;
    });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      setState(() => _updateInfo = info);
      if (!info.hasUpdate) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已是最新版本')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('检查更新失败: $e')));
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _downloadUpdate(String url) async {
    // Show risk confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildUpdateRiskDialog(ctx),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show backup confirmation
    final backupConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildBackupConfirmDialog(ctx),
    );

    if (backupConfirmed == null || !mounted) return; // Cancelled

    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
    });

    try {
      await UpdateService.downloadAndLaunch(
        url,
        createBackup: backupConfirmed,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );
      // Reload backup info after successful update
      await _loadSettings();
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadingUpdate = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  Widget _buildUpdateRiskDialog(BuildContext ctx) =>
      buildUpdateRiskDialog(ctx);

  Widget _buildBackupConfirmDialog(BuildContext ctx) =>
      buildBackupConfirmDialog(ctx);

  Future<void> _rollbackToBackup() async {
    if (_latestBackup == null || !_latestBackup!.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可用的备份')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: CicadaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CicadaColors.alert),
            ),
            icon: const Icon(
              Icons.restore,
              color: CicadaColors.alert,
              size: 48,
            ),
            title: const Text('回滚确认'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定要回滚到版本 ${_latestBackup!.version} 吗？'),
                const SizedBox(height: 8),
                Text(
                  '备份时间: ${_latestBackup!.backupTime.toLocal()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CicadaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '警告：回滚将恢复旧版本，当前版本的数据可能会丢失。',
                  style: TextStyle(color: CicadaColors.alert, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('确认回滚'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.alert,
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _downloadingUpdate = true);
    try {
      final success = await UpdateService.rollback(_latestBackup!);
      setState(() => _downloadingUpdate = false);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('回滚成功，请重启应用')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('回滚失败')));
      }
    } catch (e) {
      setState(() => _downloadingUpdate = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('回滚失败: $e')));
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: CicadaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CicadaColors.border),
            ),
            title: const Text('确认清理'),
            content: const Text('将清除所有已保存的 API Key 和设置，此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.alert,
                ),
                child: const Text('清理'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据已清理')));
    }
  }

  Future<void> _uninstallOpenClaw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: CicadaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CicadaColors.border),
            ),
            title: const Text('确认卸载'),
            content: const Text('将彻底卸载 OpenClaw CLI 工具，此操作不可恢复。您可以重新通过安装向导安装。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.alert,
                ),
                child: const Text('卸载'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Show terminal dialog for uninstall process
    final lines = ValueNotifier<List<String>>(['>>> 开始卸载 OpenClaw...']);
    final running = ValueNotifier<bool>(true);

    TerminalDialog.show(
      context,
      title: 'Uninstall OpenClaw',
      lines: lines,
      running: running,
    );

    try {
      final exitCode = await InstallerService.runInstallWithCallback(
        () => InstallerService.uninstallOpenClaw(),
        (line) {
          lines.value = [...lines.value, line];
        },
      );

      if (exitCode == 0) {
        lines.value = [...lines.value, '\n✓ OpenClaw 卸载成功'];
      } else {
        lines.value = [...lines.value, '\n✗ 卸载失败 (exit: $exitCode)'];
        lines.value = [...lines.value, '提示：可尝试以管理员身份运行'];
      }
    } catch (e) {
      lines.value = [...lines.value, '\n错误: $e'];
    } finally {
      running.value = false;
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
            'SETTINGS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('OpenClaw 配置', [
            _buildSettingRow(
              '配置文件路径',
              _configPath,
              trailing: IconButton(
                icon: const Icon(Icons.folder_open, size: 18),
                onPressed: () {
                  final dir = File(_configPath).parent.path;
                  if (Platform.isWindows) {
                    Process.run('explorer', [dir.replaceAll('/', '\\')]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', [dir]);
                  } else if (Platform.isLinux) {
                    Process.run('xdg-open', [dir]);
                  }
                },
                tooltip: '打开目录',
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('镜像源设置', [
            RadioGroup<String>(
              groupValue: _selectedMirror,
              onChanged: (v) {
                if (v != null) _saveMirror(v);
              },
              child: Column(
                children:
                    <String, String>{
                          '淘宝镜像': 'https://registry.npmmirror.com',
                          '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                          '华为镜像':
                              'https://repo.huaweicloud.com/repository/npm/',
                          '官方源': 'https://registry.npmjs.org',
                        }.entries
                        .map(
                          (e) => RadioListTile<String>(
                            title: Text(e.key),
                            subtitle: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: CicadaColors.textTertiary,
                              ),
                            ),
                            value: e.value,
                            dense: true,
                          ),
                        )
                        .toList(),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildProxySection(),
          const SizedBox(height: 24),
          _buildIntegrationSection(),
          const SizedBox(height: 24),
          _buildSection('关于', [
            _buildSettingRow('版本', '0.1.0'),
            _buildSettingRow('项目', 'Cicada (知了猴)'),
            ListTile(
              title: const Text('GitHub'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap:
                  () => launchUrl(
                    Uri.parse('https://github.com/2233admin/cicada'),
                  ),
            ),
            ListTile(
              title: const Text('检查更新'),
              trailing:
                  _checkingUpdate
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.system_update_outlined, size: 18),
              onTap: _checkingUpdate ? null : _checkForUpdate,
            ),
            if (_updateInfo != null && _updateInfo!.hasUpdate)
              _buildUpdateBanner(_updateInfo!),
          ]),
          const SizedBox(height: 24),
          _buildSection('数据管理', [
            if (_latestBackup != null && _latestBackup!.isValid)
              ListTile(
                title: const Text('回滚到上一版本'),
                subtitle: Text(
                  '备份版本: ${_latestBackup!.version} (${_latestBackup!.backupTime.toLocal().toString().split('.').first})',
                ),
                trailing: const Icon(Icons.restore, color: Colors.orange),
                onTap: _rollbackToBackup,
              ),
            ListTile(
              title: const Text(
                '清理所有数据',
                style: TextStyle(color: CicadaColors.alert),
              ),
              subtitle: const Text('删除所有已保存的 API Key 和设置'),
              trailing: const Icon(
                Icons.delete_outline,
                color: CicadaColors.alert,
              ),
              onTap: _clearData,
            ),
            ListTile(
              title: const Text(
                '卸载 OpenClaw',
                style: TextStyle(color: CicadaColors.alert),
              ),
              subtitle: const Text('卸载 OpenClaw CLI 工具'),
              trailing: const Icon(
                Icons.delete_forever,
                color: CicadaColors.alert,
              ),
              onTap: _uninstallOpenClaw,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner(UpdateInfo info) {
    return buildUpdateBanner(
      info: info,
      downloadingUpdate: _downloadingUpdate,
      downloadProgress: _downloadProgress,
      onDownload: _downloadUpdate,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CicadaColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {Widget? trailing}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
      ),
      trailing: trailing,
    );
  }

  // Proxy Settings Section
  Widget _buildProxySection() {
    return SettingsProxySection(
      proxyConfig: _proxyConfig,
      proxyHostCtrl: _proxyHostCtrl,
      proxyPortCtrl: _proxyPortCtrl,
      proxyUserCtrl: _proxyUserCtrl,
      proxyPassCtrl: _proxyPassCtrl,
      testingProxy: _testingProxy,
      proxyTestResults: _proxyTestResults,
      onProxyChanged: (config) => setState(() => _proxyConfig = config),
      onSave: _saveProxy,
      onTest: _testProxy,
    );
  }

  Future<void> _saveProxy() async {
    final host = _proxyHostCtrl.text.trim();
    final port = int.tryParse(_proxyPortCtrl.text.trim()) ?? 0;
    final user = _proxyUserCtrl.text.trim();
    final pass = _proxyPassCtrl.text.trim();

    final config = _proxyConfig.copyWith(
      host: host,
      port: port,
      username: user.isNotEmpty ? user : null,
      password: pass.isNotEmpty ? pass : null,
    );

    await ProxyService.saveConfig(config);
    setState(() => _proxyConfig = config);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('代理设置已保存')),
    );
  }

  Future<void> _testProxy() async {
    setState(() {
      _testingProxy = true;
      _proxyTestResults = null;
    });

    // Build config from current UI state
    final host = _proxyHostCtrl.text.trim();
    final port = int.tryParse(_proxyPortCtrl.text.trim()) ?? 0;
    final testConfig = _proxyConfig.copyWith(host: host, port: port, enabled: true);

    final results = await ProxyService.testApiEndpoints(proxy: testConfig);

    if (!mounted) return;
    setState(() {
      _testingProxy = false;
      _proxyTestResults = results;
    });
  }

  // Integration Management Section
  Widget _buildIntegrationSection() {
    return SettingsIntegrationSection(
      feishuCreds: _feishuCreds,
      onCredentialsChanged: _loadSettings,
    );
  }
}
