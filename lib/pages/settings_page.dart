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
  bool _testingFeishu = false;
  bool _showFeishuConfig = false;
  final _feishuAppIdCtrl = TextEditingController();
  final _feishuSecretCtrl = TextEditingController();
  final _feishuWebhookCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _feishuAppIdCtrl.dispose();
    _feishuSecretCtrl.dispose();
    _feishuWebhookCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    final config = await ConfigService.readConfig();
    final feishuCreds = await FeishuService.getCredentials();
    final backup = await UpdateService.getLatestBackup();
    if (!mounted) return;
    setState(() {
      _configPath = '$home/.openclaw/openclaw.json';
      _selectedMirror = config['npmMirror'] as String? ?? 'https://registry.npmmirror.com';
      _feishuCreds = feishuCreds;
      _latestBackup = backup;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已是最新版本')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  Widget _buildUpdateRiskDialog(BuildContext ctx) {
    return AlertDialog(
      backgroundColor: CicadaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CicadaColors.alert),
      ),
      icon: const Icon(Icons.warning_amber, color: CicadaColors.alert, size: 48),
      title: const Text('更新风险提示'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '软件更新存在以下风险，请谨慎操作：',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildRiskItem('更新过程中可能出现意外中断，导致软件无法启动'),
          _buildRiskItem('新版本可能与现有配置不兼容'),
          _buildRiskItem('网络问题可能导致更新文件损坏'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CicadaColors.alert.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CicadaColors.alert.withAlpha(100)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: CicadaColors.alert, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '建议：更新前创建备份，以便在出现问题时回滚',
                    style: TextStyle(color: CicadaColors.alert, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消更新'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.warning, size: 16),
          label: const Text('我已了解风险，继续更新'),
          style: FilledButton.styleFrom(
            backgroundColor: CicadaColors.alert,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: CicadaColors.alert)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupConfirmDialog(BuildContext ctx) {
    return AlertDialog(
      backgroundColor: CicadaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CicadaColors.border),
      ),
      title: const Text('备份确认'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('是否在更新前创建备份？'),
          SizedBox(height: 8),
          Text(
            '备份后可以在更新失败时恢复到当前版本。',
            style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('不备份'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.backup, size: 16),
          label: const Text('创建备份并更新'),
          style: FilledButton.styleFrom(
            backgroundColor: CicadaColors.ok,
          ),
        ),
      ],
    );
  }

  Future<void> _rollbackToBackup() async {
    if (_latestBackup == null || !_latestBackup!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的备份')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CicadaColors.alert),
        ),
        icon: const Icon(Icons.restore, color: CicadaColors.alert, size: 48),
        title: const Text('回滚确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要回滚到版本 ${_latestBackup!.version} 吗？'),
            const SizedBox(height: 8),
            Text(
              '备份时间: ${_latestBackup!.backupTime.toLocal()}',
              style: const TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回滚成功，请重启应用')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回滚失败')),
        );
      }
    } catch (e) {
      setState(() => _downloadingUpdate = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('回滚失败: $e')),
      );
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CicadaColors.border),
        ),
        title: const Text('确认清理'),
        content: const Text('将清除所有已保存的 API Key 和设置，此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CicadaColors.alert),
            child: const Text('清理'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据已清理')),
      );
    }
  }

  Future<void> _uninstallOpenClaw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CicadaColors.border),
        ),
        title: const Text('确认卸载'),
        content: const Text('将彻底卸载 OpenClaw CLI 工具，此操作不可恢复。您可以重新通过安装向导安装。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CicadaColors.alert),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0),
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
              onChanged: (v) { if (v != null) _saveMirror(v); },
              child: Column(
                children: <String, String>{
                  '淘宝镜像': 'https://registry.npmmirror.com',
                  '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                  '华为镜像': 'https://repo.huaweicloud.com/repository/npm/',
                  '官方源': 'https://registry.npmjs.org',
                }.entries.map(
                  (e) => RadioListTile<String>(
                    title: Text(e.key),
                    subtitle: Text(e.value, style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary)),
                    value: e.value,
                    dense: true,
                  ),
                ).toList(),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildIntegrationSection(),
          const SizedBox(height: 24),
          _buildSection('关于', [
            _buildSettingRow('版本', '0.1.0'),
            _buildSettingRow('项目', 'Cicada (知了猴)'),
            ListTile(
              title: const Text('GitHub'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => launchUrl(Uri.parse('https://github.com/2233admin/cicada')),
            ),
            ListTile(
              title: const Text('检查更新'),
              trailing: _checkingUpdate
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
                subtitle: Text('备份版本: ${_latestBackup!.version} (${_latestBackup!.backupTime.toLocal().toString().split('.').first})'),
                trailing: const Icon(Icons.restore, color: Colors.orange),
                onTap: _rollbackToBackup,
              ),
            ListTile(
              title: const Text('清理所有数据', style: TextStyle(color: CicadaColors.alert)),
              subtitle: const Text('删除所有已保存的 API Key 和设置'),
              trailing: const Icon(Icons.delete_outline, color: CicadaColors.alert),
              onTap: _clearData,
            ),
            ListTile(
              title: const Text('卸载 OpenClaw', style: TextStyle(color: CicadaColors.alert)),
              subtitle: const Text('卸载 OpenClaw CLI 工具'),
              trailing: const Icon(Icons.delete_forever, color: CicadaColors.alert),
              onTap: _uninstallOpenClaw,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner(UpdateInfo info) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CicadaColors.ok.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CicadaColors.ok),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.new_releases_outlined, color: CicadaColors.ok, size: 16),
              const SizedBox(width: 6),
              Text(
                '发现新版本 v${info.latestVersion}',
                style: const TextStyle(
                  color: CicadaColors.ok,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.releaseNotes,
              style: const TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_downloadingUpdate) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              backgroundColor: CicadaColors.border,
              valueColor: const AlwaysStoppedAnimation(CicadaColors.ok),
            ),
            const SizedBox(height: 4),
            Text(
              _downloadProgress > 0
                  ? '下载中... ${(_downloadProgress * 100).toStringAsFixed(1)}%'
                  : '正在准备备份和下载...',
              style: const TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (info.downloadUrl.isNotEmpty)
                  FilledButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('更新（有风险）'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CicadaColors.ok,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _downloadUpdate(info.downloadUrl),
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('前往下载'),
                    onPressed: () => launchUrl(
                      Uri.parse('https://github.com/2233admin/cicada/releases/latest'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      subtitle: Text(value, style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary)),
      trailing: trailing,
    );
  }

  // Integration Management Section
  Widget _buildIntegrationSection() {
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
              child: Row(
                children: [
                  const Text(
                    '集成管理',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _feishuCreds != null
                          ? CicadaColors.ok.withAlpha(30)
                          : CicadaColors.textTertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _feishuCreds != null ? '已配置' : '未配置',
                      style: TextStyle(
                        fontSize: 11,
                        color: _feishuCreds != null
                            ? CicadaColors.ok
                            : CicadaColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3370FF).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat_bubble, color: Color(0xFF3370FF), size: 18),
              ),
              title: const Text('飞书'),
              subtitle: Text(
                _feishuCreds != null ? 'AppID: ${_feishuCreds!.appId}' : '点击配置飞书集成',
                style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
              ),
              trailing: Icon(
                _showFeishuConfig ? Icons.expand_less : Icons.expand_more,
                color: CicadaColors.textTertiary,
              ),
              onTap: () => setState(() => _showFeishuConfig = !_showFeishuConfig),
            ),
            if (_showFeishuConfig) _buildFeishuConfigPanel(),
            // Placeholder for future integrations
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CicadaColors.textTertiary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chat, color: CicadaColors.textTertiary, size: 18),
              ),
              title: Text('QQ', style: TextStyle(color: CicadaColors.textTertiary)),
              subtitle: Text(
                '即将推出',
                style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
              ),
              enabled: false,
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CicadaColors.textTertiary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chat, color: CicadaColors.textTertiary, size: 18),
              ),
              title: Text('钉钉', style: TextStyle(color: CicadaColors.textTertiary)),
              subtitle: Text(
                '即将推出',
                style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeishuConfigPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _feishuAppIdCtrl,
            decoration: InputDecoration(
              labelText: 'App ID',
              hintText: 'cli_xxxxxxxxxxxx',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feishuSecretCtrl,
            decoration: InputDecoration(
              labelText: 'App Secret',
              hintText: '输入应用密钥',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feishuWebhookCtrl,
            decoration: InputDecoration(
              labelText: 'Webhook URL (可选)',
              hintText: 'https://open.feishu.cn/open-apis/bot/v2/hook/xxx',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _testingFeishu ? null : _testFeishuConnection,
                icon: _testingFeishu
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link, size: 16),
                label: const Text('测试连接'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveFeishuConfig,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('保存'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.ok,
                ),
              ),
              const Spacer(),
              if (_feishuCreds != null)
                TextButton.icon(
                  onPressed: _clearFeishuConfig,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('清除'),
                  style: TextButton.styleFrom(
                    foregroundColor: CicadaColors.alert,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testFeishuConnection() async {
    final appId = _feishuAppIdCtrl.text.trim();
    final secret = _feishuSecretCtrl.text.trim();

    if (appId.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 App ID 和 App Secret')),
      );
      return;
    }

    setState(() => _testingFeishu = true);
    final result = await FeishuService.testConnection(appId, secret);
    setState(() => _testingFeishu = false);

    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ 连接成功${result.botName != null ? ' (${result.botName})' : ''}，延迟 ${result.latency}ms')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ 连接失败: ${result.error}')),
      );
    }
  }

  Future<void> _saveFeishuConfig() async {
    final appId = _feishuAppIdCtrl.text.trim();
    final secret = _feishuSecretCtrl.text.trim();
    final webhook = _feishuWebhookCtrl.text.trim();

    if (appId.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 App ID 和 App Secret')),
      );
      return;
    }

    await FeishuService.saveCredentials(FeishuCredentials(
      appId: appId,
      appSecret: secret,
      webhookUrl: webhook.isNotEmpty ? webhook : null,
    ));

    await _loadSettings();
    if (!mounted) return;

    setState(() => _showFeishuConfig = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('飞书配置已保存')),
    );
  }

  Future<void> _clearFeishuConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: const Text('确认清除'),
        content: const Text('清除飞书配置后，将无法发送通知到飞书。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CicadaColors.alert),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FeishuService.clearCredentials();
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('飞书配置已清除')),
      );
    }
  }
}
