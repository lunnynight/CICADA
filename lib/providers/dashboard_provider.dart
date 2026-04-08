import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../services/installer_service.dart';
import '../services/token_service.dart';
import '../services/bundled_skill_service.dart';

/// Dashboard statistics (cached across page switches)
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  ref.keepAlive();

  final serviceRunning = await InstallerService.isGatewayRunning();
  final serviceStatus = serviceRunning ? '正常' : '未运行';

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

  final todayCost = todayRecords.fold<double>(0.0, (sum, r) {
    return sum +
        (r.inputTokens * 3 / 1000000) +
        (r.outputTokens * 15 / 1000000);
  });

  final allSkills = await BundledSkillService.loadManifest();
  int enabledCount = 0;
  for (final skill in allSkills) {
    if (await BundledSkillService.isInstalled(skill.name)) {
      enabledCount++;
    }
  }

  return DashboardStats(
    todayCost: todayCost,
    todayTokens: todayTokens,
    todayMessages: todayMessages,
    activeSessions: 0,
    enabledSkills: enabledCount,
    totalSkills: allSkills.length,
    serviceRunning: serviceRunning,
    serviceStatus: serviceStatus,
  );
});

/// Attention items with action IDs (not callbacks)
///
/// Action IDs: 'goto_setup', 'goto_skills', null (no action)
final attentionItemsProvider =
    FutureProvider<List<AttentionItemData>>((ref) async {
  ref.keepAlive();

  final items = <AttentionItemData>[];

  final serviceRunning = await InstallerService.isGatewayRunning();
  if (!serviceRunning) {
    items.add(const AttentionItemData(
      level: AttentionLevel.error,
      message: 'OpenClaw Gateway 未运行',
      actionLabel: '启动服务',
      actionId: 'goto_setup',
    ));
  }

  final nodeResult = await InstallerService.checkNode();
  if (nodeResult.exitCode == 0) {
    final version = nodeResult.stdout.toString().trim();
    if (version.isNotEmpty) {
      final major =
          int.tryParse(version.split('.').first.replaceAll('v', ''));
      if (major != null && major < 20) {
        items.add(AttentionItemData(
          level: AttentionLevel.warning,
          message: 'Node.js 版本过低（当前 $version，建议 v20+）',
        ));
      }
    }
  }

  final allSkills = await BundledSkillService.loadManifest();
  int updateCount = 0;
  for (final skill in allSkills) {
    if (await BundledSkillService.needsUpdate(skill)) {
      updateCount++;
    }
  }
  if (updateCount > 0) {
    items.add(AttentionItemData(
      level: AttentionLevel.warning,
      message: '有 $updateCount 个技能需要更新',
      actionLabel: '查看',
      actionId: 'goto_skills',
    ));
  }

  if (items.isEmpty && serviceRunning) {
    items.add(const AttentionItemData(
      level: AttentionLevel.info,
      message: '✓ 系统健康，无问题',
    ));
  }

  return items;
});

/// Recent sessions (placeholder)
final recentSessionsProvider =
    FutureProvider<List<RecentSession>>((ref) async {
  ref.keepAlive();
  return [];
});

/// Data class for attention items (provider-safe, no callbacks)
class AttentionItemData {
  final AttentionLevel level;
  final String message;
  final String? actionLabel;
  final String? actionId;

  const AttentionItemData({
    required this.level,
    required this.message,
    this.actionLabel,
    this.actionId,
  });

  /// Convert to AttentionItem with a callback mapped from actionId
  AttentionItem toAttentionItem(void Function(String actionId)? onAction) {
    return AttentionItem(
      level: level,
      message: message,
      actionLabel: actionLabel,
      onAction:
          actionId != null && onAction != null
              ? () => onAction(actionId!)
              : null,
    );
  }
}
