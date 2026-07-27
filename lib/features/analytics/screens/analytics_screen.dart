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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading analytics...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];
          final stats = _AnalyticsStats.from(reports);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
              ),
            ),
            child: Column(
              children: [
                _ModernHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: reports.isEmpty
                        ? _EmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Animated stat cards ────────
                              Row(
                                children: [
                                  _GlassStatCard(
                                    value: '${stats.total}',
                                    label: 'Total Reports',
                                    sub: 'All time',
                                    icon: Icons.assignment_outlined,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _GlassStatCard(
                                    value: '${stats.resolved}',
                                    label: 'Resolved',
                                    sub: stats.resolvedRate,
                                    icon: Icons.check_circle_outline,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF11998e),
                                        Color(0xFF38ef7d),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _GlassStatCard(
                                    value: '${stats.inProgress}',
                                    label: 'In Progress',
                                    sub: 'Active',
                                    icon: Icons.pending_actions,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3a7bd5),
                                        Color(0xFF3a6073),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _GlassStatCard(
                                    value: '${stats.pending}',
                                    label: 'Pending',
                                    sub: 'Awaiting',
                                    icon: Icons.hourglass_empty,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFf093fb),
                                        Color(0xFFf5576c),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _GlassStatCard(
                                    value: '${stats.overdue}',
                                    label: 'Overdue',
                                    sub: 'Critical',
                                    icon: Icons.warning_amber_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFfa709a),
                                        Color(0xFFfee140),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Response metrics ────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _GlassCard(
                                      child: _ModernAckRateWidget(stats: stats),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 3,
                                    child: _GlassCard(
                                      child: _ModernCategoryResponseWidget(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 3,
                                    child: _GlassCard(
                                      child: _ModernHourlyWidget(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Charts ──────────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernStatusChart(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernBarangayChart(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Trend analysis ──────────────
                              _GlassCard(
                                child: _ModernMonthlyTrendChart(
                                  reports: reports,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Category breakdown ──────────
                              _GlassCard(
                                child: _ModernCategoryChart(reports: reports),
                              ),
                              const SizedBox(height: 24),

                              // ── Performance ─────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernCategoryResolutionChart(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernBarangayPerformanceWidget(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Weekly patterns ─────────────
                              _GlassCard(
                                child: _ModernDayOfWeekChart(reports: reports),
                              ),
                              const SizedBox(height: 24),

                              // ── User engagement ─────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernTopReportersWidget(
                                        reports: reports,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _GlassCard(
                                      child: _ModernFollowActivityWidget(
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
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _ModernHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Real-time insights & performance metrics',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38ef7d),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GLASS STAT CARD
// ══════════════════════════════════════════════════════════════════════════════
class _GlassStatCard extends StatefulWidget {
  final String value, label, sub;
  final IconData icon;
  final Gradient gradient;

  const _GlassStatCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.icon,
    required this.gradient,
  });

  @override
  State<_GlassStatCard> createState() => _GlassStatCardState();
}

class _GlassStatCardState extends State<_GlassStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: int.tryParse(widget.value) ?? 0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

// ══════════════════════════════════════════════════════════════════════════════
// GLASS CARD
// ══════════════════════════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryBlue.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 80,
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Analytics Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analytics will appear here once residents submit reports.',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN ACK RATE WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernAckRateWidget extends StatelessWidget {
  final _AnalyticsStats stats;
  const _ModernAckRateWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.ackRate * 100).toStringAsFixed(0);
    final color = stats.ackRate >= 0.8
        ? const Color(0xFF38ef7d)
        : stats.ackRate >= 0.5
        ? const Color(0xFFffa502)
        : const Color(0xFFfa709a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.schedule, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acknowledgment Rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Within 24 hrs',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stats.ackRate),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(color),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: int.parse(pct)),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, child) {
                        return Text(
                          '$value%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: color,
                          ),
                        );
                      },
                    ),
                    const Text(
                      'acknowledged',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _MetricRow(
          icon: Icons.check_circle,
          label: 'Acknowledged',
          value: '${stats.acknowledged}',
          color: const Color(0xFF38ef7d),
        ),
        _MetricRow(
          icon: Icons.warning_amber,
          label: 'Missed window',
          value: '${stats.missedWindow}',
          color: const Color(0xFFfa709a),
        ),
        _MetricRow(
          icon: Icons.timer,
          label: 'Avg. response',
          value: stats.avgResponseStr,
          color: AppTheme.primaryBlue,
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN CATEGORY RESPONSE WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernCategoryResponseWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernCategoryResponseWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Duration>> categoryTimes = {};
    for (final r in reports) {
      if (r.statusHistory.length > 1) {
        final diff = r.statusHistory[1].timestamp.difference(r.createdAt);
        categoryTimes.putIfAbsent(r.category, () => []).add(diff);
      }
    }

    if (categoryTimes.isEmpty) {
      return _EmptyChartState('No response data yet');
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.speed,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avg. Response Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'By category',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...entries.map((e) {
          final h = e.value.inHours;
          final m = e.value.inMinutes % 60;
          final label = h > 0 ? '${h}h ${m}m' : '${m}m';
          final ratio = e.value.inMinutes / maxMin;
          final color = ratio < 0.4
              ? const Color(0xFF38ef7d)
              : ratio < 0.7
              ? const Color(0xFFffa502)
              : const Color(0xFFfa709a);

          return _AnimatedBarRow(
            label: e.key,
            value: label,
            ratio: ratio,
            color: color,
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN HOURLY WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernHourlyWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernHourlyWidget({required this.reports});

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hourly Patterns',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Submission times',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...hourBuckets.entries.map((e) {
          final ratio = e.value / maxVal;
          return _AnimatedBarRow(
            label: e.key,
            value: '${e.value} reports',
            ratio: ratio,
            color: Colors.purple,
          );
        }),
      ],
    );
  }
}

class _AnimatedBarRow extends StatelessWidget {
  final String label, value;
  final double ratio;
  final Color color;

  const _AnimatedBarRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final String message;
  const _EmptyChartState(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN STATUS CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernStatusChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernStatusChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.currentStatus] = (counts[r.currentStatus] ?? 0) + 1;
    }

    if (counts.isEmpty) return _EmptyChartState('No status data yet');

    final statuses = AppConstants.reportStatuses
        .where((s) => counts.containsKey(s))
        .toList();
    final bars = statuses.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (counts[e.value] ?? 0).toDouble(),
            gradient: LinearGradient(
              colors: [
                AppTheme.statusColor(e.value),
                AppTheme.statusColor(e.value).withValues(alpha: 0.6),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pie_chart, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reports by Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: bars,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      const labels = [
                        'Sub',
                        'Seen',
                        'Val',
                        'Que',
                        'WIP',
                        'Done',
                      ];
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                        fontSize: 11,
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
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN BARANGAY CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernBarangayChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernBarangayChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.barangay] = (counts[r.barangay] ?? 0) + 1;
    }

    if (counts.isEmpty) return _EmptyChartState('No barangay data yet');

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value.toDouble().clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reports by Barangay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...sorted
            .take(8)
            .map(
              (e) => _AnimatedBarRow(
                label: e.key,
                value: '${e.value}',
                ratio: e.value / max,
                color: Colors.orange,
              ),
            ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN MONTHLY TREND CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernMonthlyTrendChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernMonthlyTrendChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return _EmptyChartState('No trend data yet');

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withValues(alpha: 0.2),
                    Colors.teal.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Monthly Trends (6 Months)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            _LegendItem(color: AppTheme.primaryBlue, label: 'Submitted'),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFF38ef7d), label: 'Completed'),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 260,
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
                        padding: const EdgeInsets.only(top: 8),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
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
                  color: AppTheme.primaryBlue,
                  barWidth: 4,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppTheme.primaryBlue,
                      );
                    },
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
                LineChartBarData(
                  spots: completedData,
                  isCurved: true,
                  color: const Color(0xFF38ef7d),
                  barWidth: 4,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF38ef7d),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF38ef7d).withValues(alpha: 0.3),
                        const Color(0xFF38ef7d).withValues(alpha: 0.0),
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
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN CATEGORY CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernCategoryChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernCategoryChart({required this.reports});

  static const _colors = [
    LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
    LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
    LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
    LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
    LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
    LinearGradient(colors: [Color(0xFF30cfd0), Color(0xFF330867)]),
    LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]),
    LinearGradient(colors: [Color(0xFFff9a9e), Color(0xFFfecfef)]),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }

    if (counts.isEmpty) return _EmptyChartState('No category data yet');

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value.toDouble().clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.category, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reports by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: sorted.asMap().entries.map((e) {
            final gradient = _colors[e.key % _colors.length];
            final ratio = e.value.value / max;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: Duration(milliseconds: 800 + e.key * 100),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => Container(
                        height: 140 * v + 8,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${e.value.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value.key.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN CATEGORY RESOLUTION CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernCategoryResolutionChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernCategoryResolutionChart({required this.reports});

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

    if (categoryStats.isEmpty)
      return _EmptyChartState('No resolution data yet');

    final sortedCategories = categoryStats.entries.toList()
      ..sort((a, b) {
        final aRate = a.value['completed']! / a.value['total']!;
        final bRate = b.value['completed']! / b.value['total']!;
        return bRate.compareTo(aRate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resolution Rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'By category',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...sortedCategories.map((e) {
          final total = e.value['total']!;
          final completed = e.value['completed']!;
          final rate = (completed / total * 100).toStringAsFixed(0);
          final color = completed / total >= 0.7
              ? const Color(0xFF38ef7d)
              : completed / total >= 0.4
              ? const Color(0xFFffa502)
              : const Color(0xFFfa709a);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: completed / total),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.6)],
                                ),
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: Text(
                    '$rate% ($completed/$total)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

// ══════════════════════════════════════════════════════════════════════════════
// MODERN BARANGAY PERFORMANCE WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernBarangayPerformanceWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernBarangayPerformanceWidget({required this.reports});

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
      return _EmptyChartState('No completion data yet');
    }

    final avgTimes = barangayTimes.entries.map((e) {
      final avgMinutes =
          e.value.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/
          e.value.length;
      return MapEntry(e.key, Duration(minutes: avgMinutes));
    }).toList()..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFffa502), Color(0xFFff6348)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Performers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Fastest resolution',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...avgTimes.take(5).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final e = entry.value;
          final days = e.value.inDays;
          final hours = e.value.inHours % 24;
          final timeStr = days > 0 ? '$days days' : '${hours}h';

          final medalColor = rank == 1
              ? const Color(0xFFFFD700)
              : rank == 2
              ? const Color(0xFFC0C0C0)
              : rank == 3
              ? const Color(0xFFCD7F32)
              : Colors.grey[300]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    medalColor.withValues(alpha: 0.1),
                    medalColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: medalColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [medalColor, medalColor.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: medalColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${barangayTimes[e.key]!.length} reports resolved',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38ef7d),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeStr,
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

// ══════════════════════════════════════════════════════════════════════════════
// MODERN DAY OF WEEK CHART
// ══════════════════════════════════════════════════════════════════════════════
class _ModernDayOfWeekChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernDayOfWeekChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final dayCounts = List.filled(7, 0);

    for (final r in reports) {
      final day = r.createdAt.weekday - 1;
      dayCounts[day]++;
    }

    if (reports.isEmpty) return _EmptyChartState('No weekly data yet');

    final bars = dayCounts.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.toDouble(),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Submission Patterns',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Reports by day of week',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                        fontSize: 11,
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
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODERN TOP REPORTERS WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernTopReportersWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernTopReportersWidget({required this.reports});

  @override
  Widget build(BuildContext context) {
    final reporterCounts = <String, int>{};

    for (final r in reports) {
      final name = r.isAnonymous ? 'Anonymous' : r.userFullName;
      reporterCounts[name] = (reporterCounts[name] ?? 0) + 1;
    }

    if (reporterCounts.isEmpty) {
      return _EmptyChartState('No reporter data yet');
    }

    final sorted = reporterCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Active Reporters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Top 5 citizens',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...sorted.take(5).toList().asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final data = entry.value;

          final rankColor = rank == 1
              ? const Color(0xFFFFD700)
              : rank == 2
              ? const Color(0xFFC0C0C0)
              : rank == 3
              ? const Color(0xFFCD7F32)
              : const Color(0xFF4facfe);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rankColor.withValues(alpha: 0.1),
                    rankColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rankColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rankColor, rankColor.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      data.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${data.value} reports',
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

// ══════════════════════════════════════════════════════════════════════════════
// MODERN FOLLOW ACTIVITY WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _ModernFollowActivityWidget extends StatelessWidget {
  final List<ReportModel> reports;
  const _ModernFollowActivityWidget({required this.reports});

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow Activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Community engagement',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        _EngagementMetric(
          icon: Icons.favorite,
          label: 'Total follows',
          value: '$totalFollows',
          color: const Color(0xFFf093fb),
        ),
        _EngagementMetric(
          icon: Icons.trending_up,
          label: 'Reports with followers',
          value:
              '$reportsWithFollows (${(reportsWithFollows / (reports.isEmpty ? 1 : reports.length) * 100).toStringAsFixed(0)}%)',
          color: const Color(0xFF38ef7d),
        ),
        _EngagementMetric(
          icon: Icons.people_outline,
          label: 'Avg. follows per report',
          value: avgFollowsPerReport.toStringAsFixed(1),
          color: const Color(0xFF4facfe),
        ),
        if (mostFollowed != null) ...[
          const Divider(height: 28),
          const Text(
            'Most Followed Report',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFf093fb).withValues(alpha: 0.1),
                  const Color(0xFFf5576c).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFf093fb).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFf093fb),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mostFollowed.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mostFollowed.barangay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf093fb),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mostFollowed.followers.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EngagementMetric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _EngagementMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
