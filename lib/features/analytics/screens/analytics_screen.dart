import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../admin/screens/admin_shell.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = '30d';
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/analytics',
      child: StreamBuilder<List<ReportModel>>(
        stream: ReportService().getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReports = snapshot.data ?? [];
          final reports = _filterReports(allReports);
          final stats = _AnalyticsStats.from(reports, allReports, _timeRange);

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: allReports.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimeRangeSelector(),
                            const SizedBox(height: 24),
                            _buildTrendCards(stats),
                            const SizedBox(height: 24),
                            _buildTimelineChart(allReports),
                            const SizedBox(height: 24),
                            _buildChartsRow(reports),
                            const SizedBox(height: 24),
                            _buildHeatMaps(reports),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Advanced Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successGreen, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Last updated: ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        const Text(
          'Time Range:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        ...[
          ('7d', 'Last 7 days'),
          ('30d', 'Last 30 days'),
          ('90d', 'Last 90 days'),
          ('all', 'All time'),
        ].map((item) {
          final isSelected = _timeRange == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _timeRange = item.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendCards(_AnalyticsStats stats) {
    return Row(
      children: [
        _TrendCard(
          icon: Icons.assignment_outlined,
          value: '${stats.total}',
          label: 'Total Reports',
          trend: stats.totalTrend,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 16),
        _TrendCard(
          icon: Icons.check_circle_outline,
          value: '${stats.resolved}',
          label: 'Resolved',
          trend: stats.resolvedTrend,
          color: AppTheme.successGreen,
        ),
        const SizedBox(width: 16),
        _TrendCard(
          icon: Icons.schedule,
          value: stats.avgResponseTime,
          label: 'Avg Response',
          trend: stats.responseTrend,
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _TrendCard(
          icon: Icons.speed,
          value: '${stats.resolutionRate}%',
          label: 'Resolution Rate',
          trend: stats.resolutionTrend,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTimelineChart(List<ReportModel> reports) {
    return _ChartCard(
      title: 'Report Trends Over Time',
      subtitle: 'Daily submission patterns',
      child: _InteractiveLineChart(reports: reports, timeRange: _timeRange),
    );
  }

  Widget _buildChartsRow(List<ReportModel> reports) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ChartCard(
            title: 'Reports by Status',
            subtitle: 'Current distribution',
            child: _InteractivePieChart(
              data: _getStatusData(reports),
              touchedIndex: _touchedPieIndex,
              onTouch: (index) => setState(() => _touchedPieIndex = index),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ChartCard(
            title: 'Reports by Category',
            subtitle: 'Type breakdown',
            child: _CategoryDonutChart(reports: reports),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatMaps(List<ReportModel> reports) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ChartCard(
            title: 'Submission Time Heatmap',
            subtitle: 'When residents report issues',
            child: _TimeHeatMap(reports: reports),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ChartCard(
            title: 'Top Barangays',
            subtitle: 'Most active areas',
            child: _BarangayBarChart(reports: reports),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Analytics Data Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data will appear once residents start submitting reports',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  List<ReportModel> _filterReports(List<ReportModel> reports) {
    if (_timeRange == 'all') return reports;

    final now = DateTime.now();
    final days = _timeRange == '7d'
        ? 7
        : _timeRange == '30d'
        ? 30
        : 90;
    final cutoff = now.subtract(Duration(days: days));

    return reports.where((r) => r.createdAt.isAfter(cutoff)).toList();
  }

  Map<String, int> _getStatusData(List<ReportModel> reports) {
    final data = <String, int>{};
    for (final r in reports) {
      data[r.currentStatus] = (data[r.currentStatus] ?? 0) + 1;
    }
    return data;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _AnalyticsStats {
  final int total, resolved, inProgress, pending;
  final String avgResponseTime;
  final int resolutionRate;
  final double totalTrend, resolvedTrend, responseTrend, resolutionTrend;

  _AnalyticsStats({
    required this.total,
    required this.resolved,
    required this.inProgress,
    required this.pending,
    required this.avgResponseTime,
    required this.resolutionRate,
    required this.totalTrend,
    required this.resolvedTrend,
    required this.responseTrend,
    required this.resolutionTrend,
  });

  factory _AnalyticsStats.from(
    List<ReportModel> current,
    List<ReportModel> all,
    String range,
  ) {
    final total = current.length;
    final resolved = current
        .where((r) => r.currentStatus == AppConstants.statusCompleted)
        .length;
    final inProgress = current
        .where((r) => r.currentStatus == AppConstants.statusInProgress)
        .length;
    final pending = current
        .where((r) => r.currentStatus == AppConstants.statusSubmitted)
        .length;

    // Calculate average response time
    Duration totalResponse = Duration.zero;
    int responseCount = 0;
    for (final r in current) {
      if (r.statusHistory.length > 1) {
        totalResponse += r.statusHistory[1].timestamp.difference(r.createdAt);
        responseCount++;
      }
    }
    final avgResponse = responseCount > 0
        ? Duration(minutes: totalResponse.inMinutes ~/ responseCount)
        : Duration.zero;
    final avgResponseStr = avgResponse.inHours > 0
        ? '${avgResponse.inHours}h ${avgResponse.inMinutes % 60}m'
        : '${avgResponse.inMinutes}m';

    final resolutionRate = total > 0 ? ((resolved / total) * 100).round() : 0;

    // Calculate trends
    final trends = _calculateTrends(current, all, range);

    return _AnalyticsStats(
      total: total,
      resolved: resolved,
      inProgress: inProgress,
      pending: pending,
      avgResponseTime: avgResponseStr,
      resolutionRate: resolutionRate,
      totalTrend: trends['total']!,
      resolvedTrend: trends['resolved']!,
      responseTrend: trends['response']!,
      resolutionTrend: trends['resolution']!,
    );
  }

  static Map<String, double> _calculateTrends(
    List<ReportModel> current,
    List<ReportModel> all,
    String range,
  ) {
    if (range == 'all' || current.isEmpty) {
      return {'total': 0, 'resolved': 0, 'response': 0, 'resolution': 0};
    }

    final days = range == '7d'
        ? 7
        : range == '30d'
        ? 30
        : 90;
    final now = DateTime.now();
    final prevEnd = now.subtract(Duration(days: days));
    final prevStart = prevEnd.subtract(Duration(days: days));

    final previous = all
        .where(
          (r) =>
              r.createdAt.isAfter(prevStart) && r.createdAt.isBefore(prevEnd),
        )
        .toList();

    final currTotal = current.length;
    final prevTotal = previous.length;
    final totalTrend = prevTotal > 0
        ? ((currTotal - prevTotal) / prevTotal * 100)
        : 0;

    final currResolved = current
        .where((r) => r.currentStatus == AppConstants.statusCompleted)
        .length;
    final prevResolved = previous
        .where((r) => r.currentStatus == AppConstants.statusCompleted)
        .length;
    final resolvedTrend = prevResolved > 0
        ? ((currResolved - prevResolved) / prevResolved * 100)
        : 0;

    return {
      'total': totalTrend.toDouble(),
      'resolved': resolvedTrend.toDouble(),
      'response': 0,
      'resolution': 0,
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final double trend;
  final Color color;

  const _TrendCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend > 0;
    final trendColor = isPositive ? AppTheme.successGreen : AppTheme.primaryRed;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(trendIcon, size: 14, color: trendColor),
                        const SizedBox(width: 4),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERACTIVE CHARTS
// ══════════════════════════════════════════════════════════════════════════════

class _InteractiveLineChart extends StatefulWidget {
  final List<ReportModel> reports;
  final String timeRange;

  const _InteractiveLineChart({required this.reports, required this.timeRange});

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart> {
  @override
  Widget build(BuildContext context) {
    final days = _getDaysCount();
    final dataPoints = _generateDataPoints(days);

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: days / 6,
                getTitlesWidget: (value, meta) {
                  final date = _getDateFromIndex(value.toInt(), days);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: AppTheme.primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppTheme.primaryBlue,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.primaryBlue.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryBlue,
              getTooltipItems: (spots) => spots.map((spot) {
                final date = _getDateFromIndex(spot.x.toInt(), days);
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} reports',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateDataPoints(int days) {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i - 1));
      final count = widget.reports
          .where(
            (r) =>
                r.createdAt.year == date.year &&
                r.createdAt.month == date.month &&
                r.createdAt.day == date.day,
          )
          .length;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return spots;
  }

  int _getDaysCount() {
    return widget.timeRange == '7d'
        ? 7
        : widget.timeRange == '30d'
        ? 30
        : widget.timeRange == '90d'
        ? 90
        : 30;
  }

  DateTime _getDateFromIndex(int index, int days) {
    final now = DateTime.now();
    return now.subtract(Duration(days: days - index - 1));
  }
}

class _InteractivePieChart extends StatelessWidget {
  final Map<String, int> data;
  final int? touchedIndex;
  final Function(int?) onTouch;

  const _InteractivePieChart({
    required this.data,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final total = data.values.reduce((a, b) => a + b);
    final entries = data.entries.toList();

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      onTouch(null);
                      return;
                    }
                    onTouch(response.touchedSection!.touchedSectionIndex);
                  },
                ),
                sections: _generateSections(entries, total),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
              ),
            ),
          ),
          Expanded(child: _buildLegend(entries, total)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.successGreen,
      Colors.orange,
      AppTheme.primaryRed,
      Colors.purple,
      Colors.teal,
    ];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final percentage = (data.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value.toDouble(),
        title: '$percentage%',
        radius: isTouched ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(List<MapEntry<String, int>> entries, int total) {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.successGreen,
      Colors.orange,
      AppTheme.primaryRed,
      Colors.purple,
      Colors.teal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final percentage = (data.value / total * 100).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  final List<ReportModel> reports;

  const _CategoryDonutChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final data = <String, int>{};
    for (final r in reports) {
      data[r.category] = (data[r.category] ?? 0) + 1;
    }

    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final total = data.values.reduce((a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: _generateSections(entries, total),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: entries.take(6).map((e) {
                final colors = [
                  Color(0xFF0038A8),
                  Color(0xFFCE1126),
                  Color(0xFF2E7D32),
                  Color(0xFFE65100),
                  Color(0xFF6A1B9A),
                  Color(0xFF00838F),
                ];
                final index = entries.indexOf(e);
                final pct = (e.value / total * 100).toStringAsFixed(1);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    final colors = [
      Color(0xFF0038A8),
      Color(0xFFCE1126),
      Color(0xFF2E7D32),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
    ];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / total * 100).toStringAsFixed(0);

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data.value.toDouble(),
        title: '$percentage%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEAT MAPS
// ══════════════════════════════════════════════════════════════════════════════

class _TimeHeatMap extends StatelessWidget {
  final List<ReportModel> reports;

  const _TimeHeatMap({required this.reports});

  @override
  Widget build(BuildContext context) {
    final hourData = <String, int>{};
    final timeSlots = [
      '12-3 AM',
      '3-6 AM',
      '6-9 AM',
      '9-12 PM',
      '12-3 PM',
      '3-6 PM',
      '6-9 PM',
      '9-12 AM',
    ];

    for (final slot in timeSlots) {
      hourData[slot] = 0;
    }

    for (final r in reports) {
      final hour = r.createdAt.hour;
      if (hour >= 0 && hour < 3)
        hourData['12-3 AM'] = hourData['12-3 AM']! + 1;
      else if (hour >= 3 && hour < 6)
        hourData['3-6 AM'] = hourData['3-6 AM']! + 1;
      else if (hour >= 6 && hour < 9)
        hourData['6-9 AM'] = hourData['6-9 AM']! + 1;
      else if (hour >= 9 && hour < 12)
        hourData['9-12 PM'] = hourData['9-12 PM']! + 1;
      else if (hour >= 12 && hour < 15)
        hourData['12-3 PM'] = hourData['12-3 PM']! + 1;
      else if (hour >= 15 && hour < 18)
        hourData['3-6 PM'] = hourData['3-6 PM']! + 1;
      else if (hour >= 18 && hour < 21)
        hourData['6-9 PM'] = hourData['6-9 PM']! + 1;
      else
        hourData['9-12 AM'] = hourData['9-12 AM']! + 1;
    }

    final maxValue = hourData.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: timeSlots.map((slot) {
        final value = hourData[slot]!;
        final intensity = maxValue > 0 ? value / maxValue : 0.0;
        final color = _getHeatColor(intensity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  slot,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$value reports',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: intensity > 0.5 ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getHeatColor(double intensity) {
    if (intensity > 0.7) return AppTheme.primaryRed;
    if (intensity > 0.4) return Colors.orange;
    if (intensity > 0.2) return AppTheme.primaryYellow;
    return Colors.grey[200]!;
  }
}

class _BarangayBarChart extends StatelessWidget {
  final List<ReportModel> reports;

  const _BarangayBarChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final data = <String, int>{};
    for (final r in reports) {
      data[r.barangay] = (data[r.barangay] ?? 0) + 1;
    }

    if (data.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.take(10).toList();
    final maxValue = top10.first.value.toDouble();

    return Column(
      children: top10.map((entry) {
        final ratio = entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Container(
                      height: 28,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ratio > 0.5 ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
