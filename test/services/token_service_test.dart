import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/services/token_service.dart';
import 'package:cicada/models/diagnostic.dart';

void main() {
  // Shared test data
  final record1 = TokenRecord(
    timestamp: DateTime(2024, 1, 15, 10, 30),
    model: 'claude-3-5-sonnet',
    inputTokens: 100,
    outputTokens: 50,
    cacheTokens: 10,
  );

  final record2 = TokenRecord(
    timestamp: DateTime(2024, 1, 16, 14, 0),
    model: 'gpt-4',
    inputTokens: 200,
    outputTokens: 80,
    cacheTokens: 0,
  );

  final record3 = TokenRecord(
    timestamp: DateTime(2024, 1, 17, 9, 0),
    model: 'claude-3-5-sonnet',
    inputTokens: 150,
    outputTokens: 60,
    cacheTokens: 20,
  );

  group('TokenService.calculateStatistics', () {
    test('empty list returns TokenStatistics with totalRecords=0', () {
      final stats = TokenService.calculateStatistics([]);
      expect(stats.totalRecords, 0);
      expect(stats.totalInputTokens, 0);
      expect(stats.totalOutputTokens, 0);
      expect(stats.totalCacheTokens, 0);
      expect(stats.modelDistribution, isEmpty);
      expect(stats.dailyTrend, isEmpty);
      expect(stats.firstRecordDate, isNull);
      expect(stats.lastRecordDate, isNull);
    });

    test('single record totals are correct', () {
      final stats = TokenService.calculateStatistics([record1]);
      expect(stats.totalRecords, 1);
      expect(stats.totalInputTokens, 100);
      expect(stats.totalOutputTokens, 50);
      expect(stats.totalCacheTokens, 10);
      expect(stats.totalTokens, 160);
      expect(stats.averageTokensPerRequest, 160);
    });

    test('multiple records aggregate correctly', () {
      // Records sorted newest-first as parseLogs returns them
      final stats = TokenService.calculateStatistics([record3, record2, record1]);
      expect(stats.totalRecords, 3);
      expect(stats.totalInputTokens, 450); // 100+200+150
      expect(stats.totalOutputTokens, 190); // 50+80+60
      expect(stats.totalCacheTokens, 30); // 10+0+20
    });

    test('model distribution sorted by tokens descending', () {
      final stats = TokenService.calculateStatistics([record3, record2, record1]);
      expect(stats.modelDistribution.length, 2);
      // claude-3-5-sonnet: (100+50+10) + (150+60+20) = 390
      // gpt-4: 200+80+0 = 280
      expect(stats.modelDistribution[0].model, 'claude-3-5-sonnet');
      expect(stats.modelDistribution[0].tokens, 390);
      expect(stats.modelDistribution[1].model, 'gpt-4');
      expect(stats.modelDistribution[1].tokens, 280);
    });

    test('daily trend sorted by date ascending', () {
      final stats = TokenService.calculateStatistics([record3, record2, record1]);
      expect(stats.dailyTrend.length, 3);
      expect(stats.dailyTrend[0].date, '2024-01-15');
      expect(stats.dailyTrend[1].date, '2024-01-16');
      expect(stats.dailyTrend[2].date, '2024-01-17');
      // Each day has one record's total tokens
      expect(stats.dailyTrend[0].tokens, 160); // record1
      expect(stats.dailyTrend[1].tokens, 280); // record2
      expect(stats.dailyTrend[2].tokens, 230); // record3
    });

    test('firstRecordDate and lastRecordDate are correct', () {
      // Input sorted newest-first: record3, record2, record1
      final stats = TokenService.calculateStatistics([record3, record2, record1]);
      // firstRecordDate = records.last.timestamp (oldest)
      expect(stats.firstRecordDate, record1.timestamp);
      // lastRecordDate = records.first.timestamp (newest)
      expect(stats.lastRecordDate, record3.timestamp);
    });
  });

  group('TokenService.getRecentRecords', () {
    test('returns first N records', () {
      final result = TokenService.getRecentRecords([record3, record2, record1], 2);
      expect(result.length, 2);
      expect(result[0].model, record3.model);
      expect(result[1].model, record2.model);
    });

    test('count larger than list returns all', () {
      final result = TokenService.getRecentRecords([record1], 10);
      expect(result.length, 1);
    });

    test('count of zero returns empty', () {
      final result = TokenService.getRecentRecords([record1, record2], 0);
      expect(result, isEmpty);
    });
  });

  group('TokenService.filterByDateRange', () {
    test('excludes records before start', () {
      final result = TokenService.filterByDateRange(
        [record3, record2, record1],
        DateTime(2024, 1, 15, 12, 0), // after record1
        DateTime(2024, 1, 18),
      );
      expect(result.length, 2);
      expect(result.any((r) => r.timestamp == record1.timestamp), isFalse);
    });

    test('excludes records after end', () {
      final result = TokenService.filterByDateRange(
        [record3, record2, record1],
        DateTime(2024, 1, 14),
        DateTime(2024, 1, 16, 15, 0), // after record2 but before record3
      );
      expect(result.length, 2);
      expect(result.any((r) => r.timestamp == record3.timestamp), isFalse);
    });

    test('includes only records within range (exclusive boundaries)', () {
      final result = TokenService.filterByDateRange(
        [record3, record2, record1],
        DateTime(2024, 1, 15, 10, 30), // exactly record1 timestamp
        DateTime(2024, 1, 17, 9, 0), // exactly record3 timestamp
      );
      // isAfter and isBefore are exclusive, so only record2 matches
      expect(result.length, 1);
      expect(result[0].model, 'gpt-4');
    });
  });

  group('TokenService.filterByModel', () {
    test('returns only matching model records', () {
      final result = TokenService.filterByModel(
        [record3, record2, record1],
        'claude-3-5-sonnet',
      );
      expect(result.length, 2);
      expect(result.every((r) => r.model == 'claude-3-5-sonnet'), isTrue);
    });

    test('returns empty list when no match', () {
      final result = TokenService.filterByModel(
        [record1, record2],
        'nonexistent-model',
      );
      expect(result, isEmpty);
    });
  });
}
