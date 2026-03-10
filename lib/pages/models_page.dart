import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preset_service.dart';
import '../services/config_service.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _cnProviders = [];
  List<dynamic> _intlProviders = [];
  Set<String> _configuredIds = {};
  List<String> _ollamaModels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cn = await PresetService.loadCnModels();
    final intl = await PresetService.loadIntlModels();
    final configured = await ConfigService.getConfiguredProviders();
    final ollama = await ConfigService.detectOllamaModels();
    if (!mounted) return;
    setState(() {
      _cnProviders = cn['providers'] as List;
      _intlProviders = intl['providers'] as List;
      _configuredIds = configured;
      _ollamaModels = ollama;
    });
  }

  Future<void> _showConfigDialog(Map<String, dynamic> provider) async {
    final controller = TextEditingController();
    final isOllama = provider['provider'] == 'ollama';

    // Load existing key from openclaw.json
    final config = await ConfigService.readConfig();
    final providers = config['providers'] as Map<String, dynamic>? ?? {};
    final existing = providers[provider['id']] as Map<String, dynamic>?;
    if (existing != null && existing['apiKey'] != null) {
      controller.text = existing['apiKey'] as String;
    }

    // Default model selection
    final models = (provider['models'] as List)
        .map((m) => m as Map<String, dynamic>)
        .toList();
    String selectedModel = existing?['defaultModel'] as String? ?? models.first['id'] as String;

    if (!mounted) return;

    String? testResult;
    bool testing = false;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF30363D)),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                if (!isOllama) ...[
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: '输入你的 API Key',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  if (_ollamaModels.isNotEmpty) ...[
                    Text('检测到本地模型:', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _ollamaModels.map((m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF0D1117),
                        side: const BorderSide(color: Color(0xFF30363D)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text('未检测到 Ollama 本地模型，请先安装 Ollama 并下载模型。',
                        style: TextStyle(color: Colors.orange[300], fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                ],
                // Model selector
                DropdownButtonFormField<String>(
                  initialValue: selectedModel,
                  decoration: const InputDecoration(labelText: '默认模型'),
                  items: [
                    ...models.map((m) => DropdownMenuItem(
                      value: m['id'] as String,
                      child: Text(m['name'] as String),
                    )),
                    if (isOllama)
                      ..._ollamaModels
                          .where((m) => !models.any((pm) => pm['id'] == m))
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m (本地)'))),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedModel = v);
                  },
                ),
                const SizedBox(height: 16),
                // Test connection button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: testing
                          ? null
                          : () async {
                              setDialogState(() {
                                testing = true;
                                testResult = null;
                              });
                              final (ok, msg) = await ConfigService.testConnection(
                                apiBase: provider['apiBase'] as String,
                                apiKey: controller.text.trim(),
                                model: selectedModel,
                                provider: provider['provider'] as String,
                              );
                              setDialogState(() {
                                testing = false;
                                testResult = '${ok ? "✓" : "✗"} $msg';
                              });
                            },
                      icon: testing
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: Text(testing ? '测试中...' : '测试连接'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF30363D)),
                      ),
                    ),
                    if (testResult != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          testResult!,
                          style: TextStyle(
                            fontSize: 13,
                            color: testResult!.startsWith('✓') ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((provider['keyUrl'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(provider['keyUrl'])),
                    child: Text(
                      '获取 API Key \u2192',
                      style: TextStyle(color: Colors.blue[300], fontSize: 13),
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
                  await ConfigService.removeProvider(provider['id']);
                  if (ctx.mounted) Navigator.pop(ctx, '__removed__');
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, '$selectedModel|||${controller.text}'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (result == '__removed__') {
      setState(() => _configuredIds.remove(provider['id']));
      return;
    }

    final parts = result.split('|||');
    final model = parts[0];
    final apiKey = parts.length > 1 ? parts[1].trim() : '';

    if (isOllama || apiKey.isNotEmpty) {
      await ConfigService.setProvider(
        providerId: provider['id'] as String,
        apiKey: apiKey,
        apiBase: provider['apiBase'] as String,
        defaultModel: model,
      );
      setState(() => _configuredIds.add(provider['id'] as String));
    }
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
                    '模型配置',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_configuredIds.isNotEmpty)
                    Text(
                      '已配置 ${_configuredIds.length} 个供应商',
                      style: TextStyle(color: Colors.green[300], fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('配置 AI 模型提供商 — 保存后自动写入 openclaw.json',
                  style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '国产模型'),
                  Tab(text: '海外模型'),
                ],
                indicatorColor: const Color(0xFF7C3AED),
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: Colors.grey[500],
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

  Widget _buildProviderCard(Map<String, dynamic> provider, bool configured) {
    final freeQuota = provider['freeQuota'] as String? ?? '';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: configured ? Colors.green.withValues(alpha: 0.5) : const Color(0xFF30363D),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (configured)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              provider['description'],
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (freeQuota.isNotEmpty)
              Chip(
                label: Text(freeQuota, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.green.withValues(alpha: 0.15),
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
                      backgroundColor: configured
                          ? const Color(0xFF30363D)
                          : const Color(0xFF7C3AED),
                    ),
                    child: Text(configured ? '修改配置' : '配置'),
                  ),
                ),
                if ((provider['keyUrl'] as String).isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(provider['keyUrl'])),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: '获取 Key',
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF30363D)),
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
