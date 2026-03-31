import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../services/preset_service.dart';
import '../services/config_service.dart';
import '../utils/key_masker.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _cnProviders = [];
  List<dynamic> _intlProviders = [];
  List<Map<String, dynamic>> _customProviders = [];
  Set<String> _configuredIds = {};
  Map<String, Map<String, dynamic>> _configuredDetails = {};
  List<String> _ollamaModels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cn = await PresetService.loadCnModels();
      final intl = await PresetService.loadIntlModels();
      final configured = await ConfigService.getConfiguredProviders();
      final ollama = await ConfigService.detectOllamaModels();
      final custom = await _loadCustomProviders();
      // Load provider details for overview bar
      final config = await ConfigService.readConfig();
      final providerMap = config['providers'] as Map<String, dynamic>? ?? {};
      final details = <String, Map<String, dynamic>>{};
      for (final id in configured) {
        final p = providerMap[id] as Map<String, dynamic>?;
        if (p != null) details[id] = p;
      }
      if (!mounted) return;
      setState(() {
        _cnProviders = (cn['providers'] as List?) ?? [];
        _intlProviders = (intl['providers'] as List?) ?? [];
        _customProviders = custom;
        _configuredIds = configured;
        _configuredDetails = details;
        _ollamaModels = ollama;
      });
    } catch (e) {
      debugPrint('ModelsPage._loadData failed: $e');
    }
  }

  Future<void> _showConfigDialog(Map<String, dynamic> provider) async {
    final controller = TextEditingController();
    final isOllama = provider['provider'] == 'ollama';

    // Load existing key from openclaw.json
    final config = await ConfigService.readConfig();
    final providers = config['providers'] as Map<String, dynamic>? ?? {};
    final existing = providers[provider['id']] as Map<String, dynamic>?;
    final existingKey = existing?['apiKey'] as String? ?? '';

    // Show masked key as placeholder, not as actual text
    bool showingMask = existingKey.isNotEmpty;
    bool obscureKey = true;
    if (showingMask) {
      controller.text = maskApiKey(existingKey);
    }

    // Default model selection
    final models =
        (provider['models'] as List)
            .map((m) => m as Map<String, dynamic>)
            .toList();
    String selectedModel =
        existing?['defaultModel'] as String? ??
        (models.isNotEmpty ? models.first['id'] as String : '');

    if (!mounted) return;

    String? testResult;
    bool testOk = false;
    int? testLatencyMs;
    bool testing = false;

    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  backgroundColor: CicadaColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: CicadaColors.border),
                  ),
                  title: Text('配置 ${provider['name']}'),
                  content: SizedBox(
                    width: 450,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Base: ${provider['apiBase']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: CicadaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!isOllama) ...[
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'API Key',
                              hintText: '输入你的 API Key',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureKey ? Icons.visibility_off : Icons.visibility,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setDialogState(() => obscureKey = !obscureKey);
                                },
                              ),
                            ),
                            obscureText: obscureKey,
                            onTap: () {
                              if (showingMask) {
                                setDialogState(() {
                                  controller.clear();
                                  showingMask = false;
                                });
                              }
                            },
                          ),
                          if (existingKey.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '当前: ${maskApiKey(existingKey)}  · 留空保留旧 Key',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CicadaColors.textTertiary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ] else ...[
                          if (_ollamaModels.isNotEmpty) ...[
                            Text(
                              '检测到本地模型:',
                              style: TextStyle(
                                color: CicadaColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  _ollamaModels
                                      .map(
                                        (m) => Chip(
                                          label: Text(
                                            m,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor:
                                              CicadaColors.background,
                                          side: const BorderSide(
                                            color: CicadaColors.border,
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Text(
                              '未检测到 Ollama 本地模型，请先安装 Ollama 并下载模型。',
                              style: TextStyle(
                                color: CicadaColors.accent,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        // Model selector with context window
                        DropdownButtonFormField<String>(
                          initialValue: selectedModel,
                          decoration: const InputDecoration(labelText: '默认模型'),
                          items: [
                            ...models.map(
                              (m) {
                                final ctx = m['context'] as int?;
                                final ctxLabel = ctx != null ? ' (${ctx >= 1000 ? '${ctx ~/ 1000}K' : ctx})' : '';
                                return DropdownMenuItem(
                                  value: m['id'] as String,
                                  child: Text('${m['name']}$ctxLabel'),
                                );
                              },
                            ),
                            if (isOllama)
                              ..._ollamaModels
                                  .where(
                                    (m) => !models.any((pm) => pm['id'] == m),
                                  )
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text('$m (本地)'),
                                    ),
                                  ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedModel = v);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Test connection button
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  testing
                                      ? null
                                      : () async {
                                        setDialogState(() {
                                          testing = true;
                                          testResult = null;
                                        });
                                        final effectiveKey = showingMask
                                            ? existingKey
                                            : controller.text.trim();
                                        final sw = Stopwatch()..start();
                                        final (
                                          ok,
                                          msg,
                                        ) = await ConfigService.testConnection(
                                          apiBase:
                                              provider['apiBase'] as String,
                                          apiKey: effectiveKey,
                                          model: selectedModel,
                                          provider:
                                              provider['provider'] as String,
                                        );
                                        sw.stop();
                                        setDialogState(() {
                                          testing = false;
                                          testOk = ok;
                                          testLatencyMs = sw.elapsedMilliseconds;
                                          testResult = msg;
                                        });
                                      },
                              icon:
                                  testing
                                      ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.wifi_tethering,
                                        size: 16,
                                      ),
                              label: Text(testing ? '测试中...' : '测试连接'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: CicadaColors.border,
                                ),
                              ),
                            ),
                            if (testResult != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                testOk ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: testOk ? CicadaColors.ok : CicadaColors.alert,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$testResult${testLatencyMs != null ? '  ${testLatencyMs}ms' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: testOk ? CicadaColors.ok : CicadaColors.alert,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((provider['keyUrl'] as String? ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap:
                                () => launchUrl(Uri.parse(provider['keyUrl'])),
                            child: Text(
                              '获取 API Key \u2192',
                              style: const TextStyle(
                                color: CicadaColors.energy,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    if (existing != null)
                      TextButton(
                        onPressed: () async {
                          // Confirm before delete
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              backgroundColor: CicadaColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: CicadaColors.border),
                              ),
                              title: const Text('确认删除'),
                              content: Text('确定要删除 ${provider['name']} 的配置吗？此操作不可撤销。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text(
                                    '删除',
                                    style: TextStyle(color: CicadaColors.alert),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ConfigService.removeProvider(provider['id']);
                            if (ctx.mounted) Navigator.pop(ctx, '__removed__');
                          }
                        },
                        child: const Text(
                          '删除',
                          style: TextStyle(color: CicadaColors.alert),
                        ),
                      ),
                    FilledButton(
                      onPressed:
                          () => Navigator.pop(
                            ctx,
                            '$selectedModel|||${controller.text}|||${showingMask ? '1' : '0'}',
                          ),
                      style: FilledButton.styleFrom(
                        backgroundColor: CicadaColors.data,
                      ),
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );

    if (result == null) {
      controller.dispose();
      return;
    }
    if (result == '__removed__') {
      controller.dispose();
      await _loadData();
      return;
    }

    final parts = result.split('|||');
    final model = parts[0];
    final rawKey = parts.length > 1 ? parts[1].trim() : '';
    final wasMask = parts.length > 2 && parts[2] == '1';

    // If user didn't touch the key field (still showing mask), keep existing key
    final apiKey = (wasMask || rawKey.isEmpty) ? existingKey : rawKey;

    if (isOllama || apiKey.isNotEmpty) {
      await ConfigService.setProvider(
        providerId: provider['id'] as String,
        apiKey: apiKey,
        apiBase: provider['apiBase'] as String,
        defaultModel: model,
      );
      await _loadData();
    }
    controller.dispose();
  }

  String _findProviderName(String id) {
    for (final p in [..._cnProviders, ..._intlProviders]) {
      final pm = p as Map<String, dynamic>;
      if (pm['id'] == id) return pm['name'] as String? ?? id;
    }
    // Check custom providers
    if (id.startsWith('custom-')) return id.replaceFirst('custom-', '');
    return id;
  }

  Map<String, dynamic>? _findProviderData(String id) {
    for (final p in [..._cnProviders, ..._intlProviders]) {
      final pm = p as Map<String, dynamic>;
      if (pm['id'] == id) return pm;
    }
    for (final pm in _customProviders) {
      if (pm['id'] == id) return pm;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MODEL CONFIG',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  if (_configuredIds.isNotEmpty)
                    Text(
                      '已配置 ${_configuredIds.length} 个供应商',
                      style: const TextStyle(
                        color: CicadaColors.ok,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '配置 AI 模型提供商 — 保存后自动写入 openclaw.json',
                style: TextStyle(color: CicadaColors.textSecondary),
              ),
              if (_configuredIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._configuredIds.map((id) {
                        final detail = _configuredDetails[id];
                        final name = _findProviderName(id);
                        final key = detail?['apiKey'] as String? ?? '';
                        final model = detail?['defaultModel'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              final p = _findProviderData(id);
                              if (p != null) _showConfigDialog(p);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: CicadaColors.ok.withValues(alpha: 0.08),
                                border: Border.all(color: CicadaColors.ok.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, color: CicadaColors.ok, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: CicadaColors.textPrimary,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${key.isNotEmpty ? maskApiKey(key) : '—'}  ·  $model',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: CicadaColors.textTertiary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '国产模型'),
                  Tab(text: '海外模型'),
                  Tab(text: '自定义'),
                ],
                indicatorColor: CicadaColors.data,
                labelColor: CicadaColors.data,
                unselectedLabelColor: CicadaColors.textSecondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProviderGrid(_cnProviders),
              _buildProviderGrid(_intlProviders),
              _buildCustomProviderTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderGrid(List<dynamic> providers) {
    if (providers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final p = providers[index] as Map<String, dynamic>;
        final configured = _configuredIds.contains(p['id']);
        return _buildProviderCard(p, configured);
      },
    );
  }

  Widget _buildCustomProviderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '自定义供应商',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddCustomDialog(),
                icon: const Icon(Icons.add),
                label: const Text('添加供应商'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.data,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '添加任意 OpenAI 兼容 API 的供应商',
            style: TextStyle(
              color: CicadaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (_customProviders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: CicadaColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '暂无自定义供应商',
                      style: TextStyle(color: CicadaColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击上方按钮添加任意 OpenAI 兼容 API',
                      style: TextStyle(
                        color: CicadaColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._customProviders.map((p) {
              final configured = _configuredIds.contains(p['id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProviderCard(p, configured, isCustom: true),
              );
            }),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadCustomProviders() async {
    final config = await ConfigService.readConfig();
    final customs = config['customProviders'] as List<dynamic>?;
    if (customs == null) return [];
    return customs.cast<Map<String, dynamic>>();
  }

  Future<void> _showAddCustomDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: isEdit ? existing['name'] as String? ?? '' : '');
    final baseCtrl = TextEditingController(text: isEdit ? existing['apiBase'] as String? ?? '' : '');
    final keyCtrl = TextEditingController();
    final modelCtrl = TextEditingController(
      text: isEdit
          ? ((existing['models'] as List?)?.isNotEmpty == true
              ? (existing['models'] as List).first['id'] as String? ?? ''
              : '')
          : '',
    );

    // For edit mode, show masked key hint
    final existingId = isEdit ? existing['id'] as String? ?? '' : '';
    String existingKey = '';
    if (isEdit) {
      final config = await ConfigService.readConfig();
      final providers = config['providers'] as Map<String, dynamic>? ?? {};
      final prov = providers[existingId] as Map<String, dynamic>?;
      existingKey = prov?['apiKey'] as String? ?? '';
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: CicadaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CicadaColors.border),
            ),
            title: Text(isEdit ? '编辑自定义供应商' : '添加自定义供应商'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '供应商名称',
                      hintText: '例: 我的代理',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: baseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'https://api.example.com/v1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: isEdit && existingKey.isNotEmpty
                          ? '当前: ${maskApiKey(existingKey)}  · 留空保留'
                          : 'sk-...',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(
                      labelText: '模型 ID',
                      hintText: '例: gpt-4o, claude-sonnet-4',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '支持所有 OpenAI 兼容 API（中转站、私有部署等）',
                    style: TextStyle(
                      fontSize: 12,
                      color: CicadaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.data,
                ),
                child: Text(isEdit ? '保存' : '添加'),
              ),
            ],
          ),
    );

    if (result != true) {
      nameCtrl.dispose();
      baseCtrl.dispose();
      keyCtrl.dispose();
      modelCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    final base = baseCtrl.text.trim();
    final key = keyCtrl.text.trim();
    final model = modelCtrl.text.trim();
    nameCtrl.dispose();
    baseCtrl.dispose();
    keyCtrl.dispose();
    modelCtrl.dispose();
    if (name.isEmpty || base.isEmpty || model.isEmpty) return;

    final id = isEdit
        ? existingId
        : 'custom-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}';

    // Save to customProviders list in config
    final config = await ConfigService.readConfig();
    final customs = (config['customProviders'] as List<dynamic>?) ?? [];

    final entry = {
      'id': id,
      'name': name,
      'provider': 'openai-compatible',
      'description': base,
      'apiBase': base,
      'models': [
        {'id': model, 'name': model, 'context': 128000},
      ],
      'keyUrl': '',
      'freeQuota': '',
    };

    if (isEdit) {
      final idx = customs.indexWhere((c) => (c as Map)['id'] == existingId);
      if (idx >= 0) {
        customs[idx] = entry;
      } else {
        customs.add(entry);
      }
    } else {
      customs.add(entry);
    }
    config['customProviders'] = customs;
    await ConfigService.writeConfig(config);

    // Save as active provider
    final effectiveKey = key.isNotEmpty ? key : existingKey;
    if (effectiveKey.isNotEmpty) {
      await ConfigService.setProvider(
        providerId: id,
        apiKey: effectiveKey,
        apiBase: base,
        defaultModel: model,
      );
    }

    await _loadData(); // Refresh all
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, bool configured, {bool isCustom = false}) {
    final freeQuota = provider['freeQuota'] as String? ?? '';
    final detail = _configuredDetails[provider['id']];
    final maskedKey = detail != null ? maskApiKey(detail['apiKey'] as String? ?? '') : '';
    final defaultModel = detail?['defaultModel'] as String? ?? '';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              configured
                  ? CicadaColors.ok.withValues(alpha: 0.5)
                  : CicadaColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    provider['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (configured)
                  const Icon(
                    Icons.check_circle,
                    color: CicadaColors.ok,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              provider['description'],
              style: TextStyle(fontSize: 13, color: CicadaColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (configured && (maskedKey.isNotEmpty || defaultModel.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (maskedKey.isNotEmpty) ...[
                    Icon(Icons.key, size: 11, color: CicadaColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      maskedKey,
                      style: TextStyle(
                        fontSize: 10,
                        color: CicadaColors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (maskedKey.isNotEmpty && defaultModel.isNotEmpty)
                    const SizedBox(width: 10),
                  if (defaultModel.isNotEmpty) ...[
                    Icon(Icons.smart_toy_outlined, size: 11, color: CicadaColors.textTertiary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        defaultModel,
                        style: TextStyle(
                          fontSize: 10,
                          color: CicadaColors.textTertiary,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (freeQuota.isNotEmpty)
              Chip(
                label: Text(freeQuota, style: const TextStyle(fontSize: 11)),
                backgroundColor: CicadaColors.ok.withValues(alpha: 0.15),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showConfigDialog(provider),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          configured ? CicadaColors.border : CicadaColors.data,
                    ),
                    child: Text(configured ? '修改配置' : '配置'),
                  ),
                ),
                if (isCustom) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showAddCustomDialog(existing: provider),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: '编辑供应商',
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: CicadaColors.border),
                    ),
                  ),
                ],
                if ((provider['keyUrl'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(provider['keyUrl'])),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: '获取 Key',
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: CicadaColors.border),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
