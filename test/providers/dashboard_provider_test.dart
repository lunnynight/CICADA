import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/dashboard_stats.dart';
import '../../lib/providers/dashboard_provider.dart';

void main() {
  group('dashboardStatsProvider', () {
    test('returns DashboardStats', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats, isA<DashboardStats>());
      expect(stats.todayTokens, greaterThanOrEqualTo(0));
      expect(stats.todayMessages, greaterThanOrEqualTo(0));
      expect(stats.totalSkills, greaterThanOrEqualTo(0));
    });
  });

  group('attentionItemsProvider', () {
    test('returns a list of AttentionItemData', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = await container.read(attentionItemsProvider.future);
      expect(items, isA<List<AttentionItemData>>());
      expect(items, isNotEmpty);
    });

    test('items have valid level and message', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = await container.read(attentionItemsProvider.future);
      for (final item in items) {
        expect(item.message, isNotEmpty);
      }
    });
  });

  group('recentSessionsProvider', () {
    test('returns a list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sessions = await container.read(recentSessionsProvider.future);
      expect(sessions, isA<List>());
    });
  });

  group('AttentionItemData', () {
    test('toAttentionItem converts with callback', () {
      String? capturedId;
      final data = AttentionItemData(
        level: AttentionLevel.warning,
        message: 'test',
        actionLabel: 'Fix',
        actionId: 'goto_setup',
      );

      final item = data.toAttentionItem((id) => capturedId = id);
      expect(item.message, equals('test'));
      expect(item.actionLabel, equals('Fix'));

      item.onAction?.call();
      expect(capturedId, equals('goto_setup'));
    });

    test('toAttentionItem without actionId has no callback', () {
      final data = AttentionItemData(
        level: AttentionLevel.info,
        message: 'all good',
      );

      final item = data.toAttentionItem((id) {});
      expect(item.onAction, isNull);
    });
  });
}
