import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme/cicada_colors.dart';
import '../services/claude_code_service.dart';
import '../services/installer_service.dart';

class ClaudeCodePage extends StatefulWidget {
  const ClaudeCodePage({super.key});

  @override
  State<ClaudeCodePage> createState() => _ClaudeCodePageState();
}

class _ClaudeCodePageState extends State<ClaudeCodePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Install
  bool _installed = false;
  String _version = '';
  bool _checking = true;
  bool _installing = false;
  final List<String> _installLog = [];

  // Tab 2: Providers
  List<ApiProvider> _providers = [];
  String? _currentProvider;

  // Tab 3: Config
  Map<String, String> _envVars = {};
  Map<String, dynamic> _mcpServers = {};
  bool? _vscodeInstalled;
  bool? _vscodeExtInstalled;
  bool _installingVscodeExt = false;

  // Tab 4: Sessions
  List<SessionMeta> _sessions = [];
  bool _loadingSessions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_checkInstall(), _loadProviders(), _loadConfig()]);
  }

  Future<void> _checkInstall() async {
    setState(() => _checking = true);
    final result = await InstallerService.checkClaudeCode();
    if (!mounted) return;
    setState(() {
      _installed = result.exitCode == 0;
      _version = _installed ? (result.stdout as String).trim() : '';
      _checking = false;
    });
  }

  Future<void> _runInstall() async {
    // Pre-check: Node >= 22
    final nodeCheck = await InstallerService.isNodeVersionSufficient();
    if (!nodeCheck.sufficient) {
      if (!mounted) return;
      final msg = nodeCheck.installed
          ? 'Node.js 版本过低 (${nodeCheck.raw})，需要 >= 22'
          : 'Node.js 未安装，需要 >= 22';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: CicadaColors.alert,
      ));
      return;
    }

    setState(() {
      _installing = true;
      _installLog.clear();
      _installLog.add('>>> 安装 Claude Code (官方脚本) ...');
    });
    try {
      final code = await InstallerService.runInstallWithCallback(
        () => InstallerService.installClaudeCode(),
        (line) {
          if (!mounted) return;
          setState(() => _installLog.add(line));
        },
      );
      if (!mounted) return;
      setState(() {
        _installLog.add(code == 0 ? '\n✓ 安装成功' : '\n✗ 安装失败 (exit: $code)');
        _installing = false;
      });
      if (code == 0) await _checkInstall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installLog.add('错误: $e');
        _installing = false;
      });
    }
  }

  Future<void> _runUninstall() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: const Text('确认卸载',
            style: TextStyle(color: CicadaColors.textPrimary, fontSize: 16)),
        content: const Text('确定要卸载 Claude Code 吗？此操作不会删除 ~/.claude 配置目录。',
            style: TextStyle(color: CicadaColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消',
                style: TextStyle(color: CicadaColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('卸载',
                style: TextStyle(color: CicadaColors.alert)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _installing = true;
      _installLog.clear();
      _installLog.add('>>> 卸载 Claude Code ...');
    });
    try {
      final code = await InstallerService.runInstallWithCallback(
        () => InstallerService.uninstallClaudeCode(),
        (line) {
          if (!mounted) return;
          setState(() => _installLog.add(line));
        },
      );
      if (!mounted) return;
      setState(() {
        _installLog.add(code == 0 ? '\n✓ 卸载成功' : '\n✗ 卸载失败');
        _installing = false;
      });
      if (code == 0) await _checkInstall();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installLog.add('错误: $e');
        _installing = false;
      });
    }
  }

  Future<void> _loadProviders() async {
    final providers = await ClaudeCodeService.getProviders();
    final current = await ClaudeCodeService.getCurrentProvider();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _currentProvider = current;
    });
  }

  Future<void> _loadConfig() async {
    final env = await ClaudeCodeService.getEnvVars();
    final mcp = await ClaudeCodeService.getMcpServers();
    final vscodeOk = await InstallerService.checkVSCode();
    final extOk = vscodeOk
        ? await InstallerService.isClaudeCodeExtensionInstalled()
        : false;
    if (!mounted) return;
    setState(() {
      _envVars = env;
      _mcpServers = mcp;
      _vscodeInstalled = vscodeOk;
      _vscodeExtInstalled = extOk;
    });
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    final sessions = await ClaudeCodeService.listSessions(limit: 100);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loadingSessions = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CicadaColors.background,
      appBar: AppBar(
        backgroundColor: CicadaColors.surface,
        title: const Text('Claude Code',
            style: TextStyle(color: CicadaColors.textPrimary, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CicadaColors.accent,
          labelColor: CicadaColors.textPrimary,
          unselectedLabelColor: CicadaColors.textTertiary,
          onTap: (i) {
            if (i == 3 && _sessions.isEmpty) _loadSessions();
          },
          tabs: const [
            Tab(text: '安装', icon: Icon(Icons.download, size: 18)),
            Tab(text: 'Provider', icon: Icon(Icons.swap_horiz, size: 18)),
            Tab(text: '配置', icon: Icon(Icons.tune, size: 18)),
            Tab(text: '会话', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstallTab(),
          _buildProviderTab(),
          _buildConfigTab(),
          _buildSessionTab(),
        ],
      ),
    );
  }

  // ==================== Tab 1: Install ====================

  Widget _buildInstallTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CicadaColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _installed ? CicadaColors.ok : CicadaColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _installed ? Icons.check_circle : Icons.cancel,
                color: _installed ? CicadaColors.ok : CicadaColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _checking
                          ? '检测中...'
                          : _installed
                              ? 'Claude Code 已安装'
                              : 'Claude Code 未安装',
                      style: const TextStyle(
                          color: CicadaColors.textPrimary, fontSize: 14),
                    ),
                    if (_version.isNotEmpty)
                      Text(_version,
                          style: const TextStyle(
                              color: CicadaColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              if (!_checking && !_installing) ...[
                if (!_installed)
                  _actionBtn('安装', CicadaColors.ok, _runInstall)
                else ...[
                  _actionBtn('更新', CicadaColors.energy, _runInstall),
                  const SizedBox(width: 8),
                  _actionBtn('卸载', CicadaColors.alert, _runUninstall),
                ],
              ],
              if (_installing)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        // Terminal output
        if (_installLog.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CicadaColors.border),
            ),
            child: ListView.builder(
              itemCount: _installLog.length,
              itemBuilder: (_, i) => Text(
                _installLog[i],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _installLog[i].startsWith('✓')
                      ? CicadaColors.ok
                      : _installLog[i].startsWith('✗')
                          ? CicadaColors.alert
                          : CicadaColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(color: color.withAlpha(80)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }


  // ==================== Tab 2: Provider ====================

  Widget _buildProviderTab() {
    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz,
                size: 48, color: CicadaColors.textTertiary),
            const SizedBox(height: 12),
            const Text('还没有 Provider',
                style: TextStyle(color: CicadaColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('添加一个 API 端点开始使用 Claude Code',
                style: TextStyle(
                    color: CicadaColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 16),
            _actionBtn('添加 Provider', CicadaColors.accent, _showAddProvider),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _providers.length,
          itemBuilder: (_, i) => _buildProviderCard(_providers[i]),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            backgroundColor: CicadaColors.accent,
            onPressed: _showAddProvider,
            child: const Icon(Icons.add, color: CicadaColors.background),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(ApiProvider provider) {
    final isCurrent = provider.name == _currentProvider;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? CicadaColors.accent : CicadaColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isCurrent ? CicadaColors.accent : CicadaColors.textTertiary,
          size: 20,
        ),
        title: Text(provider.name,
            style: TextStyle(
              color: CicadaColors.textPrimary,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            )),
        subtitle: Text(
          '${provider.baseUrl}  ·  ${provider.model}',
          style:
              const TextStyle(color: CicadaColors.textTertiary, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert,
              color: CicadaColors.textTertiary, size: 18),
          color: CicadaColors.surface,
          onSelected: (action) async {
            switch (action) {
              case 'switch':
                await ClaudeCodeService.switchProvider(provider.name);
                await _loadProviders();
                await _loadConfig();
              case 'edit':
                _showEditProvider(provider);
              case 'test':
                _testProvider(provider);
              case 'delete':
                await ClaudeCodeService.removeProvider(provider.name);
                await _loadProviders();
            }
          },
          itemBuilder: (_) => [
            if (!isCurrent)
              const PopupMenuItem(
                  value: 'switch',
                  child: Text('切换到此 Provider',
                      style: TextStyle(color: CicadaColors.textPrimary, fontSize: 13))),
            const PopupMenuItem(
                value: 'test',
                child: Text('测试连接',
                    style: TextStyle(color: CicadaColors.textPrimary, fontSize: 13))),
            const PopupMenuItem(
                value: 'edit',
                child: Text('编辑',
                    style: TextStyle(color: CicadaColors.textPrimary, fontSize: 13))),
            const PopupMenuItem(
                value: 'delete',
                child: Text('删除',
                    style: TextStyle(color: CicadaColors.alert, fontSize: 13))),
          ],
        ),
        onTap: isCurrent
            ? null
            : () async {
                await ClaudeCodeService.switchProvider(provider.name);
                await _loadProviders();
                await _loadConfig();
              },
      ),
    );
  }

  Future<void> _testProvider(ApiProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: CicadaColors.surface,
        content: Row(
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text('测试连接中...',
                style: TextStyle(color: CicadaColors.textPrimary)),
          ],
        ),
      ),
    );
    final result = await ClaudeCodeService.testProvider(provider);
    if (!mounted) return;
    Navigator.pop(context);
    final msg = result.success
        ? '连接成功 (${result.latencyMs}ms)'
        : '连接失败 (${result.latencyMs}ms)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: result.success ? CicadaColors.ok : CicadaColors.alert,
    ));
  }

  void _showAddProvider() => _showProviderDialog(null);
  void _showEditProvider(ApiProvider p) => _showProviderDialog(p);

  void _showProviderDialog(ApiProvider? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.baseUrl ?? '');
    final keyCtrl = TextEditingController(text: existing?.apiKey ?? '');
    final modelCtrl = TextEditingController(
        text: existing?.model ?? 'claude-sonnet-4-6');
    String? nameError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CicadaColors.surface,
          title: Text(
            existing == null ? '添加 Provider' : '编辑 Provider',
            style:
                const TextStyle(color: CicadaColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('名称', nameCtrl, '例如: my-relay',
                    errorText: nameError),
                _dialogField(
                    'Base URL', urlCtrl, 'https://api.anthropic.com'),
                _dialogField('API Key', keyCtrl, 'sk-...', obscure: true),
                _dialogField('模型', modelCtrl, 'claude-sonnet-4-6'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消',
                  style: TextStyle(color: CicadaColors.textTertiary)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final provider = ApiProvider(
                  name: name,
                  baseUrl: urlCtrl.text.trim(),
                  apiKey: keyCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                );
                if (name.isEmpty || provider.baseUrl.isEmpty) return;
                // Name uniqueness check (skip if editing same name)
                final duplicate = _providers.any((p) =>
                    p.name == name &&
                    (existing == null || p.name != existing.name));
                if (duplicate) {
                  setDialogState(() => nameError = '名称已存在');
                  return;
                }
                if (existing != null) {
                  await ClaudeCodeService.updateProvider(
                      existing.name, provider);
                } else {
                  await ClaudeCodeService.addProvider(provider);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await _loadProviders();
              },
              child: const Text('保存',
                  style: TextStyle(color: CicadaColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, String hint,
      {bool obscure = false, String? errorText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: CicadaColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: CicadaColors.textTertiary),
          hintText: hint,
          hintStyle: const TextStyle(color: CicadaColors.textTertiary),
          errorText: errorText,
          errorStyle: const TextStyle(color: CicadaColors.alert, fontSize: 11),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: CicadaColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: CicadaColors.accent),
            borderRadius: BorderRadius.circular(6),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: CicadaColors.alert),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: CicadaColors.alert),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }


  // ==================== Tab 3: Config ====================

  Widget _buildConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Env vars section
        _sectionHeader('环境变量', Icons.vpn_key),
        ..._envVars.entries.map((e) => _envVarTile(e.key, e.value)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _actionBtn('添加变量', CicadaColors.data, _showAddEnvVar),
        ),
        const SizedBox(height: 16),
        // MCP servers section
        _sectionHeader('MCP 服务器', Icons.extension),
        if (_mcpServers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('无 MCP 服务器配置',
                style: TextStyle(color: CicadaColors.textTertiary, fontSize: 12)),
          )
        else
          ..._mcpServers.entries.map((e) => _mcpTile(e.key, e.value)),
        const SizedBox(height: 16),
        // VS Code extension section
        _sectionHeader('VS Code 插件', Icons.code),
        _buildVscodeSection(),
        const SizedBox(height: 16),
        // Raw JSON
        _actionBtn('查看原始 JSON', CicadaColors.textSecondary, _showRawJson),
      ],
    );
  }

  Widget _buildVscodeSection() {
    if (_vscodeInstalled == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('检测中...',
            style: TextStyle(color: CicadaColors.textTertiary, fontSize: 12)),
      );
    }
    if (!_vscodeInstalled!) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: CicadaColors.textTertiary),
            SizedBox(width: 8),
            Text('VS Code 未检测到',
                style:
                    TextStyle(color: CicadaColors.textTertiary, fontSize: 12)),
          ],
        ),
      );
    }
    // VS Code installed
    if (_vscodeExtInstalled == true) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: CicadaColors.ok),
                SizedBox(width: 8),
                Text('Claude Code 插件已安装',
                    style:
                        TextStyle(color: CicadaColors.textPrimary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'VS Code 插件会自动继承 ~/.claude/settings.json 中的配置，无需额外设置',
              style:
                  TextStyle(color: CicadaColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      );
    }
    // VS Code installed, extension not installed
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Claude Code 插件未安装',
                    style: TextStyle(
                        color: CicadaColors.textSecondary, fontSize: 12)),
              ),
              if (_installingVscodeExt)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                _actionBtn(
                    '一键安装', CicadaColors.accent, _installVscodeExtension),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'VS Code 插件会自动继承 ~/.claude/settings.json 中的配置，无需额外设置',
            style: TextStyle(color: CicadaColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _installVscodeExtension() async {
    setState(() => _installingVscodeExt = true);
    try {
      final code = await InstallerService.runInstallWithCallback(
        () => InstallerService.installClaudeCodeExtension(),
        (_) {},
      );
      if (!mounted) return;
      if (code == 0) {
        setState(() {
          _vscodeExtInstalled = true;
          _installingVscodeExt = false;
        });
      } else {
        setState(() => _installingVscodeExt = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('插件安装失败'),
          backgroundColor: CicadaColors.alert,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _installingVscodeExt = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('安装错误: $e'),
        backgroundColor: CicadaColors.alert,
      ));
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CicadaColors.accent),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: CicadaColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _envVarTile(String key, String value) {
    final masked = key.contains('KEY') || key.contains('TOKEN')
        ? '${value.substring(0, (value.length > 8 ? 8 : value.length))}...'
        : value;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(key,
                style: const TextStyle(
                    color: CicadaColors.energy,
                    fontFamily: 'monospace',
                    fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(masked,
                style: const TextStyle(
                    color: CicadaColors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          InkWell(
            onTap: () async {
              await ClaudeCodeService.removeEnvVar(key);
              await _loadConfig();
            },
            child: const Icon(Icons.close,
                size: 14, color: CicadaColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _mcpTile(String name, dynamic config) {
    final cmd = config is Map ? (config['command'] ?? 'http') : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.power, size: 14, color: CicadaColors.data),
          const SizedBox(width: 8),
          Text(name,
              style: const TextStyle(
                  color: CicadaColors.textPrimary, fontSize: 12)),
          const Spacer(),
          Text('$cmd',
              style: const TextStyle(
                  color: CicadaColors.textTertiary,
                  fontFamily: 'monospace',
                  fontSize: 11)),
        ],
      ),
    );
  }

  void _showAddEnvVar() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: const Text('添加环境变量',
            style: TextStyle(color: CicadaColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Key', keyCtrl, 'ANTHROPIC_API_KEY'),
            _dialogField('Value', valCtrl, 'sk-ant-...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: CicadaColors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              if (keyCtrl.text.trim().isEmpty) return;
              await ClaudeCodeService.setEnvVar(
                  keyCtrl.text.trim(), valCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadConfig();
            },
            child: const Text('保存',
                style: TextStyle(color: CicadaColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRawJson() async {
    final settings = await ClaudeCodeService.readSettings();
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert(settings);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: Row(
          children: [
            const Text('settings.json',
                style: TextStyle(color: CicadaColors.textPrimary, fontSize: 14)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: CicadaColors.textTertiary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('已复制')),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Text(jsonStr,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: CicadaColors.textSecondary)),
          ),
        ),
      ),
    );
  }


  // ==================== Tab 4: Sessions ====================

  Widget _buildSessionTab() {
    if (_loadingSessions) {
      return const Center(
          child: CircularProgressIndicator(color: CicadaColors.accent));
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history,
                size: 48, color: CicadaColors.textTertiary),
            const SizedBox(height: 12),
            const Text('暂无会话记录',
                style: TextStyle(color: CicadaColors.textSecondary)),
            const SizedBox(height: 16),
            _actionBtn('加载会话', CicadaColors.energy, _loadSessions),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (_, i) {
          final s = _sessions[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: CicadaColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CicadaColors.border),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              title: Text(
                s.firstMessage ?? s.sessionId.substring(0, 8),
                style: const TextStyle(
                    color: CicadaColors.textPrimary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_formatTime(s.timestamp)}  ·  ${s.project}',
                style: const TextStyle(
                    color: CicadaColors.textTertiary, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: CicadaColors.textTertiary, size: 18),
              onTap: () => _showSessionDetail(s),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  Future<void> _showSessionDetail(SessionMeta session) async {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        backgroundColor: CicadaColors.surface,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text('加载会话...',
                style: TextStyle(color: CicadaColors.textPrimary)),
          ],
        ),
      ),
    );

    final messages = await ClaudeCodeService.loadSession(session.filePath);
    if (!mounted) return;
    Navigator.pop(context);

    // Filter to user/assistant messages for display
    final displayMsgs = messages.where((m) {
      final t = m.type;
      return t == 'human' || t == 'user' || t == 'assistant' || t == 'text';
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CicadaColors.surface,
        title: Text(
          session.firstMessage ?? session.sessionId.substring(0, 8),
          style: const TextStyle(color: CicadaColors.textPrimary, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: displayMsgs.isEmpty
              ? Center(
                  child: Text(
                    '${messages.length} 条事件（无可显示的对话消息）',
                    style: const TextStyle(color: CicadaColors.textTertiary),
                  ),
                )
              : ListView.builder(
                  itemCount: displayMsgs.length,
                  itemBuilder: (_, i) {
                    final msg = displayMsgs[i];
                    final isUser =
                        msg.type == 'human' || msg.type == 'user';
                    final content = _extractContent(msg.data);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? CicadaColors.data.withAlpha(15)
                            : CicadaColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUser
                              ? CicadaColors.data.withAlpha(40)
                              : CicadaColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUser ? 'User' : 'Assistant',
                            style: TextStyle(
                              color: isUser
                                  ? CicadaColors.data
                                  : CicadaColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content,
                            style: const TextStyle(
                                color: CicadaColors.textPrimary, fontSize: 12),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭',
                style: TextStyle(color: CicadaColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  String _extractContent(Map<String, dynamic> data) {
    // Try common JSONL message formats
    final msg = data['message'] as Map<String, dynamic>?;
    if (msg != null) {
      final content = msg['content'];
      if (content is String) return content;
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map && first['text'] != null) return first['text'];
        if (first is String) return first;
      }
    }
    final content = data['content'];
    if (content is String) return content;
    return data['type']?.toString() ?? '';
  }
}
