import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../models/dashboard_stats.dart';
import '../services/installer_service.dart';
import '../services/token_service.dart';
import '../services/bundled_skill_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_sessions_list.dart';
import '../widgets/attention_panel.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardStats _stats = DashboardStats.empty;
  List<RecentSession> _recentSessions = [];
  List<AttentionItem> _attentionItems = [];
  Timer? _refreshTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final stats = await _computeStats();
    if (!mounted) return;

    final sessions = await _loadRecentSessions();
    if (!mounted) return;

    final attention = await _computeAttentionItems();
    if (!mounted) return;

    setState(() {
      _stats = stats;
      _recentSessions = sessions;
      _attentionItems = attention;
      _loading = false;
    });
  }

  Future<DashboardStats> _computeStats() async {
    // Check service status
    final serviceRunning = await InstallerService.isGatewayRunning();
    final serviceStatus = serviceRunning ? '正常' : '未运行';

    // Parse token logs
    final records = await TokenService.parseLogs();
    final now = DateTime.now();
    final todayRecords = records.where((r) {
      return r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day;
    }).toList();

    final todayTokens = todayRecords.fold<int>(
      0,
      (sum, r) => sum + r.inputTokens + r.outputTokens,
    );
    final todayMessages = todayRecords.length;

    // Estimate cost (rough: $3/1M input, $15/1M output)
    final todayCost = todayRecords.fold<double>(0.0, (sum, r) {
      return sum + (r.inputTokens * 3 / 1000000) + (r.outputTokens * 15 / 1000000);
    });

    // Count skills
    final allSkills = await BundledSkillService.loadManifest();
    int enabledCount = 0;
    for (final skill in allSkills) {
      if (await BundledSkillService.isInstalled(skill.name)) {
        enabledCount++;
      }
    }

    // Active sessions (placeholder - would need session tracking)
    final activeSessions = 0;

    return DashboardStats(
      todayCost: todayCost,
      todayTokens: todayTokens,
      todayMessages: todayMessages,
      activeSessions: activeSessions,
      enabledSkills: enabledCount,
      totalSkills: allSkills.length,
      serviceRunning: serviceRunning,
      serviceStatus: serviceStatus,
    );
  }

  Future<List<RecentSession>> _loadRecentSessions() async {
    // Placeholder - would need session history tracking
    return [];
  }

  Future<List<AttentionItem>> _computeAttentionItems() async {
    final items = <AttentionItem>[];

    // Check service status
    final serviceRunning = await InstallerService.isGatewayRunning();
    if (!serviceRunning) {
      items.add(AttentionItem(
        level: AttentionLevel.error,
        message: 'OpenClaw Gateway 未运行',
        actionLabel: '启动服务',
        onAction: () => widget.onNavigate?.call(1), // Go to setup page
      ));
    }

    // Check Node.js version
    final nodeResult = await InstallerService.checkNode();
    if (nodeResult.exitCode == 0) {
      final version = nodeResult.stdout.toString().trim();
      if (version.isNotEmpty) {
        final major = int.tryParse(version.split('.').first.replaceAll('v', ''));
        if (major != null && major < 20) {
          items.add(AttentionItem(
            level: AttentionLevel.warning,
            message: 'Node.js 版本过低（当前 $version，建议 v20+）',
          ));
        }
      }
    }

    // Check for skill updates
    final allSkills = await BundledSkillService.loadManifest();
    int updateCount = 0;
    for (final skill in allSkills) {
      if (await BundledSkillService.needsUpdate(skill)) {
        updateCount++;
      }
    }
    if (updateCount > 0) {
      items.add(AttentionItem(
        level: AttentionLevel.warning,
        message: '有 $updateCount 个技能需要更新',
        actionLabel: '查看',
        onAction: () => widget.onNavigate?.call(8), // Go to skills page
      ));
    }

    // All good
    if (items.isEmpty && serviceRunning) {
      items.add(const AttentionItem(
        level: AttentionLevel.info,
        message: '✓ 系统健康，无问题',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(CicadaColors.energy),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats cards
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Recent sessions
          RecentSessionsList(
            sessions: _recentSessions,
            onSessionTap: (key) {
              widget.onNavigate?.call(3);
            },
          ),
          const SizedBox(height: 24),

          // Attention panel
          AttentionPanel(items: _attentionItems),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            label: '今日花费',
            value: '\$${_stats.todayCost.toStringAsFixed(2)}',
            hint: '${(_stats.todayTokens / 1000).toStringAsFixed(0)}K tokens',
            iconColor: CicadaColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.chat_bubble_outline,
            label: '会话数',
            value: '${_stats.todayMessages}',
            hint: '今日消息',
            iconColor: CicadaColors.data,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.extension,
            label: '技能',
            value: '${_stats.enabledSkills}/${_stats.totalSkills}',
            hint: '已启用',
            iconColor: CicadaColors.energy,
            onTap: () {
              widget.onNavigate?.call(8);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: _stats.serviceRunning
                ? Icons.check_circle
                : Icons.error_outline,
            label: '服务状态',
            value: _stats.serviceStatus,
            hint: _stats.serviceRunning ? '运行中' : '已停止',
            iconColor: _stats.serviceRunning ? CicadaColors.ok : CicadaColors.alert,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        QuickActionButton(
          icon: Icons.chat,
          label: '开始对话',
          onPressed: () {
            widget.onNavigate?.call(2);
          },
          backgroundColor: CicadaColors.energy,
        ),
        const SizedBox(width: 16),
        QuickActionButton(
          icon: Icons.history,
          label: '查看历史',
          onPressed: () {
            widget.onNavigate?.call(3);
          },
          backgroundColor: CicadaColors.data,
        ),
        const SizedBox(width: 16),
        QuickActionButton(
          icon: Icons.extension,
          label: '安装技能',
          onPressed: () {
            widget.onNavigate?.call(8);
          },
          backgroundColor: CicadaColors.accent,
        ),
        const SizedBox(width: 16),
        QuickActionButton(
          icon: Icons.open_in_browser,
          label: '打开控制台',
          onPressed: () async {
            final url = Uri.parse('http://localhost:18789');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          backgroundColor: CicadaColors.ok,
        ),
      ],
    );
  }
}
