import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SkillModel {
  final String name;
  final String description;
  final String author;
  final int downloads;

  const SkillModel({
    required this.name,
    required this.description,
    required this.author,
    required this.downloads,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'unknown',
      downloads: json['downloads'] as int? ?? 0,
    );
  }
}

const _kFallbackSkills = [
  SkillModel(name: 'code-review', description: '自动化代码质量检查与审查建议', author: 'clawhub', downloads: 12400),
  SkillModel(name: 'doc-gen', description: '从代码自动生成 API 文档', author: 'clawhub', downloads: 8900),
  SkillModel(name: 'test-helper', description: '自动生成单元测试用例', author: 'clawhub', downloads: 7300),
  SkillModel(name: 'i18n', description: '多语言国际化翻译支持', author: 'clawhub', downloads: 5100),
  SkillModel(name: 'git-helper', description: '智能 commit message 生成', author: 'clawhub', downloads: 9800),
  SkillModel(name: 'refactor', description: '代码重构与优化建议', author: 'clawhub', downloads: 6200),
];

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  List<SkillModel> _allSkills = [];
  List<SkillModel> _filtered = [];
  Set<String> _installed = {};
  final Set<String> _installing = {};
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchSkills(), _loadInstalled()]);
  }

  Future<void> _fetchSkills() async {
    try {
      final uri = Uri.parse('https://registry.clawhub.org/api/v1/skills').replace(
        queryParameters: {
          'page': '1',
          'limit': '20',
          if (_search.isNotEmpty) 'search': _search,
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List<dynamic> items = data['skills'] ?? data['data'] ?? (data is List ? data : []);
        final skills = items.map((e) => SkillModel.fromJson(e as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _allSkills = skills.isEmpty ? _kFallbackSkills.toList() : skills;
            _applyFilter();
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _allSkills = _kFallbackSkills.toList();
        _applyFilter();
        _loading = false;
      });
    }
  }

  Future<void> _loadInstalled() async {
    try {
      final result = await Process.run('clawhub', ['list'], runInShell: true);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        final names = lines
            .map((l) => l.trim().split(RegExp(r'\s+')).first)
            .where((s) => s.isNotEmpty)
            .toSet();
        if (mounted) setState(() => _installed = names);
      }
    } catch (_) {}
  }

  void _applyFilter() {
    if (_search.isEmpty) {
      _filtered = List.of(_allSkills);
    } else {
      final q = _search.toLowerCase();
      _filtered = _allSkills
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.author.toLowerCase().contains(q))
          .toList();
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _applyFilter();
    });
    if (value.isEmpty) {
      _fetchSkills();
    }
  }

  Future<void> _install(SkillModel skill) async {
    setState(() => _installing.add(skill.name));
    try {
      final process = await Process.start('clawhub', ['install', skill.name], runInShell: true);
      await process.exitCode;
      await _loadInstalled();
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.name));
  }

  Future<void> _uninstall(SkillModel skill) async {
    setState(() => _installing.add(skill.name));
    try {
      final process = await Process.start('clawhub', ['uninstall', skill.name], runInShell: true);
      await process.exitCode;
      await _loadInstalled();
    } catch (_) {}
    if (mounted) setState(() => _installing.remove(skill.name));
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
                    '技能商店',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () {
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('发现和安装 OpenClaw 技能扩展', style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索技能...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                ),
                onChanged: _onSearch,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 56, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text('没有找到匹配的技能', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 180,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final skill = _filtered[i];
                        final isInstalled = _installed.contains(skill.name);
                        final isInstalling = _installing.contains(skill.name);
                        return _SkillCard(
                          skill: skill,
                          isInstalled: isInstalled,
                          isInstalling: isInstalling,
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

class _SkillCard extends StatelessWidget {
  final SkillModel skill;
  final bool isInstalled;
  final bool isInstalling;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  const _SkillCard({
    required this.skill,
    required this.isInstalled,
    required this.isInstalling,
    required this.onInstall,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.extension, color: Color(0xFF7C3AED), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isInstalled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    '已安装',
                    style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            skill.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(skill.author, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 12),
              Icon(Icons.download_outlined, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(_formatDownloads(skill.downloads),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: isInstalling
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF30363D)),
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                    ),
                  )
                : isInstalled
                    ? OutlinedButton(
                        onPressed: onUninstall,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF30363D)),
                          foregroundColor: Colors.grey[400],
                        ),
                        child: const Text('卸载', style: TextStyle(fontSize: 12)),
                      )
                    : ElevatedButton(
                        onPressed: onInstall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('安装', style: TextStyle(fontSize: 12)),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDownloads(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
