import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../data/clawhub_catalog.dart';
import '../services/skill_installer_service.dart';

class ClawHubPage extends StatefulWidget {
  const ClawHubPage({super.key});

  @override
  State<ClawHubPage> createState() => _ClawHubPageState();
}

class _ClawHubPageState extends State<ClawHubPage> {
  String _search = '';
  String _categoryFilter = '全部';
  List<ClawHubSkill> _filtered = ClawHubCatalog.skills;
  Set<String> _installed = {};
  final Set<String> _installing = {};

  @override
  void initState() {
    super.initState();
    _loadInstalled();
  }

  Future<void> _loadInstalled() async {
    final skills = await SkillInstallerService.scanInstalled();
    if (mounted) {
      setState(() {
        _installed = skills.map((s) => s.slug).toSet();
      });
    }
  }

  Future<void> _installSkill(ClawHubSkill skill) async {
    setState(() => _installing.add(skill.slug));
    try {
      await SkillInstallerService.installFromClawHub(skill.slug);
      await _loadInstalled();
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.slug));
  }

  Future<void> _uninstallSkill(ClawHubSkill skill) async {
    setState(() => _installing.add(skill.slug));
    try {
      await SkillInstallerService.uninstall(skill.slug);
      await _loadInstalled();
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.slug));
  }

  void _applyFilter() {
    var base = ClawHubCatalog.skills.toList();

    // Category
    if (_categoryFilter != '全部') {
      base = base.where((s) => s.category == _categoryFilter).toList();
    }

    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      base = base
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.slug.toLowerCase().contains(q))
          .toList();
    }

    // Sort by score desc
    base.sort((a, b) => b.score.compareTo(a.score));

    setState(() => _filtered = base);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with ClawHub link
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ClawHub banner
              InkWell(
                onTap: () => launchUrl(Uri.parse(ClawHubCatalog.siteUrl)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CicadaColors.data.withValues(alpha: 0.15),
                        CicadaColors.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: CicadaColors.data.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: CicadaColors.data, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ClawHub — Agent Skill Store',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: CicadaColors.textPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ClawHubCatalog.siteUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: CicadaColors.data.withValues(alpha: 0.8),
                                fontFamily: 'monospace',
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        color: CicadaColors.data,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Search
              TextField(
                style: const TextStyle(
                  color: CicadaColors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '搜索 ClawHub 技能...',
                  hintStyle: const TextStyle(
                    color: CicadaColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: CicadaColors.data,
                    size: 18,
                  ),
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
                      color: CicadaColors.data,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                ),
                onChanged: (v) {
                  _search = v;
                  _applyFilter();
                },
              ),
              const SizedBox(height: 12),
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ClawHubCatalog.categories.map((cat) {
                    final selected = _categoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: selected
                                ? CicadaColors.background
                                : CicadaColors.textSecondary,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          _categoryFilter = cat;
                          _applyFilter();
                        },
                        selectedColor: CicadaColors.data,
                        backgroundColor: CicadaColors.surface,
                        side: BorderSide(
                          color: selected
                              ? CicadaColors.data
                              : CicadaColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_filtered.length} 个技能',
                style: const TextStyle(
                  fontSize: 11,
                  color: CicadaColors.textTertiary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    '未找到匹配的技能',
                    style: TextStyle(
                      color: CicadaColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 185,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) => _ClawHubSkillCard(
                    skill: _filtered[i],
                    isInstalled: _installed.contains(_filtered[i].slug),
                    isInstalling: _installing.contains(_filtered[i].slug),
                    onInstall: () => _installSkill(_filtered[i]),
                    onUninstall: () => _uninstallSkill(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ClawHubSkillCard extends StatelessWidget {
  final ClawHubSkill skill;
  final bool isInstalled;
  final bool isInstalling;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const _ClawHubSkillCard({
    required this.skill,
    required this.isInstalled,
    required this.isInstalling,
    required this.onInstall,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        border: Border(
          top: BorderSide(
            color: isInstalled ? CicadaColors.ok : CicadaColors.data,
            width: 2,
          ),
          left: const BorderSide(color: CicadaColors.border),
          right: const BorderSide(color: CicadaColors.border),
          bottom: const BorderSide(color: CicadaColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                skill.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: CicadaColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isInstalled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: CicadaColors.ok.withValues(alpha: 0.12),
                    border: Border.all(color: CicadaColors.ok.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'INSTALLED',
                    style: TextStyle(
                      fontSize: 8,
                      color: CicadaColors.ok,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: CicadaColors.data.withValues(alpha: 0.12),
              border: Border.all(
                color: CicadaColors.data.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              skill.category,
              style: const TextStyle(
                fontSize: 9,
                color: CicadaColors.data,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Expanded(
            child: Text(
              skill.description,
              style: const TextStyle(
                fontSize: 11.5,
                color: CicadaColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Action row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: isInstalling
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CicadaColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CicadaColors.data,
                            ),
                          ),
                        )
                      : isInstalled
                          ? OutlinedButton(
                              onPressed: onUninstall,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CicadaColors.muted,
                                side: const BorderSide(color: CicadaColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                              child: const Text('[ REMOVE ]'),
                            )
                          : ElevatedButton(
                              onPressed: onInstall,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CicadaColors.data,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                ),
                                elevation: 0,
                              ),
                              child: const Text('[ INSTALL ]'),
                            ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => launchUrl(Uri.parse(skill.url)),
                icon: Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: CicadaColors.data.withValues(alpha: 0.6),
                ),
                tooltip: '在浏览器中查看',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: CicadaColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
