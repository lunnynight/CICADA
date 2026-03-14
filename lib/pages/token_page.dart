import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app/theme/cicada_colors.dart';
import '../models/diagnostic.dart';
import '../services/token_service.dart';

class TokenPage extends StatefulWidget {
  const TokenPage({super.key});

  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  List<TokenRecord> _records = [];
  TokenStatistics _stats = const TokenStatistics.empty();
  bool _loading = true;
  String? _error;
  int _selectedTimeRange = 7; // days

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final records = await TokenService.parseLogs();
      // Filter by time range
      final cutoff = DateTime.now().subtract(Duration(days: _selectedTimeRange));
      final filtered = records.where((r) => r.timestamp.isAfter(cutoff)).toList();
      final stats = TokenService.calculateStatistics(filtered);

      if (!mounted) return;
      setState(() {
        _records = filtered;
        _stats = stats;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'TOKEN ANALYTICS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Time range selector
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7天')),
                  ButtonSegment(value: 30, label: Text('30天')),
                  ButtonSegment(value: 90, label: Text('90天')),
                ],
                selected: {_selectedTimeRange},
                onSelectionChanged: (selected) {
                  setState(() => _selectedTimeRange = selected.first);
                  _loadData();
                },
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _loadData,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('刷新'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.data,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Token 使用分析与趋势',
            style: TextStyle(
              color: CicadaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (_error != null) ...[
            _buildErrorCard(),
          ] else ...[
            // Stats cards
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Charts row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTrendChart(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModelChart(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent records table
            _buildRecentRecordsTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CicadaColors.alert.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.alert),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: CicadaColors.alert, size: 48),
          const SizedBox(height: 12),
          Text(
            '加载失败: $_error',
            style: const TextStyle(color: CicadaColors.alert),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatCard(
        label: '总调用次数',
        value: _stats.totalRecords.toString(),
        icon: Icons.replay,
        color: CicadaColors.data,
      ),
      _StatCard(
        label: '总 Token 数',
        value: _formatNumber(_stats.totalTokens),
        icon: Icons.data_usage,
        color: CicadaColors.energy,
      ),
      _StatCard(
        label: '输入 Token',
        value: _formatNumber(_stats.totalInputTokens),
        icon: Icons.input,
        color: CicadaColors.ok,
      ),
      _StatCard(
        label: '输出 Token',
        value: _formatNumber(_stats.totalOutputTokens),
        icon: Icons.output,
        color: Colors.orange,
      ),
      _StatCard(
        label: '平均/请求',
        value: _formatNumber(_stats.averageTokensPerRequest),
        icon: Icons.analytics,
        color: CicadaColors.accent,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatCard stat) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 16, color: stat.color),
              const SizedBox(width: 6),
              Text(
                stat.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: CicadaColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: stat.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_stats.dailyTrend.isEmpty) {
      return _buildEmptyChart('暂无趋势数据');
    }

    // Limit to last 30 points for readability
    final data = _stats.dailyTrend.length > 30
        ? _stats.dailyTrend.sublist(_stats.dailyTrend.length - 30)
        : _stats.dailyTrend;

    final maxY = data.map((d) => d.tokens.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Token 使用趋势',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: CicadaColors.border,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompactNumber(value.toInt()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: CicadaColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.length / 6).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) return const SizedBox();
                        return Text(
                          data[index].date.substring(5), // MM-DD
                          style: const TextStyle(
                            fontSize: 10,
                            color: CicadaColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.tokens.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: CicadaColors.data,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: CicadaColors.data.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelChart() {
    if (_stats.modelDistribution.isEmpty) {
      return _buildEmptyChart('暂无模型数据');
    }

    // Take top 5 models
    final data = _stats.modelDistribution.take(5).toList();
    final total = data.map((d) => d.tokens).reduce((a, b) => a + b);

    final sections = data.asMap().entries.map((e) {
      final colors = [
        CicadaColors.data,
        CicadaColors.energy,
        CicadaColors.ok,
        Colors.orange,
        CicadaColors.accent,
      ];
      final percentage = e.value.tokens / total;
      return PieChartSectionData(
        value: e.value.tokens.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(1)}%',
        color: colors[e.key % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '模型分布',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.asMap().entries.map((e) {
                    final colors = [
                      CicadaColors.data,
                      CicadaColors.energy,
                      CicadaColors.ok,
                      Colors.orange,
                      CicadaColors.accent,
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _truncateModelName(e.value.model),
                            style: const TextStyle(
                              fontSize: 11,
                              color: CicadaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: CicadaColors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildRecentRecordsTable() {
    final recent = _records.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '最近调用',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '显示最近 ${recent.length} 条',
                style: const TextStyle(
                  fontSize: 11,
                  color: CicadaColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '暂无记录',
                  style: TextStyle(color: CicadaColors.textTertiary),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: CicadaColors.border),
                    ),
                  ),
                  children: [
                    _buildTableHeader('时间'),
                    _buildTableHeader('模型'),
                    _buildTableHeader('输入', align: TextAlign.right),
                    _buildTableHeader('输出', align: TextAlign.right),
                    _buildTableHeader('总计', align: TextAlign.right),
                  ],
                ),
                // Rows
                ...recent.map((r) => TableRow(
                  children: [
                    _buildTableCell(_formatDateTime(r.timestamp)),
                    _buildTableCell(_truncateModelName(r.model)),
                    _buildTableCell(_formatNumber(r.inputTokens), align: TextAlign.right),
                    _buildTableCell(_formatNumber(r.outputTokens), align: TextAlign.right),
                    _buildTableCell(
                      _formatNumber(r.totalTokens),
                      align: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {TextAlign? align}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CicadaColors.textTertiary,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildTableCell(String text, {TextAlign? align, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: style ?? const TextStyle(
          fontSize: 12,
          color: CicadaColors.textSecondary,
        ),
        textAlign: align,
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatCompactNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _truncateModelName(String name) {
    if (name.length <= 20) return name;
    return '${name.substring(0, 18)}...';
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
