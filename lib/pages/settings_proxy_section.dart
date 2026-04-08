import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../models/proxy_config.dart';

/// Proxy settings section widget.
/// Keeps all TextEditingControllers in the parent State and passes them in.
class SettingsProxySection extends StatelessWidget {
  final ProxyConfig proxyConfig;
  final TextEditingController proxyHostCtrl;
  final TextEditingController proxyPortCtrl;
  final TextEditingController proxyUserCtrl;
  final TextEditingController proxyPassCtrl;
  final bool testingProxy;
  final Map<String, ({bool ok, int latencyMs, String? error})>? proxyTestResults;
  final ValueChanged<ProxyConfig> onProxyChanged;
  final VoidCallback onSave;
  final VoidCallback onTest;

  const SettingsProxySection({
    super.key,
    required this.proxyConfig,
    required this.proxyHostCtrl,
    required this.proxyPortCtrl,
    required this.proxyUserCtrl,
    required this.proxyPassCtrl,
    required this.testingProxy,
    required this.proxyTestResults,
    required this.onProxyChanged,
    required this.onSave,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection('网络代理（加速器）', [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          '国内网络可能无法直接访问 AI API，配置代理后可正常使用',
          style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
        ),
      ),
      SwitchListTile(
        title: const Text('启用代理'),
        value: proxyConfig.enabled,
        onChanged: (v) => onProxyChanged(proxyConfig.copyWith(enabled: v)),
        activeTrackColor: CicadaColors.ok,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text('类型：', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('HTTP'),
              selected: proxyConfig.type == ProxyType.http,
              onSelected: (_) =>
                  onProxyChanged(proxyConfig.copyWith(type: ProxyType.http)),
              selectedColor: CicadaColors.accent,
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('SOCKS5'),
              selected: proxyConfig.type == ProxyType.socks5,
              onSelected: (_) =>
                  onProxyChanged(proxyConfig.copyWith(type: ProxyType.socks5)),
              selectedColor: CicadaColors.accent,
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('系统代理'),
              selected: proxyConfig.type == ProxyType.system,
              onSelected: (_) =>
                  onProxyChanged(proxyConfig.copyWith(type: ProxyType.system)),
              selectedColor: CicadaColors.accent,
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          ],
        ),
      ),
      if (proxyConfig.type != ProxyType.system &&
          proxyConfig.type != ProxyType.none)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: proxyHostCtrl,
                  decoration: InputDecoration(
                    labelText: '地址',
                    hintText: '127.0.0.1',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: proxyPortCtrl,
                  decoration: InputDecoration(
                    labelText: '端口',
                    hintText: '7897',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      if (proxyConfig.type != ProxyType.system &&
          proxyConfig.type != ProxyType.none)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: proxyUserCtrl,
                  decoration: InputDecoration(
                    labelText: '用户名（可选）',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: proxyPassCtrl,
                  decoration: InputDecoration(
                    labelText: '密码（可选）',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  obscureText: true,
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: testingProxy ? null : onTest,
              icon: testingProxy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.speed, size: 16),
              label: const Text('测试连通性'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('保存'),
              style: FilledButton.styleFrom(backgroundColor: CicadaColors.ok),
            ),
          ],
        ),
      ),
      if (proxyTestResults != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: proxyTestResults!.entries.map((e) {
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      r.ok ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: r.ok ? CicadaColors.ok : CicadaColors.alert,
                    ),
                    const SizedBox(width: 6),
                    Text(e.key, style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(
                      r.ok ? '${r.latencyMs}ms' : (r.error ?? '失败'),
                      style: TextStyle(
                        fontSize: 11,
                        color: r.ok ? CicadaColors.ok : CicadaColors.alert,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
    ]);
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
}
