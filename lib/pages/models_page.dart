import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preset_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('apikey_')).toSet();
    if (!mounted) return;
    setState(() {
      _cnProviders = cn['providers'] as List;
      _intlProviders = intl['providers'] as List;
      _configuredIds = keys.map((k) => k.replaceFirst('apikey_', '')).toSet();
    });
  }

  Future<void> _showConfigDialog(Map<String, dynamic> provider) async {
    final controller = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('apikey_${provider['id']}');
    if (existing != null) controller.text = existing;

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        title: Text('配置 ${provider['name']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Base: ${provider['apiBase']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: '输入你的 API Key',
                ),
                obscureText: true,
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
                await prefs.remove('apikey_${provider['id']}');
                if (ctx.mounted) Navigator.pop(ctx, '__removed__');
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result == '__removed__') {
      setState(() => _configuredIds.remove(provider['id']));
      return;
    }
    if (result.trim().isNotEmpty) {
      await prefs.setString('apikey_${provider['id']}', result.trim());
      setState(() => _configuredIds.add(provider['id']));
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
              const Text(
                '模型配置',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('配置 AI 模型提供商的 API Key', style: TextStyle(color: Colors.grey[500])),
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
