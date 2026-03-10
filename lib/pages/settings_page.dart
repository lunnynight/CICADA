import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/config_service.dart';
import '../services/update_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    final config = await ConfigService.readConfig();
    if (!mounted) return;
    setState(() {
      _configPath = '$home/.openclaw/openclaw.json';
      _selectedMirror = config['npmMirror'] as String? ?? 'https://registry.npmmirror.com';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在下载更新，请稍候...')),
    );
    try {
      await UpdateService.downloadAndLaunch(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        title: const Text('确认清理'),
        content: const Text('将清除所有已保存的 API Key 和设置，此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  }
                },
                tooltip: '打开目录',
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('镜像源设置', [
            ...<String, String>{
              '淘宝镜像': 'https://registry.npmmirror.com',
              '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
              '华为镜像': 'https://repo.huaweicloud.com/repository/npm/',
              '官方源': 'https://registry.npmjs.org',
            }.entries.map(
              (e) => RadioListTile<String>(
                title: Text(e.key),
                subtitle: Text(e.value, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                value: e.value,
                groupValue: _selectedMirror,
                onChanged: (v) { if (v != null) _saveMirror(v); },
                dense: true,
              ),
            ),
          ]),
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
            ListTile(
              title: const Text('清理所有数据', style: TextStyle(color: Colors.red)),
              subtitle: const Text('删除所有已保存的 API Key 和设置'),
              trailing: const Icon(Icons.delete_outline, color: Colors.red),
              onTap: _clearData,
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
        color: const Color(0xFF1C2B1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2EA043)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.new_releases_outlined, color: Color(0xFF3FB950), size: 16),
              const SizedBox(width: 6),
              Text(
                '发现新版本 v${info.latestVersion}',
                style: const TextStyle(
                  color: Color(0xFF3FB950),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.releaseNotes,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (info.downloadUrl.isNotEmpty)
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('下载安装'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2EA043),
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
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
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
      subtitle: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: trailing,
    );
  }
}
