import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../services/integration_service.dart';

/// Integration management section widget (Feishu, QQ placeholder, DingTalk placeholder).
class SettingsIntegrationSection extends StatefulWidget {
  final FeishuCredentials? feishuCreds;
  final VoidCallback onCredentialsChanged;

  const SettingsIntegrationSection({
    super.key,
    required this.feishuCreds,
    required this.onCredentialsChanged,
  });

  @override
  State<SettingsIntegrationSection> createState() =>
      _SettingsIntegrationSectionState();
}

class _SettingsIntegrationSectionState
    extends State<SettingsIntegrationSection> {
  bool _testingFeishu = false;
  bool _showFeishuConfig = false;
  final _feishuAppIdCtrl = TextEditingController();
  final _feishuSecretCtrl = TextEditingController();
  final _feishuWebhookCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.feishuCreds != null) {
      _feishuAppIdCtrl.text = widget.feishuCreds!.appId;
    }
  }

  @override
  void dispose() {
    _feishuAppIdCtrl.dispose();
    _feishuSecretCtrl.dispose();
    _feishuWebhookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.feishuCreds != null
                          ? CicadaColors.ok.withAlpha(30)
                          : CicadaColors.textTertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.feishuCreds != null ? '已配置' : '未配置',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.feishuCreds != null
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
                child: const Icon(
                  Icons.chat_bubble,
                  color: Color(0xFF3370FF),
                  size: 18,
                ),
              ),
              title: const Text('飞书'),
              subtitle: Text(
                widget.feishuCreds != null
                    ? 'AppID: ${widget.feishuCreds!.appId}'
                    : '点击配置飞书集成',
                style: TextStyle(
                  fontSize: 12,
                  color: CicadaColors.textTertiary,
                ),
              ),
              trailing: Icon(
                _showFeishuConfig ? Icons.expand_less : Icons.expand_more,
                color: CicadaColors.textTertiary,
              ),
              onTap: () =>
                  setState(() => _showFeishuConfig = !_showFeishuConfig),
            ),
            if (_showFeishuConfig) _buildFeishuConfigPanel(),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CicadaColors.textTertiary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat,
                  color: CicadaColors.textTertiary,
                  size: 18,
                ),
              ),
              title: Text(
                'QQ',
                style: TextStyle(color: CicadaColors.textTertiary),
              ),
              subtitle: Text(
                '即将推出',
                style: TextStyle(
                  fontSize: 12,
                  color: CicadaColors.textTertiary,
                ),
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
                child: Icon(
                  Icons.chat,
                  color: CicadaColors.textTertiary,
                  size: 18,
                ),
              ),
              title: Text(
                '钉钉',
                style: TextStyle(color: CicadaColors.textTertiary),
              ),
              subtitle: Text(
                '即将推出',
                style: TextStyle(
                  fontSize: 12,
                  color: CicadaColors.textTertiary,
                ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feishuSecretCtrl,
            decoration: InputDecoration(
              labelText: 'App Secret',
              hintText: '输入应用密钥',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feishuWebhookCtrl,
            decoration: InputDecoration(
              labelText: 'Webhook URL (可选)',
              hintText: 'https://open.feishu.cn/open-apis/bot/v2/hook/xxx',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
                style:
                    FilledButton.styleFrom(backgroundColor: CicadaColors.ok),
              ),
              const Spacer(),
              if (widget.feishuCreds != null)
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
          const SnackBar(content: Text('请填写 App ID 和 App Secret')));
      return;
    }

    setState(() => _testingFeishu = true);
    final result = await FeishuService.testConnection(appId, secret);
    setState(() => _testingFeishu = false);

    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ 连接成功${result.botName != null ? ' (${result.botName})' : ''}，延迟 ${result.latency}ms',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ 连接失败: ${result.error}')));
    }
  }

  Future<void> _saveFeishuConfig() async {
    final appId = _feishuAppIdCtrl.text.trim();
    final secret = _feishuSecretCtrl.text.trim();
    final webhook = _feishuWebhookCtrl.text.trim();

    if (appId.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写 App ID 和 App Secret')));
      return;
    }

    await FeishuService.saveCredentials(
      FeishuCredentials(
        appId: appId,
        appSecret: secret,
        webhookUrl: webhook.isNotEmpty ? webhook : null,
      ),
    );

    widget.onCredentialsChanged();
    if (!mounted) return;
    setState(() => _showFeishuConfig = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('飞书配置已保存')));
  }

  Future<void> _clearFeishuConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: const Text('确认清除'),
        content: const Text('清除飞书配置后，将无法发送通知到飞书。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: CicadaColors.alert),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FeishuService.clearCredentials();
      widget.onCredentialsChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('飞书配置已清除')));
    }
  }
}
