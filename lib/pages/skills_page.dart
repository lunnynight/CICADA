import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/cicada_colors.dart';
import '../models/skill.dart';
import '../providers/page_data_provider.dart';
import '../services/bundled_skill_service.dart';
import '../services/installer_service.dart';
import '../services/skill_installer_service.dart';
import 'clawhub_page.dart';
import 'skill_card.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: CicadaColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: CicadaColors.accent,
            labelColor: CicadaColors.accent,
            unselectedLabelColor: CicadaColors.textSecondary,
            labelStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
            tabs: const [
              Tab(text: 'BUNDLED'),
              Tab(text: 'CLAWHUB STORE'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BundledSkillsTab(),
              ClawHubPage(),
            ],
          ),
        ),
      ],
    );
  }
}

class _BundledSkillsTab extends ConsumerStatefulWidget {
  const _BundledSkillsTab();

  @override
  ConsumerState<_BundledSkillsTab> createState() => _BundledSkillsTabState();
}

class _BundledSkillsTabState extends ConsumerState<_BundledSkillsTab> {
  List<Skill> _filtered = [];
  final Set<String> _installing = {};
  bool _syncing = false;
  String _search = '';
  String _categoryFilter = '全部';
  OpenClawStatus _openclawStatus = OpenClawStatus.notInstalled;

  static const _categories = ['全部', '内置', '已安装', '通讯', '开发', '效率', '笔记', '智能家居', '媒体', 'AI', '系统'];

  @override
  void initState() {
    super.initState();
    _checkOpenClawStatus();
  }

  Future<void> _checkOpenClawStatus() async {
    final status = await InstallerService.getOpenClawStatus();
    if (mounted) setState(() => _openclawStatus = status);
  }

  void _applyFilter(List<Skill> allSkills) {
    List<Skill> base;
    if (_search.isEmpty) {
      base = List.of(allSkills);
    } else {
      final q = _search.toLowerCase();
      base =
          allSkills
              .where(
                (s) =>
                    s.name.toLowerCase().contains(q) ||
                    s.slug.toLowerCase().contains(q) ||
                    s.description.toLowerCase().contains(q) ||
                    s.author.toLowerCase().contains(q),
              )
              .toList();
    }

    // Category filter
    switch (_categoryFilter) {
      case '内置':
        base = base.where((s) => s.isBundled).toList();
        break;
      case '已安装':
        base = base.where((s) => s.isInstalled).toList();
        break;
      case '代码质量':
        base =
            base
                .where(
                  (s) =>
                      s.slug.contains('review') ||
                      s.slug.contains('refactor') ||
                      s.description.contains('质量') ||
                      s.description.contains('重构'),
                )
                .toList();
        break;
      case '文档':
        base =
            base
                .where(
                  (s) =>
                      s.slug.contains('doc') ||
                      s.slug.contains('i18n') ||
                      s.description.contains('文档') ||
                      s.description.contains('翻译'),
                )
                .toList();
        break;
      case '测试':
        base =
            base
                .where(
                  (s) =>
                      s.slug.contains('test') || s.description.contains('测试'),
                )
                .toList();
        break;
      default:
        break;
    }

    _filtered = base;
    // Bundled skills first
    _filtered.sort((a, b) {
      if (a.isBundled && !b.isBundled) return -1;
      if (!a.isBundled && b.isBundled) return 1;
      return b.downloads.compareTo(a.downloads);
    });
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
    });
  }

  Future<void> _install(Skill skill) async {
    setState(() => _installing.add(skill.slug));
    try {
      if (skill.isBundled) {
        final manifest = await BundledSkillService.loadManifest();
        final meta = manifest.firstWhere((m) => m.name == skill.slug);
        await BundledSkillService.installBundled(meta);
      } else {
        await SkillInstallerService.installFromClawHub(skill.slug);
      }
      ref.invalidate(skillsProvider);
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.slug));
  }

  Future<void> _uninstall(Skill skill) async {
    setState(() => _installing.add(skill.slug));
    try {
      await SkillInstallerService.uninstall(skill.slug);
      ref.invalidate(skillsProvider);
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.slug));
  }

  Future<void> _syncBundled() async {
    setState(() => _syncing = true);
    final count = await BundledSkillService.syncBundledSkills();
    ref.invalidate(skillsProvider);
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 ? '已同步 $count 个内置技能' : '内置技能已是最新'),
          backgroundColor: CicadaColors.surface,
          behavior: SnackBarBehavior.floating,
          width: 280,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);

    return skillsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CicadaColors.data),
      ),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (allSkills) {
        _applyFilter(allSkills);
        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SKILL ARMORY',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: CicadaColors.accent,
                          fontFamily: 'monospace',
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '技能武器库 · OPENCLAW EXTENSIONS',
                        style: TextStyle(
                          color: CicadaColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _syncing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CicadaColors.accent,
                        ),
                      )
                      : OutlinedButton.icon(
                        onPressed: _syncBundled,
                        icon: const Icon(
                          Icons.download_for_offline_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          '同步内置技能',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CicadaColors.accent,
                          side: const BorderSide(
                            color: CicadaColors.accent,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: CicadaColors.muted),
                    tooltip: '刷新',
                    onPressed: () => ref.invalidate(skillsProvider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // OpenClaw status warning
              if (_openclawStatus != OpenClawStatus.running)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _openclawStatus == OpenClawStatus.notInstalled
                        ? CicadaColors.error.withValues(alpha: 0.1)
                        : CicadaColors.warning.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _openclawStatus == OpenClawStatus.notInstalled
                          ? CicadaColors.error.withValues(alpha: 0.3)
                          : CicadaColors.warning.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _openclawStatus == OpenClawStatus.notInstalled
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        color: _openclawStatus == OpenClawStatus.notInstalled
                            ? CicadaColors.error
                            : CicadaColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _openclawStatus == OpenClawStatus.notInstalled
                              ? 'OpenClaw 未安装 - 技能功能不可用'
                              : 'OpenClaw Gateway 未运行 - 请先启动 OpenClaw',
                          style: TextStyle(
                            color: _openclawStatus == OpenClawStatus.notInstalled
                                ? CicadaColors.error
                                : CicadaColors.warning,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Tactical search field
              TextField(
                style: const TextStyle(
                  color: CicadaColors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '输入技能名称或关键词...',
                  hintStyle: const TextStyle(
                    color: CicadaColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search,
                          color: CicadaColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SEARCH //',
                          style: TextStyle(
                            color: CicadaColors.accent.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  filled: true,
                  fillColor: CicadaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: CicadaColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: CicadaColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: CicadaColors.accent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                ),
                onChanged: _onSearch,
              ),
              const SizedBox(height: 12),
              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _categories.map((cat) {
                        final selected = _categoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                                color:
                                    selected
                                        ? CicadaColors.background
                                        : CicadaColors.textSecondary,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _categoryFilter = cat;
                              });
                            },
                            selectedColor: CicadaColors.accent,
                            backgroundColor: CicadaColors.surface,
                            side: BorderSide(
                              color:
                                  selected
                                      ? CicadaColors.accent
                                      : CicadaColors.border,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Expanded(
          child:
              _filtered.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 56,
                          color: CicadaColors.border,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NO TARGETS FOUND',
                          style: TextStyle(
                            color: CicadaColors.textSecondary,
                            fontSize: 18,
                            fontFamily: 'monospace',
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '调整搜索条件或浏览全部技能',
                          style: TextStyle(
                            color: CicadaColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 210,
                        ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final skill = _filtered[i];
                      return SkillCard(
                        skill: skill,
                        isInstalled: skill.isInstalled,
                        isInstalling: _installing.contains(skill.slug),
                        openclawRunning: _openclawStatus == OpenClawStatus.running,
                        onInstall: () => _install(skill),
                        onUninstall: () => _uninstall(skill),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

