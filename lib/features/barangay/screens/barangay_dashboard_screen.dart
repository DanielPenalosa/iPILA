import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/barangay_service.dart';
import '../../auth/providers/auth_provider.dart';

class BarangayDashboardScreen extends StatelessWidget {
  const BarangayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<ReportModel>>(
      stream: BarangayService().getBarangayReports(user.uid),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];

        final assigned = reports
            .where((r) => r.currentStatus == AppConstants.statusAssigned)
            .length;
        final inProgress = reports
            .where((r) => r.currentStatus == AppConstants.statusInProgress)
            .length;
        final forVerification = reports
            .where((r) => r.currentStatus == AppConstants.statusDone)
            .length;
        final resolved = reports
            .where((r) => r.currentStatus == AppConstants.statusResolved)
            .length;
        final revisionRequired = reports
            .where((r) => r.currentStatus == AppConstants.statusNeedsRevision)
            .length;
        final needsAction = assigned + revisionRequired;

        final recent = [...reports]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final recentFive = recent.take(5).toList();

        final categoryMap = <String, int>{};
        for (final r in reports) {
          categoryMap[r.category] = (categoryMap[r.category] ?? 0) + 1;
        }
        final categoryEntries = categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.barangay.isNotEmpty
                              ? 'Brgy. ${user.barangay}'
                              : 'Barangay',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy')
                              .format(DateTime.now()),
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  if (needsAction > 0)
                    _AlertChip(label: '$needsAction need action'),
                ],
              ),
              const SizedBox(height: 32),

              if (revisionRequired > 0) ...[
                _Banner(
                  icon: Icons.undo_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  text:
                      '$revisionRequired report${revisionRequired > 1 ? 's' : ''} returned for revision.',
                ),
                const SizedBox(height: 24),
              ],

              Row(
                children: [
                  _Stat(
                      label: 'Total',
                      value: '${reports.length}',
                      accent: const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _Stat(
                      label: 'Needs Action',
                      value: '$needsAction',
                      accent: const Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  _Stat(
                      label: 'In Progress',
                      value: '$inProgress',
                      accent: const Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  _Stat(
                      label: 'For Review',
                      value: '$forVerification',
                      accent: const Color(0xFF8B5CF6)),
                  const SizedBox(width: 12),
                  _Stat(
                      label: 'Resolved',
                      value: '$resolved',
                      accent: const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _Section(
                      title: 'Recent Activity',
                      child: recentFive.isEmpty
                          ? const _Empty(message: 'No reports assigned yet.')
                          : Column(
                              children: recentFive
                                  .map((r) => _ActivityRow(report: r))
                                  .toList(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _Section(
                      title: 'Breakdown',
                      child: Column(
                        children: [
                          _Bar(
                              label: 'Assigned',
                              count: assigned,
                              total: reports.length,
                              color: const Color(0xFFF59E0B)),
                          _Bar(
                              label: 'In Progress',
                              count: inProgress,
                              total: reports.length,
                              color: const Color(0xFF3B82F6)),
                          _Bar(
                              label: 'For Review',
                              count: forVerification,
                              total: reports.length,
                              color: const Color(0xFF8B5CF6)),
                          _Bar(
                              label: 'Revision Req.',
                              count: revisionRequired,
                              total: reports.length,
                              color: const Color(0xFFDC2626)),
                          _Bar(
                              label: 'Resolved',
                              count: resolved,
                              total: reports.length,
                              color: const Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (categoryEntries.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Section(
                  title: 'Workload by Category',
                  child: _CategoryWorkload(
                      entries: categoryEntries, total: reports.length),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AlertChip extends StatelessWidget {
  final String label;
  const _AlertChip({required this.label});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String text;
  const _Banner(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _Stat(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    letterSpacing: 0.2)),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          child,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message,
          style:
              const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ReportModel report;
  const _ActivityRow({required this.report});

  Color _dot(String s) {
    switch (s) {
      case 'Assigned': return const Color(0xFFF59E0B);
      case 'In Progress': return const Color(0xFF3B82F6);
      case 'Done': return const Color(0xFF8B5CF6);
      case 'Needs Revision': return const Color(0xFFDC2626);
      case 'Resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _dot(report.currentStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.category,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111))),
                const SizedBox(height: 1),
                Text('Brgy. ${report.barangay}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(report.currentStatus,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
              const SizedBox(height: 2),
              Text(DateFormat('MMM d').format(report.updatedAt),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFD1D5DB))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _Bar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)))),
              Text('$count',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryWorkload extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final int total;
  const _CategoryWorkload(
      {required this.entries, required this.total});

  Color _color(int i) {
    const colors = [
      Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFF3B82F6),
      Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF8B5CF6),
      Color(0xFFDC2626), Color(0xFF14B8A6),
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.first.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final idx = e.key;
          final category = e.value.key;
          final count = e.value.value;
          final pct = maxCount > 0 ? count / maxCount : 0.0;
          final color = _color(idx);
          final percentage =
              total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.report_outlined, size: 14, color: color),
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: Text(category,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151)),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text('$count',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  child: Text('$percentage%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
