import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../admin/screens/admin_shell.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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

          final reports = snapshot.data ?? [];
          final stats = _AnalyticsStats.from(reports);

          return Column(
            children: [
              const AdminPageHeader(title: 'Analytics'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: reports.isEmpty
                      ? _EmptyState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top stat cards ──────────────────────────
                            Row(
                              children: [
                                _StatCard(
                                  value: '${stats.total}',
                                  label: 'Total Reports',
                                  sub: 'All time',
                                  subColor: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  value: '${stats.resolved}',
                                  label: 'Resolved',
                                  sub: stats.resolvedRate,
                                  subColor: AppTheme.successGreen,
                                  valueColor: AppTheme.successGreen,
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  value: '${stats.inProgress}',
                                  label: 'In Progress',
                                  sub: 'Active',
                                  subColor: AppTheme.textMuted,
                                  valueColor: const Color(0xFF1565C0),
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  value: '${stats.pending}',
                                  label: 'Pending',
                                  sub: 'Awaiting action',
                                  subColor: Colors.orange,
                                  valueColor: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  value: '${stats.overdue}',
                                  label: 'Overdue',
                                  sub: 'Past deadline',
                                  subColor: AppTheme.primaryRed,
                                  valueColor: AppTheme.primaryRed,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Acknowledgment + Response time ──────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _Card(
                                    title: 'Acknowledgment Rate',
                                    subtitle:
                                        'Reports reviewed within 24 hrs of submission',
                                    child: _AckRateWidget(stats: stats),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: _Card(
                                    title: 'Avg. Response Time by Category',
                                    subtitle:
                                        'Time from submission to first status update',
                                    child: _CategoryResponseWidget(
                                      reports: reports,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: _Card(
                                    title: 'Reports by Hour of Day',
                                    subtitle: 'When reports are submitted',
                                    child: _HourlyWidget(reports: reports),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Charts ──────────────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _Card(
                                    title: 'Reports by Status',
                                    child: _StatusChart(reports: reports),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Card(
                                    title: 'Reports by Barangay',
                                    child: _BarangayChart(reports: reports),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Monthly Trend Analysis ───────────────────
                            _Card(
                              title: 'Report Trends (Last 6 Months)',
                              subtitle:
                                  'Monthly submission and completion trends',
                              child: _MonthlyTrendChart(reports: reports),
                            ),
                            const SizedBox(height: 20),

                            // ── Category breakdown ───────────────────────
                            _Card(
                              title: 'Reports by Category',
                              child: _CategoryChart(reports: reports),
                            ),
                            const SizedBox(height: 20),

                            // ── Performance Analysis ─────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _Card(
                                    title: 'Resolution Rate by Category',
                                    subtitle:
                                        'Completion percentage per category',
                                    child: _CategoryResolutionChart(
                                      reports: reports,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Card(
                                    title: 'Top Performing Barangays',
                                    subtitle: 'By resolution speed',
                                    child: _BarangayPerformanceWidget(
                                      reports: reports,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Day of Week Patterns ─────────────────────
                            _Card(
                              title: 'Weekly Submission Patterns',
                              subtitle: 'Reports by day of week',
                              child: _DayOfWeekChart(reports: reports),
                            ),
                            const SizedBox(height: 20),

                            // ── User Engagement ──────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _Card(
                                    title: 'Most Active Reporters',
                                    subtitle:
                                        'Top 5 citizens by reports submitted',
                                    child: _TopReportersWidget(
                                      reports: reports,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Card(
                                    title: 'Follow Activity',
                                    subtitle: 'Community engagement metrics',
                                    child: _FollowActivityWidget(
                                      reports: reports,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
}

// ── Data model ────────────────────────────────────────────────────────────────
class _AnalyticsStats {
  final int total,
      resolved,
      inProgress,
      pending,
      overdue,
      acknowledged,
      missedWindow;
  final Duration avgResponseTime;

  _AnalyticsStats({
    required this.total,
    required this.resolved,
    required this.inProgress,
    required this.pending,
    required this.overdue,
    required this.acknowledged,
    required this.missedWindow,
    required this.avgResponseTime,
  });

  String get resolvedRate => total == 0
      ? '0%'
      : '${(resolved / total * 100).toStringAsFixed(1)}% rate';
  double get ackRate => total == 0 ? 0 : acknowledged / total;

  factory _AnalyticsStats.from(List<ReportModel> reports) {
    final total = reports.length;
    final resolved = reports
        .where((r) => r.currentStatus == AppConstants.statusCompleted)
        .length;
    final inProgress = reports
        .where((r) => r.currentStatus == AppConstants.statusInProgress)
        .length;
    final pending = reports
        .where((r) => r.currentStatus == AppConstants.statusSubmitted)
        .length;
    final overdue = reports.where((r) => r.currentStatus == 'Overdue').length;

    // Acknowledged = seen within 24h of submission
    int acknowledged = 0;
    int missedWindow = 0;
    Duration totalResponse = Duration.zero;
    int responseCount = 0;

    for (final r in reports) {
      if (r.statusHistory.length > 1) {
        final firstUpdate = r.statusHistory[1].timestamp;
        final diff = firstUpdate.difference(r.createdAt);
        totalResponse += diff;
        responseCount++;
        if (diff.inHours <= 24) {
          acknowledged++;
        } else {
          missedWindow++;
        }
      }
    }

    final avgResponse = responseCount > 0
        ? Duration(minutes: totalResponse.inMinutes ~/ responseCount)
        : Duration.zero;

    return _AnalyticsStats(
      total: total,
      resolved: resolved,
      inProgress: inProgress,
      pending: pending,
      overdue: overdue,
      acknowledged: acknowledged,
      missedWindow: missedWindow,
      avgResponseTime: avgResponse,
    );
  }

  String get avgResponseStr {
    final h = avgResponseTime.inHours;
    final m = avgResponseTime.inMinutes % 60;
    if (h == 0 && m == 0) return 'N/A';
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No data yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analytics will appear here once residents submit reports.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label, sub;
  final Color subColor;
  final Color? valueColor;
  const _StatCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.subColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AckRateWidget extends StatelessWidget {
  final _AnalyticsStats stats;
  const _AckRateWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.ackRate * 100).toStringAsFixed(0);
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background shadow circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (stats.ackRate >= 0.8
                                  ? AppTheme.successGreen
                                  : stats.ackRate >= 0.5
                                  ? AppTheme.primaryYellow
                                  : AppTheme.primaryRed)
                              .withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Animated progress
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stats.ackRate),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(
                    stats.ackRate >= 0.8
                        ? AppTheme.successGreen
                        : stats.ackRate >= 0.5
                        ? AppTheme.primaryYellow
                        : AppTheme.primaryRed,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (stats.ackRate >= 0.8
                                  ? AppTheme.successGreen
                                  : stats.ackRate >= 0.5
                                  ? AppTheme.primaryYellow
                                  : AppTheme.primaryRed)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stats.ackRate >= 0.8
                          ? 'Excellent'
                          : stats.ackRate >= 0.5
                          ? 'Good'
                          : 'Needs Work',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stats.ackRate >= 0.8
                            ? AppTheme.successGreen
                            : stats.ackRate >= 0.5
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AckRow(
          label: 'Acknowledged',
          value: '${stats.acknowledged} reports',
          color: AppTheme.successGreen,
        ),
        _AckRow(
          label: 'Missed window',
          value: '${stats.missedWindow} reports',
          color: AppTheme.primaryRed,
        ),
        _AckRow(
          label: 'Avg. response time',
          value: stats.avgResponseStr,
          color: AppTheme.textDark,
        ),
      ],
    );
  }
}

class _AckRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AckRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryResponseWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _CategoryResponseWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    // Calculate avg response time per category
    final Map<String, List<Duration>> categoryTimes = {};
    for (final r in reports) {
      if (r.statusHistory.length > 1) {
        final diff = r.statusHistory[1].timestamp.difference(r.createdAt);
        categoryTimes.putIfAbsent(r.category, () => []).add(diff);
      }
    }

    if (categoryTimes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No response data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final entries = categoryTimes.entries.map((e) {
      final avg = Duration(
        minutes:
            e.value.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/
            e.value.length,
      );
      return MapEntry(e.key, avg);
    }).toList()..sort((a, b) => a.value.compareTo(b.value));

    final maxMin = entries.last.value.inMinutes.toDouble().clamp(
      1.0,
      double.infinity,
    );

    return Column(
      children: [
        const SizedBox(height: 16),
        ...entries.map((e) {
          final h = e.value.inHours;
          final m = e.value.inMinutes % 60;
          final label = h > 0 ? '${h}h ${m}m' : '${m}m';
          final ratio = e.value.inMinutes / maxMin;
          final color = ratio < 0.4
              ? AppTheme.successGreen
              : ratio < 0.7
              ? Colors.orange
              : AppTheme.primaryRed;
          return _RespRow(
            label: e.key,
            time: label,
            color: color,
            value: ratio,
          );
        }),
      ],
    );
  }
}

class _HourlyWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _HourlyWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> hourBuckets = {
      '6–9 AM': 0,
      '9–12 PM': 0,
      '12–3 PM': 0,
      '3–6 PM': 0,
      '6–9 PM': 0,
      '9 PM+': 0,
    };

    for (final r in reports) {
      final h = r.createdAt.hour;
      if (h >= 6 && h < 9)
        hourBuckets['6–9 AM'] = hourBuckets['6–9 AM']! + 1;
      else if (h >= 9 && h < 12)
        hourBuckets['9–12 PM'] = hourBuckets['9–12 PM']! + 1;
      else if (h >= 12 && h < 15)
        hourBuckets['12–3 PM'] = hourBuckets['12–3 PM']! + 1;
      else if (h >= 15 && h < 18)
        hourBuckets['3–6 PM'] = hourBuckets['3–6 PM']! + 1;
      else if (h >= 18 && h < 21)
        hourBuckets['6–9 PM'] = hourBuckets['6–9 PM']! + 1;
      else
        hourBuckets['9 PM+'] = hourBuckets['9 PM+']! + 1;
    }

    final maxVal = hourBuckets.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1.0, double.infinity);

    return Column(
      children: [
        const SizedBox(height: 16),
        ...hourBuckets.entries.map((e) {
          final ratio = e.value / maxVal;
          final color = ratio < 0.4
              ? AppTheme.successGreen
              : ratio < 0.7
              ? Colors.orange
              : AppTheme.primaryRed;
          return _RespRow(
            label: e.key,
            time: '${e.value} reports',
            color: color,
            value: ratio,
          );
        }),
      ],
    );
  }
}

class _RespRow extends StatelessWidget {
  final String label, time;
  final Color color;
  final double value;
  const _RespRow({
    required this.label,
    required this.time,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _StatusChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.currentStatus] = (counts[r.currentStatus] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final statuses = AppConstants.reportStatuses
        .where((s) => counts.containsKey(s))
        .toList();
    final bars = statuses
        .asMap()
        .entries
        .map(
          (e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (counts[e.value] ?? 0).toDouble(),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.statusColor(e.value),
                    AppTheme.statusColor(e.value).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (counts.values.reduce(
                    (a, b) => a > b ? a : b,
                  )).toDouble(),
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
        )
        .toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: bars,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final labels = ['Sub', 'Seen', 'Val', 'Que', 'WIP', 'Done'];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _BarangayChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _BarangayChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.barangay] = (counts[r.barangay] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value.toDouble().clamp(1.0, double.infinity);

    return Column(
      children: [
        const SizedBox(height: 12),
        ...sorted
            .take(10)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: e.value / max),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 14,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _CategoryChart({required this.reports});

  static const _colors = [
    Color(0xFF0038A8),
    Color(0xFFCE1126),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF558B2F),
    Color(0xFF4E342E),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value.toDouble().clamp(1.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sorted.asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          final ratio = e.value.value / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Container(
                      height: 120 * v + 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${e.value.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.key.split(' ').first,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Monthly Trend Chart ──────────────────────────────────────────────────────
class _MonthlyTrendChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _MonthlyTrendChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    // Get last 6 months of data
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    final submittedData = <FlSpot>[];
    final completedData = <FlSpot>[];

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final submitted = reports.where((r) {
        return r.createdAt.isAfter(month) && r.createdAt.isBefore(nextMonth);
      }).length;

      final completed = reports.where((r) {
        return r.currentStatus == AppConstants.statusCompleted &&
            r.createdAt.isAfter(month) &&
            r.createdAt.isBefore(nextMonth);
      }).length;

      submittedData.add(FlSpot(i.toDouble(), submitted.toDouble()));
      completedData.add(FlSpot(i.toDouble(), completed.toDouble()));
    }

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= months.length) return const SizedBox();
                    final month = months[i];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ][month.month - 1],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
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
                spots: submittedData,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryOrange, AppTheme.primaryYellow],
                ),
                barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: AppTheme.primaryOrange,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryOrange.withValues(alpha: 0.3),
                      AppTheme.primaryYellow.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              LineChartBarData(
                spots: completedData,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppTheme.successGreen, Color(0xFF10B981)],
                ),
                barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: AppTheme.successGreen,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successGreen.withValues(alpha: 0.3),
                      AppTheme.successGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Resolution Chart ────────────────────────────────────────────────
class _CategoryResolutionChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _CategoryResolutionChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, int>> categoryStats = {};

    for (final r in reports) {
      categoryStats.putIfAbsent(r.category, () => {'total': 0, 'completed': 0});
      categoryStats[r.category]!['total'] =
          categoryStats[r.category]!['total']! + 1;
      if (r.currentStatus == AppConstants.statusCompleted) {
        categoryStats[r.category]!['completed'] =
            categoryStats[r.category]!['completed']! + 1;
      }
    }

    if (categoryStats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final sortedCategories = categoryStats.entries.toList()
      ..sort((a, b) {
        final aRate = a.value['completed']! / a.value['total']!;
        final bRate = b.value['completed']! / b.value['total']!;
        return bRate.compareTo(aRate);
      });

    return Column(
      children: [
        const SizedBox(height: 12),
        ...sortedCategories.map((e) {
          final total = e.value['total']!;
          final completed = e.value['completed']!;
          final rate = (completed / total * 100).toStringAsFixed(0);
          final color = completed / total >= 0.7
              ? AppTheme.successGreen
              : completed / total >= 0.4
              ? Colors.orange
              : AppTheme.primaryRed;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: completed / total),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * v * 0.3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: completed / total >= 0.7
                                    ? [
                                        AppTheme.successGreen,
                                        const Color(0xFF10B981),
                                      ]
                                    : completed / total >= 0.4
                                    ? [
                                        AppTheme.primaryOrange,
                                        AppTheme.primaryYellow,
                                      ]
                                    : [AppTheme.coral, AppTheme.primaryRed],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$rate% ($completed/$total)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Barangay Performance Widget ──────────────────────────────────────────────
class _BarangayPerformanceWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _BarangayPerformanceWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Duration>> barangayTimes = {};

    for (final r in reports) {
      if (r.currentStatus == AppConstants.statusCompleted &&
          r.statusHistory.length > 1) {
        final duration = r.statusHistory.last.timestamp.difference(r.createdAt);
        barangayTimes.putIfAbsent(r.barangay, () => []).add(duration);
      }
    }

    if (barangayTimes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No completion data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final avgTimes = barangayTimes.entries.map((e) {
      final avgMinutes =
          e.value.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/
          e.value.length;
      return MapEntry(e.key, Duration(minutes: avgMinutes));
    }).toList()..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      children: [
        const SizedBox(height: 12),
        ...avgTimes.take(5).map((e) {
          final days = e.value.inDays;
          final hours = e.value.inHours % 24;
          final timeStr = days > 0 ? '$days days' : '${hours}h';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successGreen.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.successGreen, Color(0xFF10B981)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${avgTimes.indexOf(e) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Avg: $timeStr',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryYellow,
                          AppTheme.primaryOrange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${barangayTimes[e.key]!.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Day of Week Chart ────────────────────────────────────────────────────────
class _DayOfWeekChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _DayOfWeekChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final dayCounts = List.filled(7, 0);

    for (final r in reports) {
      final day = r.createdAt.weekday - 1; // Mon = 0, Sun = 6
      dayCounts[day]++;
    }

    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final bars = dayCounts
        .asMap()
        .entries
        .map(
          (e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                gradient: LinearGradient(
                  colors: [AppTheme.primaryYellow, AppTheme.primaryOrange],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: 36,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
            ],
          ),
        )
        .toList();

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: BarChart(
          BarChartData(
            barGroups: bars,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    const labels = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[i],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

// ── Top Reporters Widget ─────────────────────────────────────────────────────
class _TopReportersWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _TopReportersWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final reporterCounts = <String, int>{};

    for (final r in reports) {
      final name = r.isAnonymous ? 'Anonymous' : r.userFullName;
      reporterCounts[name] = (reporterCounts[name] ?? 0) + 1;
    }

    if (reporterCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No data yet.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final sorted = reporterCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        const SizedBox(height: 12),
        ...sorted.take(5).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final data = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: rank == 1
                      ? [
                          const Color(0xFFFFD700).withValues(alpha: 0.2),
                          const Color(0xFFFFD700).withValues(alpha: 0.05),
                        ]
                      : rank == 2
                      ? [
                          const Color(0xFFC0C0C0).withValues(alpha: 0.2),
                          const Color(0xFFC0C0C0).withValues(alpha: 0.05),
                        ]
                      : rank == 3
                      ? [
                          const Color(0xFFCD7F32).withValues(alpha: 0.2),
                          const Color(0xFFCD7F32).withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rank <= 3
                      ? (rank == 1
                                ? const Color(0xFFFFD700)
                                : rank == 2
                                ? const Color(0xFFC0C0C0)
                                : const Color(0xFFCD7F32))
                            .withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: rank == 1
                            ? [const Color(0xFFFFD700), const Color(0xFFFFAA00)]
                            : rank == 2
                            ? [const Color(0xFFC0C0C0), const Color(0xFFA0A0A0)]
                            : rank == 3
                            ? [const Color(0xFFCD7F32), const Color(0xFFAD5F12)]
                            : [AppTheme.primaryYellow, AppTheme.primaryOrange],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (rank == 1
                                      ? const Color(0xFFFFD700)
                                      : rank == 2
                                      ? const Color(0xFFC0C0C0)
                                      : const Color(0xFFCD7F32))
                                  .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${data.value} reports',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rank <= 3)
                    Icon(
                      Icons.emoji_events_rounded,
                      color: rank == 1
                          ? const Color(0xFFFFD700)
                          : rank == 2
                          ? const Color(0xFFC0C0C0)
                          : const Color(0xFFCD7F32),
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Follow Activity Widget ───────────────────────────────────────────────────
class _FollowActivityWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _FollowActivityWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final totalFollows = reports.fold<int>(
      0,
      (sum, r) => sum + r.followers.length,
    );

    final reportsWithFollows = reports
        .where((r) => r.followers.isNotEmpty)
        .length;
    final avgFollowsPerReport = reports.isEmpty
        ? 0.0
        : totalFollows / reports.length;

    final mostFollowed = reports.isEmpty
        ? null
        : reports.reduce(
            (a, b) => a.followers.length > b.followers.length ? a : b,
          );

    return Column(
      children: [
        const SizedBox(height: 16),
        _MetricRow(
          label: 'Total follows',
          value: '$totalFollows',
          color: AppTheme.primaryBlue,
        ),
        _MetricRow(
          label: 'Reports with followers',
          value:
              '$reportsWithFollows (${(reportsWithFollows / (reports.isEmpty ? 1 : reports.length) * 100).toStringAsFixed(0)}%)',
          color: AppTheme.successGreen,
        ),
        _MetricRow(
          label: 'Avg. follows per report',
          value: avgFollowsPerReport.toStringAsFixed(1),
          color: Colors.orange,
        ),
        if (mostFollowed != null) ...[
          const Divider(height: 20),
          const Text(
            'Most Followed Report',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostFollowed.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mostFollowed.followers.length} followers',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
