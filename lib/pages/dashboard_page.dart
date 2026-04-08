import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/cicada_colors.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../pages/home_page.dart' show NavIndex;
import '../widgets/stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_sessions_list.dart';
import '../widgets/attention_panel.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(attentionItemsProvider);
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleAttentionAction(String actionId) {
    switch (actionId) {
      case 'goto_setup':
        widget.onNavigate?.call(NavIndex.setup);
        break;
      case 'goto_skills':
        widget.onNavigate?.call(NavIndex.skills);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final attentionAsync = ref.watch(attentionItemsProvider);
    final sessionsAsync = ref.watch(recentSessionsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(CicadaColors.energy),
        ),
      ),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (stats) {
        final attentionItems = attentionAsync.valueOrNull ?? [];
        final recentSessions = sessionsAsync.valueOrNull ?? [];

        final items = attentionItems
            .map((d) => d.toAttentionItem(_handleAttentionAction))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsRow(stats),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              RecentSessionsList(
                sessions: recentSessions,
                onSessionTap: (key) {
                  widget.onNavigate?.call(NavIndex.gateway);
                },
              ),
              const SizedBox(height: 24),
              AttentionPanel(items: items),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            label: '今日花费',
            value: '\$${stats.todayCost.toStringAsFixed(2)}',
            hint: '${(stats.todayTokens / 1000).toStringAsFixed(0)}K tokens',
            iconColor: CicadaColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.chat_bubble_outline,
            label: '会话数',
            value: '${stats.todayMessages}',
            hint: '今日消息',
            iconColor: CicadaColors.data,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.extension,
            label: '技能',
            value: '${stats.enabledSkills}/${stats.totalSkills}',
            hint: '已启用',
            iconColor: CicadaColors.energy,
            onTap: () {
              widget.onNavigate?.call(NavIndex.skills);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: stats.serviceRunning
                ? Icons.check_circle
                : Icons.error_outline,
            label: '服务状态',
            value: stats.serviceStatus,
            hint: stats.serviceRunning ? '运行中' : '已停止',
            iconColor: stats.serviceRunning ? CicadaColors.ok : CicadaColors.alert,
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
            widget.onNavigate?.call(NavIndex.gateway);
          },
          backgroundColor: CicadaColors.energy,
        ),
        const SizedBox(width: 16),
        QuickActionButton(
          icon: Icons.history,
          label: '查看历史',
          onPressed: () {
            widget.onNavigate?.call(NavIndex.gateway);
          },
          backgroundColor: CicadaColors.data,
        ),
        const SizedBox(width: 16),
        QuickActionButton(
          icon: Icons.extension,
          label: '安装技能',
          onPressed: () {
            widget.onNavigate?.call(NavIndex.skills);
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
