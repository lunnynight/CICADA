import 'package:flutter/material.dart';

import '../app/theme/cicada_colors.dart';
import '../models/mcp_server.dart';
import '../data/mcp_presets.dart';
import '../data/mcp_directory.dart';
import '../services/mcp_service.dart';

class McpPage extends StatefulWidget {
  const McpPage({super.key});

  @override
  State<McpPage> createState() => _McpPageState();
}

class _McpPageState extends State<McpPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<McpServer> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadServers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() => _loading = true);
    final servers = await McpService.getAll();
    if (mounted) setState(() { _servers = servers; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: CicadaColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: CicadaColors.accent,
            labelColor: CicadaColors.accent,
            unselectedLabelColor: CicadaColors.textSecondary,
            labelStyle: const TextStyle(
              fontFamily: 'monospace', fontSize: 13,
              fontWeight: FontWeight.w600, letterSpacing: 1,
            ),
            tabs: const [
              Tab(text: 'MY PLUGINS'),
              Tab(text: 'PRESETS'),
              Tab(text: 'DISCOVER'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MyPluginsTab(
                servers: _servers,
                loading: _loading,
                onRefresh: _loadServers,
                onAdd: () => _showAddDialog(),
              ),
              _PresetsTab(onInstall: (preset) => _installPreset(preset)),
              const _DiscoverTab(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog({McpServer? existing}) async {
    final result = await showDialog<McpServer>(
      context: context,
      builder: (ctx) => _McpFormDialog(existing: existing),
    );
    if (result != null) {
      if (existing != null) {
        await McpService.update(result);
      } else {
        await McpService.add(result);
      }
      _loadServers();
    }
  }

  Future<void> _installPreset(McpPreset preset) async {
    // Collect required env vars
    Map<String, String> env = {};
    if (preset.envKeys.isNotEmpty && mounted) {
      env = await _collectEnvVars(preset.envKeys) ?? {};
      if (env.isEmpty && preset.envKeys.isNotEmpty) return; // cancelled
    }

    final id = preset.name.toLowerCase().replaceAll(' ', '-');
    final server = preset.toServer(id: id, env: env);
    await McpService.add(server);
    _loadServers();
    _tabController.animateTo(0); // switch to My Plugins
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加插件: ${preset.name}')),
      );
    }
  }

  Future<Map<String, String>?> _collectEnvVars(List<String> keys) async {
    final controllers = {for (final k in keys) k: TextEditingController()};
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CicadaColors.border),
        ),
        title: const Text('配置环境变量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: keys.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controllers[k],
              decoration: InputDecoration(
                labelText: k,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              obscureText: k.toLowerCase().contains('key') || k.toLowerCase().contains('secret'),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final env = <String, String>{};
              for (final k in keys) {
                final v = controllers[k]!.text.trim();
                if (v.isNotEmpty) env[k] = v;
              }
              Navigator.pop(ctx, env);
            },
            style: FilledButton.styleFrom(backgroundColor: CicadaColors.ok),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    for (final c in controllers.values) { c.dispose(); }
    return result;
  }
}

// ── My Plugins Tab ──

class _MyPluginsTab extends StatelessWidget {
  final List<McpServer> servers;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _MyPluginsTab({
    required this.servers,
    required this.loading,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
          child: Row(
            children: [
              const Text(
                'MCP PLUGINS',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: CicadaColors.accent, fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加插件'),
                style: FilledButton.styleFrom(backgroundColor: CicadaColors.accent),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: CicadaColors.muted),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: CicadaColors.data))
              : servers.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: servers.length,
                      itemBuilder: (ctx, i) => _McpServerTile(
                        server: servers[i],
                        onToggle: (enabled) async {
                          await McpService.toggle(servers[i].id, enabled);
                          onRefresh();
                        },
                        onDelete: () async {
                          await McpService.remove(servers[i].id);
                          onRefresh();
                        },
                        onTest: () async {
                          final result = await McpService.test(servers[i]);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(result.isSuccess
                                  ? result.dataOrNull ?? '测试通过'
                                  : result.errorOrNull?.message ?? '测试失败'),
                            ));
                          }
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.extension_off, size: 56, color: CicadaColors.border),
          const SizedBox(height: 16),
          const Text(
            'NO PLUGINS CONFIGURED',
            style: TextStyle(
              color: CicadaColors.textSecondary, fontSize: 16,
              fontFamily: 'monospace', letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '从预设模板或发现页面添加插件',
            style: TextStyle(color: CicadaColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Server Tile ──

class _McpServerTile extends StatelessWidget {
  final McpServer server;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _McpServerTile({
    required this.server,
    required this.onToggle,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: server.enabled ? CicadaColors.accent.withAlpha(80) : CicadaColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              server.transport == McpTransport.sse ? Icons.cloud : Icons.terminal,
              color: server.enabled ? CicadaColors.accent : CicadaColors.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                      color: server.enabled ? CicadaColors.textPrimary : CicadaColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    server.description ?? '${server.command} ${server.args.join(' ')}',
                    style: const TextStyle(fontSize: 11, color: CicadaColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.speed, size: 16),
              color: CicadaColors.data,
              onPressed: onTest,
              tooltip: '测试',
            ),
            Switch(
              value: server.enabled,
              onChanged: onToggle,
              activeTrackColor: CicadaColors.ok,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: CicadaColors.alert,
              onPressed: onDelete,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Presets Tab ──

class _PresetsTab extends StatelessWidget {
  final void Function(McpPreset) onInstall;

  const _PresetsTab({required this.onInstall});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: mcpPresets.length,
      itemBuilder: (ctx, i) {
        final preset = mcpPresets[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: CicadaColors.border),
          ),
          child: ListTile(
            leading: Icon(Icons.extension, color: CicadaColors.data, size: 20),
            title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preset.description, style: const TextStyle(fontSize: 11, color: CicadaColors.textTertiary)),
                if (preset.envKeys.isNotEmpty)
                  Text(
                    '需要: ${preset.envKeys.join(', ')}',
                    style: TextStyle(fontSize: 10, color: CicadaColors.alert.withAlpha(180)),
                  ),
              ],
            ),
            trailing: OutlinedButton(
              onPressed: () => onInstall(preset),
              style: OutlinedButton.styleFrom(
                foregroundColor: CicadaColors.accent,
                side: const BorderSide(color: CicadaColors.accent),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('添加', style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}

// ── Discover Tab ──

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  String _category = '全部';

  List<McpEntry> get _filtered {
    if (_category == '全部') return mcpDirectory;
    return mcpDirectory.where((e) => e.category == _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: mcpDirectoryCategories.map((cat) {
                final selected = _category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(
                      fontSize: 11, fontFamily: 'monospace',
                      color: selected ? CicadaColors.background : CicadaColors.textSecondary,
                    )),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: CicadaColors.accent,
                    backgroundColor: CicadaColors.surface,
                    side: BorderSide(color: selected ? CicadaColors.accent : CicadaColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 120,
            ),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final entry = _filtered[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: CicadaColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.name, style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13,
                          )),
                          const Spacer(),
                          if (entry.stars > 0)
                            Row(children: [
                              const Icon(Icons.star, size: 12, color: CicadaColors.alert),
                              const SizedBox(width: 2),
                              Text(
                                entry.stars >= 1000 ? '${(entry.stars / 1000).toStringAsFixed(1)}k' : '${entry.stars}',
                                style: const TextStyle(fontSize: 10, color: CicadaColors.textTertiary),
                              ),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(entry.description, style: const TextStyle(
                        fontSize: 11, color: CicadaColors.textTertiary,
                      ), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        children: [
                          Text(entry.category, style: TextStyle(
                            fontSize: 10, color: CicadaColors.accent.withAlpha(180),
                            fontFamily: 'monospace',
                          )),
                          const Spacer(),
                          Text(entry.npm, style: const TextStyle(
                            fontSize: 9, color: CicadaColors.textTertiary,
                            fontFamily: 'monospace',
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Add/Edit Dialog ──

class _McpFormDialog extends StatefulWidget {
  final McpServer? existing;
  const _McpFormDialog({this.existing});

  @override
  State<_McpFormDialog> createState() => _McpFormDialogState();
}

class _McpFormDialogState extends State<_McpFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commandCtrl;
  late final TextEditingController _argsCtrl;
  late final TextEditingController _urlCtrl;
  McpTransport _transport = McpTransport.stdio;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _commandCtrl = TextEditingController(text: e?.command ?? '');
    _argsCtrl = TextEditingController(text: e?.args.join(' ') ?? '');
    _urlCtrl = TextEditingController(text: e?.url ?? '');
    _transport = e?.transport ?? McpTransport.stdio;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commandCtrl.dispose();
    _argsCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CicadaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CicadaColors.border),
      ),
      title: Text(widget.existing != null ? '编辑插件' : '添加插件'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('传输方式：', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('stdio'),
                  selected: _transport == McpTransport.stdio,
                  onSelected: (_) => setState(() => _transport = McpTransport.stdio),
                  selectedColor: CicadaColors.accent,
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('SSE'),
                  selected: _transport == McpTransport.sse,
                  onSelected: (_) => setState(() => _transport = McpTransport.sse),
                  selectedColor: CicadaColors.accent,
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_transport == McpTransport.stdio) ...[
              TextField(
                controller: _commandCtrl,
                decoration: InputDecoration(
                  labelText: '命令',
                  hintText: 'npx',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _argsCtrl,
                decoration: InputDecoration(
                  labelText: '参数（空格分隔）',
                  hintText: '-y @anthropic-ai/mcp-filesystem',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ] else
              TextField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: 'SSE URL',
                  hintText: 'http://localhost:3000/sse',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final id = widget.existing?.id ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
            final server = McpServer(
              id: id,
              name: name,
              command: _commandCtrl.text.trim(),
              args: _argsCtrl.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList(),
              transport: _transport,
              url: _transport == McpTransport.sse ? _urlCtrl.text.trim() : null,
              source: 'manual',
              createdAt: DateTime.now(),
            );
            Navigator.pop(context, server);
          },
          style: FilledButton.styleFrom(backgroundColor: CicadaColors.ok),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
