/// Dashboard statistics data model
class DashboardStats {
  final double todayCost;
  final int todayTokens;
  final int todayMessages;
  final int activeSessions;
  final int enabledSkills;
  final int totalSkills;
  final bool serviceRunning;
  final String serviceStatus;

  const DashboardStats({
    required this.todayCost,
    required this.todayTokens,
    required this.todayMessages,
    required this.activeSessions,
    required this.enabledSkills,
    required this.totalSkills,
    required this.serviceRunning,
    required this.serviceStatus,
  });

  static const empty = DashboardStats(
    todayCost: 0.0,
    todayTokens: 0,
    todayMessages: 0,
    activeSessions: 0,
    enabledSkills: 0,
    totalSkills: 0,
    serviceRunning: false,
    serviceStatus: '未知',
  );
}

/// Recent session item
class RecentSession {
  final String title;
  final String timeAgo;
  final String sessionKey;

  const RecentSession({
    required this.title,
    required this.timeAgo,
    required this.sessionKey,
  });
}

/// Attention item level
enum AttentionLevel {
  info,
  warning,
  error,
}

/// Attention item for dashboard alerts
class AttentionItem {
  final AttentionLevel level;
  final String message;
  final String? actionLabel;
  final void Function()? onAction;

  const AttentionItem({
    required this.level,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}
