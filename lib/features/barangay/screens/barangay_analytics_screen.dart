import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/barangay_service.dart';
import '../../auth/providers/auth_provider.dart';

class BarangayAnalyticsScreen extends StatelessWidget {
  const BarangayAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<ReportModel>>(
      stream: BarangayService().getBarangayReports(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        return _BrgyAnalyticsBody(reports: reports, barangayName: user.barangay.isNotEmpty ? 'Brgy. ${user.barangay}' : 'Barangay');
      },
    );
  }
}

class _BrgyAnalyticsBody extends StatelessWidget {
  final List<ReportModel> reports;
  final String barangayName;
  const _BrgyAnalyticsBody({required this.reports, required this.barangayName});

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final assigned = reports.where((r) => r.currentStatus == AppConstants.statusAssigned).length;
    final inProgress = reports.where((r) => r.currentStatus == AppConstants.statusInProgress).length;
    final done = reports.where((r) => r.currentStatus == AppConstants.statusDone).length;
    final resolved = reports.where((r) => r.currentStatus == AppConstants.statusResolved).length;
    final needsRevision = reports.where((r) => r.currentStatus == AppConstants.statusNeedsRevision).length;
    final resolvedRate = total == 0 ? '0%' : '${(resolved / total * 100).toStringAsFixed(1)}%';

    Duration totalRes = Duration.zero;
    int resCount = 0;
    for (final r in reports) {
      if (r.currentStatus == AppConstants.statusResolved && r.completedAt != null) {
        totalRes += r.completedAt!.difference(r.createdAt);
        resCount++;
      }
    }
    final avgDays = resCount > 0 ? (totalRes.inHours / resCount / 24).toStringAsFixed(1) : '–';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics — $barangayName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text('Your assigned report performance', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),

          if (reports.isEmpty)
            _EmptyState()
          else ...[
            // ── Stat cards ──────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(value: '$total', label: 'Total Assigned', sub: 'All time', subColor: AppTheme.textMuted),
                _StatCard(value: '$resolved', label: 'Resolved', sub: resolvedRate, subColor: AppTheme.successGreen, valueColor: AppTheme.successGreen),
                _StatCard(value: '$inProgress', label: 'In Progress', sub: 'Active work', subColor: const Color(0xFF0D9488), valueColor: const Color(0xFF0D9488)),
                _StatCard(value: '$assigned', label: 'Assigned', sub: 'Pending start', subColor: Colors.orange, valueColor: Colors.orange),
                _StatCard(value: '$needsRevision', label: 'Needs Revision', sub: 'Returned', subColor: AppTheme.primaryRed, valueColor: AppTheme.primaryRed),
                _StatCard(value: avgDays == '–' ? '–' : '${avgDays}d', label: 'Avg Resolution', sub: 'Days to resolve', subColor: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 20),

            // ── Status + Category ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Card(title: 'Reports by Status', child: _StatusChart(reports: reports))),
                const SizedBox(width: 16),
                Expanded(child: _Card(title: 'Reports by Category', child: _CategoryChart(reports: reports))),
              ],
            ),
            const SizedBox(height: 20),

            // ── Monthly trend ────────────────────────────────────────
            _Card(
              title: 'Monthly Report Trend (Last 6 Months)',
              subtitle: 'Assigned vs resolved per month',
              child: _MonthlyTrendChart(reports: reports),
            ),
            const SizedBox(height: 20),

            // ── Resolution rate + Day of week ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Card(title: 'Resolution Rate by Category', subtitle: 'Resolved out of total per category', child: _CategoryResolutionChart(reports: reports))),
                const SizedBox(width: 16),
                Expanded(child: _Card(title: 'Workload by Day of Week', subtitle: 'When reports are assigned', child: _DayOfWeekChart(reports: reports))),
              ],
            ),
            const SizedBox(height: 20),

            // ── Submission quality ───────────────────────────────────
            _Card(
              title: 'Submission Quality',
              subtitle: 'Done (first pass) vs Needs Revision',
              child: _QualityWidget(done: done, needsRevision: needsRevision, resolved: resolved),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

// ── Shared UI widgets ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No reports assigned yet', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label, sub;
  final Color subColor;
  final Color? valueColor;
  const _StatCard({required this.value, required this.label, required this.sub, required this.subColor, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: subColor)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
          const SizedBox(height: 14),
          child,
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
    if (counts.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No data yet.', style: TextStyle(color: AppTheme.textMuted)));

    final statuses = AppConstants.reportStatuses.where((s) => counts.containsKey(s)).toList();
    final bars = statuses.asMap().entries.map((e) => BarChartGroupData(
      x: e.key,
      barRods: [BarChartRodData(
        toY: (counts[e.value] ?? 0).toDouble(),
        gradient: LinearGradient(
          colors: [AppTheme.statusColor(e.value), AppTheme.statusColor(e.value).withValues(alpha: 0.6)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        width: 24,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: counts.values.reduce((a, b) => a > b ? a : b).toDouble(),
          color: Colors.grey[100],
        ),
      )],
    )).toList();

    return SizedBox(
      height: 180,
      child: BarChart(BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= statuses.length) return const SizedBox();
              final label = statuses[i]
                  .replaceAll('Under Review', 'Review')
                  .replaceAll('In Progress', 'WIP')
                  .replaceAll('Needs Revision', 'Revision');
              return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      )),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _CategoryChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    if (counts.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No data yet.', style: TextStyle(color: AppTheme.textMuted)));

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value.toDouble();
    const accent = Color(0xFF0D9488);

    return Column(
      children: sorted.map((e) {
        final pct = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontSize: 11, color: AppTheme.textDark), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: Colors.grey[100], valueColor: const AlwaysStoppedAnimation<Color>(accent)))),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: Text('${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _MonthlyTrendChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final assignedData = <FlSpot>[];
    final resolvedData = <FlSpot>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final next = DateTime(month.year, month.month + 1, 1);
      final idx = (5 - i).toDouble();
      final a = reports.where((r) => r.createdAt.isAfter(month) && r.createdAt.isBefore(next)).length;
      final res = reports.where((r) =>
        r.currentStatus == AppConstants.statusResolved &&
        r.completedAt != null &&
        r.completedAt!.isAfter(month) &&
        r.completedAt!.isBefore(next),
      ).length;
      assignedData.add(FlSpot(idx, a.toDouble()));
      resolvedData.add(FlSpot(idx, res.toDouble()));
    }

    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m.month - 1];
    });

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: assignedData,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)]),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
              colors: [const Color(0xFF0D9488).withValues(alpha: 0.15), const Color(0xFF0D9488).withValues(alpha: 0.0)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            )),
          ),
          LineChartBarData(
            spots: resolvedData,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= months.length) return const SizedBox();
              return Text(months[i], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      )),
    );
  }
}

class _CategoryResolutionChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _CategoryResolutionChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final total = <String, int>{};
    final resolved = <String, int>{};
    for (final r in reports) {
      total[r.category] = (total[r.category] ?? 0) + 1;
      if (r.currentStatus == AppConstants.statusResolved) {
        resolved[r.category] = (resolved[r.category] ?? 0) + 1;
      }
    }
    if (total.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No data yet.', style: TextStyle(color: AppTheme.textMuted)));

    final sorted = total.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final res = resolved[e.key] ?? 0;
        final pct = e.value > 0 ? res / e.value : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: pct, minHeight: 10, backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(pct >= 0.7 ? AppTheme.successGreen : pct >= 0.4 ? Colors.orange : AppTheme.primaryRed),
              ))),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final List<ReportModel> reports;
  const _DayOfWeekChart({required this.reports});

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(7, 0);
    for (final r in reports) {
      counts[r.createdAt.weekday % 7]++;
    }
    final maxVal = counts.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const accent = Color(0xFF0D9488);

    return SizedBox(
      height: 140,
      child: BarChart(BarChartData(
        barGroups: List.generate(7, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: counts[i].toDouble(),
            color: accent,
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxVal == 0 ? 1 : maxVal, color: Colors.grey[100]),
          )],
        )),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      )),
    );
  }
}

class _QualityWidget extends StatelessWidget {
  final int done, needsRevision, resolved;
  const _QualityWidget({required this.done, required this.needsRevision, required this.resolved});

  @override
  Widget build(BuildContext context) {
    final total = done + needsRevision + resolved;
    if (total == 0) return const Padding(padding: EdgeInsets.all(16), child: Text('No completed reports yet.', style: TextStyle(color: AppTheme.textMuted)));

    final firstPassRate = (done + resolved) / total;
    final revisionRate = needsRevision / total;

    return Row(
      children: [
        Expanded(child: _QualityTile(label: 'First-Pass Rate', value: '${(firstPassRate * 100).toStringAsFixed(1)}%', sub: '${done + resolved} of $total without revision', color: AppTheme.successGreen, icon: Icons.check_circle_outline)),
        const SizedBox(width: 16),
        Expanded(child: _QualityTile(label: 'Revision Rate', value: '${(revisionRate * 100).toStringAsFixed(1)}%', sub: '$needsRevision reports returned', color: Colors.orange, icon: Icons.replay_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _QualityTile(label: 'Resolved', value: '$resolved', sub: 'Admin-verified', color: const Color(0xFF0D9488), icon: Icons.verified_outlined)),
      ],
    );
  }
}

class _QualityTile extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const _QualityTile({required this.label, required this.value, required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
