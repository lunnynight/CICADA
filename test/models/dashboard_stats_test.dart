import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/dashboard_stats.dart';

void main() {
  group('DashboardStats', () {
    test('empty constant has zero values', () {
      const stats = DashboardStats.empty;
      expect(stats.todayCost, 0.0);
      expect(stats.todayTokens, 0);
      expect(stats.todayMessages, 0);
      expect(stats.activeSessions, 0);
      expect(stats.enabledSkills, 0);
      expect(stats.totalSkills, 0);
      expect(stats.serviceRunning, false);
      expect(stats.serviceStatus, '未知');
    });

    test('constructor sets all fields', () {
      const stats = DashboardStats(
        todayCost: 1.23,
        todayTokens: 500,
        todayMessages: 10,
        activeSessions: 2,
        enabledSkills: 3,
        totalSkills: 6,
        serviceRunning: true,
        serviceStatus: '运行中',
      );
      expect(stats.todayCost, 1.23);
      expect(stats.todayTokens, 500);
      expect(stats.todayMessages, 10);
      expect(stats.activeSessions, 2);
      expect(stats.enabledSkills, 3);
      expect(stats.totalSkills, 6);
      expect(stats.serviceRunning, true);
      expect(stats.serviceStatus, '运行中');
    });
  });

  group('RecentSession', () {
    test('constructor sets all fields', () {
      const session = RecentSession(
        title: 'Test Session',
        timeAgo: '5分钟前',
        sessionKey: 'session-001',
      );
      expect(session.title, 'Test Session');
      expect(session.timeAgo, '5分钟前');
      expect(session.sessionKey, 'session-001');
    });
  });

  group('AttentionItem', () {
    test('constructor sets level and message', () {
      const item = AttentionItem(
        level: AttentionLevel.warning,
        message: '请检查配置',
      );
      expect(item.level, AttentionLevel.warning);
      expect(item.message, '请检查配置');
      expect(item.actionLabel, isNull);
      expect(item.onAction, isNull);
    });

    test('constructor with optional fields', () {
      var called = false;
      final item = AttentionItem(
        level: AttentionLevel.error,
        message: '服务未运行',
        actionLabel: '启动',
        onAction: () => called = true,
      );
      expect(item.actionLabel, '启动');
      item.onAction!();
      expect(called, true);
    });

    test('AttentionLevel enum has info, warning, error', () {
      expect(AttentionLevel.values, containsAll([
        AttentionLevel.info,
        AttentionLevel.warning,
        AttentionLevel.error,
      ]));
    });
  });
}
