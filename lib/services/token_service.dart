import 'dart:io';
import '../models/diagnostic.dart';

/// Token analysis service for parsing logs and generating usage statistics.
class TokenService {
  /// Parse OpenClaw log files for token usage records.
  /// Searches common log locations based on platform.
  static Future<List<TokenRecord>> parseLogs() async {
    final records = <TokenRecord>[];

    // Determine log directory based on platform
    final logDirs = _getLogDirectories();

    for (final dir in logDirs) {
      try {
        final directory = Directory(dir);
        if (!await directory.exists()) continue;

        // Look for log files
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && _isLogFile(entity.path)) {
            final fileRecords = await _parseLogFile(entity);
            records.addAll(fileRecords);
          }
        }
      } catch (e) {
        // Silently skip inaccessible directories
        continue;
      }
    }

    // Sort by timestamp descending
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return records;
  }

  /// Get possible log directories based on platform.
  static List<String> _getLogDirectories() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    if (Platform.isMacOS) {
      return [
        '$home/.openclaw/logs',
        '$home/Library/Logs/OpenClaw',
        '/var/log/openclaw',
      ];
    } else if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? home;
      return [
        '$home\\.openclaw\\logs',
        '$localAppData\\OpenClaw\\logs',
      ];
    } else if (Platform.isLinux) {
      return [
        '$home/.openclaw/logs',
        '/var/log/openclaw',
        '$home/.local/share/openclaw/logs',
      ];
    }

    return ['$home/.openclaw/logs'];
  }

  /// Check if file is a log file.
  static bool _isLogFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.log') ||
        lower.endsWith('.txt') ||
        lower.contains('log');
  }

  /// Parse a single log file for token records.
  /// Looks for patterns like:
  /// - "tokens: {input: 100, output: 50}"
  /// - "input_tokens: 100, output_tokens: 50"
  /// - "usage: {prompt_tokens: 100, completion_tokens: 50}"
  static Future<List<TokenRecord>> _parseLogFile(File file) async {
    final records = <TokenRecord>[];

    try {
      final lines = await file.readAsLines();
      DateTime? currentTimestamp;

      for (final line in lines) {
        // Try to extract timestamp from line
        final ts = _extractTimestamp(line);
        if (ts != null) {
          currentTimestamp = ts;
        }

        // Try to extract token usage
        final tokens = _extractTokens(line);
        if (tokens != null) {
          records.add(TokenRecord(
            timestamp: currentTimestamp ?? DateTime.now(),
            model: tokens['model'] ?? 'unknown',
            inputTokens: tokens['input'] ?? 0,
            outputTokens: tokens['output'] ?? 0,
            cacheTokens: tokens['cache'] ?? 0,
          ));
        }
      }
    } catch (e) {
      // Skip files that can't be read
    }

    return records;
  }

  /// Extract timestamp from log line.
  /// Supports formats like:
  /// - "2024-01-15 10:30:45"
  /// - "2024-01-15T10:30:45.123Z"
  /// - "[2024-01-15 10:30:45]"
  static DateTime? _extractTimestamp(String line) {
    // ISO format with T
    final isoMatch = RegExp(
      r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?)',
    ).firstMatch(line);
    if (isoMatch != null) {
      try {
        return DateTime.parse(isoMatch.group(1)!);
      } catch (_) {}
    }

    // Standard format: 2024-01-15 10:30:45
    final standardMatch = RegExp(
      r'[(\[]?(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})[)\]]?',
    ).firstMatch(line);
    if (standardMatch != null) {
      try {
        return DateTime.parse(standardMatch.group(1)!);
      } catch (_) {}
    }

    return null;
  }

  /// Extract token counts from log line.
  /// Returns map with keys: input, output, cache, model
  static Map<String, dynamic>? _extractTokens(String line) {
    final result = <String, dynamic>{};

    // Pattern 1: OpenAI-style usage
    // "usage": {"prompt_tokens": 100, "completion_tokens": 50}
    final openaiMatch = RegExp(
      "['\"]?(?:prompt|input)_tokens?['\"]?\\s*[:=]\\s*(\\d+)",
      caseSensitive: false,
    ).firstMatch(line);
    if (openaiMatch != null) {
      result['input'] = int.parse(openaiMatch.group(1)!);
    }

    final openaiOutputMatch = RegExp(
      "['\"]?(?:completion|output)_tokens?['\"]?\\s*[:=]\\s*(\\d+)",
      caseSensitive: false,
    ).firstMatch(line);
    if (openaiOutputMatch != null) {
      result['output'] = int.parse(openaiOutputMatch.group(1)!);
    }

    // Pattern 2: cache_tokens
    final cacheMatch = RegExp(
      "['\"]?cache_tokens?['\"]?\\s*[:=]\\s*(\\d+)",
      caseSensitive: false,
    ).firstMatch(line);
    if (cacheMatch != null) {
      result['cache'] = int.parse(cacheMatch.group(1)!);
    }

    // Pattern 3: total_tokens (if no input/output breakdown)
    if (!result.containsKey('input') && !result.containsKey('output')) {
      final totalMatch = RegExp(
        "['\"]?total_tokens?['\"]?\\s*[:=]\\s*(\\d+)",
        caseSensitive: false,
      ).firstMatch(line);
      if (totalMatch != null) {
        result['input'] = int.parse(totalMatch.group(1)!);
        result['output'] = 0;
      }
    }

    // Extract model name
    final modelMatch = RegExp(
      "['\"]?model['\"]?\\s*[:=]\\s*['\"]?([^'\"\\s,}]+)",
      caseSensitive: false,
    ).firstMatch(line);
    if (modelMatch != null) {
      result['model'] = modelMatch.group(1)!;
    }

    // Only return if we found token data
    if (result.containsKey('input') || result.containsKey('output')) {
      result.putIfAbsent('input', () => 0);
      result.putIfAbsent('output', () => 0);
      result.putIfAbsent('cache', () => 0);
      result.putIfAbsent('model', () => 'unknown');
      return result;
    }

    return null;
  }

  /// Get statistics for the given records.
  static TokenStatistics calculateStatistics(List<TokenRecord> records) {
    if (records.isEmpty) {
      return const TokenStatistics.empty();
    }

    var totalInput = 0;
    var totalOutput = 0;
    var totalCache = 0;
    final modelCounts = <String, int>{};
    final dailyUsage = <String, int>{};

    for (final record in records) {
      totalInput += record.inputTokens;
      totalOutput += record.outputTokens;
      totalCache += record.cacheTokens;

      // Model distribution
      modelCounts[record.model] =
          (modelCounts[record.model] ?? 0) + record.totalTokens;

      // Daily aggregation
      final day = _formatDate(record.timestamp);
      dailyUsage[day] = (dailyUsage[day] ?? 0) + record.totalTokens;
    }

    // Sort daily usage by date
    final sortedDays = dailyUsage.keys.toList()..sort();
    final trendData = sortedDays.map((d) => DailyUsage(d, dailyUsage[d]!)).toList();

    // Model distribution sorted by usage
    final modelDistribution = modelCounts.entries
        .map((e) => ModelUsage(e.key, e.value))
        .toList()
      ..sort((a, b) => b.tokens.compareTo(a.tokens));

    return TokenStatistics(
      totalRecords: records.length,
      totalInputTokens: totalInput,
      totalOutputTokens: totalOutput,
      totalCacheTokens: totalCache,
      modelDistribution: modelDistribution,
      dailyTrend: trendData,
      firstRecordDate: records.last.timestamp,
      lastRecordDate: records.first.timestamp,
    );
  }

  /// Format date as YYYY-MM-DD.
  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Get recent records (last N).
  static List<TokenRecord> getRecentRecords(List<TokenRecord> records, int count) {
    return records.take(count).toList();
  }

  /// Filter records by date range.
  static List<TokenRecord> filterByDateRange(
    List<TokenRecord> records,
    DateTime start,
    DateTime end,
  ) {
    return records.where((r) {
      return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
    }).toList();
  }

  /// Filter records by model.
  static List<TokenRecord> filterByModel(
    List<TokenRecord> records,
    String model,
  ) {
    return records.where((r) => r.model == model).toList();
  }
}

/// Token usage statistics.
class TokenStatistics {
  final int totalRecords;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheTokens;
  final List<ModelUsage> modelDistribution;
  final List<DailyUsage> dailyTrend;
  final DateTime? firstRecordDate;
  final DateTime? lastRecordDate;

  int get totalTokens => totalInputTokens + totalOutputTokens + totalCacheTokens;
  int get averageTokensPerRequest =>
      totalRecords > 0 ? totalTokens ~/ totalRecords : 0;

  const TokenStatistics({
    required this.totalRecords,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCacheTokens,
    required this.modelDistribution,
    required this.dailyTrend,
    this.firstRecordDate,
    this.lastRecordDate,
  });

  const TokenStatistics.empty()
      : totalRecords = 0,
        totalInputTokens = 0,
        totalOutputTokens = 0,
        totalCacheTokens = 0,
        modelDistribution = const [],
        dailyTrend = const [],
        firstRecordDate = null,
        lastRecordDate = null;
}

/// Model usage breakdown.
class ModelUsage {
  final String model;
  final int tokens;

  const ModelUsage(this.model, this.tokens);
}

/// Daily usage for trend chart.
class DailyUsage {
  final String date;
  final int tokens;

  const DailyUsage(this.date, this.tokens);
}
