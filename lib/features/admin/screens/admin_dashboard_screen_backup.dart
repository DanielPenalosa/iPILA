import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin',
      child: StreamBuilder<List<ReportModel>>(
        stream: ReportService().getAllReports(),
        builder: (context, snapshot) {
          final reports = snapshot.data ?? [];
          final total = reports.length;
          final awaiting = reports
              .where((r) => r.currentStatus == AppConstants.statusSubmitted)
              .length;
          final inProgress = reports
              .where((r) => r.currentStatus == AppConstants.statusInProgress)
              .length;
          final resolved = reports
              .where((r) => r.currentStatus == AppConstants.statusCompleted)
              .length;
          final overdue = reports
              .where((r) => r.currentStatus == 'Overdue')
              .length;
          final resolvedRate = total == 0
              ? '0%'
              : '${(resolved / total * 100).toStringAsFixed(1)}% rate';

          // Acknowledgment stats
          int acknowledged = 0;
          int missedWindow = 0;
          Duration totalResponse = Duration.zero;
          int responseCount = 0;
          for (final r in reports) {
            if (r.statusHistory.length > 1) {
              final diff = r.statusHistory[1].timestamp.difference(r.createdAt);
              totalResponse += diff;
              responseCount++;
              if (diff.inHours <= 24)
                acknowledged++;
              else
                missedWindow++;
            }
          }
          final avgH = responseCount > 0
              ? (totalResponse.inMinutes ~/ responseCount) ~/ 60
              : 0;
          final avgM = responseCount > 0
              ? (totalResponse.inMinutes ~/ responseCount) % 60
              : 0;
          final avgStr = responseCount > 0 ? '${avgH}h ${avgM}m' : 'N/A';
          final ackRate = total == 0 ? 0.0 : acknowledged / total;

          // Response time by category
          final Map<String, List<int>> catTimes = {};
          for (final r in reports) {
            if (r.statusHistory.length > 1) {
              final mins = r.statusHistory[1].timestamp
                  .difference(r.createdAt)
                  .inMinutes;
              catTimes.putIfAbsent(r.category, () => []).add(mins);
            }
          }
          final catAvg = catTimes.entries.map((e) {
            final avg = e.value.reduce((a, b) => a + b) ~/ e.value.length;
            return MapEntry(e.key, avg);
          }).toList()..sort((a, b) => a.value.compareTo(b.value));
          final maxCatMin = catAvg.isEmpty ? 1 : catAvg.last.value;

          final needsAttention = reports
              .where((r) => r.currentStatus == AppConstants.statusSubmitted)
              .take(5)
              .toList();
          final recentActivity = reports.take(6).toList();

          return Column(
            children: [
              const AdminPageHeader(title: 'Overview'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stat cards ──────────────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            value: '$total',
                            label: 'Total Reports',
                            sub: total == 0 ? 'No reports yet' : 'All time',
                            subColor: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '$awaiting',
                            label: 'Awaiting Validation',
                            sub: awaiting == 0 ? 'All clear' : 'Needs action',
                            subColor: awaiting == 0
                                ? AppTheme.successGreen
                                : Colors.orange,
                            valueColor: awaiting == 0
                                ? AppTheme.textDark
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '$inProgress',
                            label: 'In Progress',
                            sub: 'Active repairs',
                            subColor: AppTheme.textMuted,
                            valueColor: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '$resolved',
                            label: 'Resolved',
                            sub: resolvedRate,
                            subColor: AppTheme.successGreen,
                            valueColor: AppTheme.successGreen,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '$overdue',
                            label: 'Overdue',
                            sub: overdue == 0 ? 'None' : 'Past deadline',
                            subColor: overdue == 0
                                ? AppTheme.successGreen
                                : AppTheme.primaryRed,
                            valueColor: overdue == 0
                                ? AppTheme.textDark
                                : AppTheme.primaryRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Middle row ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Acknowledgment rate
                          Expanded(
                            flex: 5,
                            child: _WhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Acknowledgment Rate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Reports reviewed within the 24-hour target window',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 140,
                                              height: 140,
                                              child: CircularProgressIndicator(
                                                value: ackRate,
                                                strokeWidth: 12,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      ackRate >= 0.8
                                                          ? AppTheme
                                                                .successGreen
                                                          : ackRate >= 0.5
                                                          ? Colors.orange
                                                          : AppTheme.primaryRed,
                                                    ),
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${(ackRate * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 32,
                                                    height: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'rate',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _AckStat(
                                            label: 'Acknowledged',
                                            value: '$acknowledged',
                                            color: AppTheme.successGreen,
                                          ),
                                          const SizedBox(height: 8),
                                          _AckStat(
                                            label: 'Missed window',
                                            value: '$missedWindow',
                                            color: AppTheme.primaryRed,
                                          ),
                                          const SizedBox(height: 8),
                                          _AckStat(
                                            label: 'Avg. response time',
                                            value: avgStr,
                                            color: AppTheme.textDark,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Response time by category
                          Expanded(
                            flex: 4,
                            child: _WhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RESPONSE TIME BY CATEGORY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (catAvg.isEmpty)
                                    const Text(
                                      'No response data yet.',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    ...catAvg.take(6).map((e) {
                                      final h = e.value ~/ 60;
                                      final m = e.value % 60;
                                      final label = h > 0
                                          ? '${h}h ${m}m'
                                          : '${m}m';
                                      final ratio = e.value / maxCatMin;
                                      final color = ratio < 0.4
                                          ? AppTheme.successGreen
                                          : ratio < 0.7
                                          ? Colors.orange
                                          : AppTheme.primaryRed;
                                      return _ResponseRow(
                                        label: e.key,
                                        time: label,
                                        color: color,
                                        value: ratio.clamp(0.05, 1.0),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Bottom row ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Needs attention
                          Expanded(
                            child: _WhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Needs Attention',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      AdminHoverButton(
                                        label: 'View all →',
                                        onTap: () =>
                                            context.go('/admin/reports'),
                                        outlined: true,
                                        small: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (needsAttention.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: AppTheme.successGreen,
                                              size: 32,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'All caught up!',
                                              style: TextStyle(
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ...needsAttention.map(
                                      (r) => _AttentionRow(
                                        report: r,
                                        onTap: () => context.push(
                                          '/admin/reports/${r.id}',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Recent activity
                          Expanded(
                            child: _WhiteCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Activity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (recentActivity.isEmpty)
                                    const Text(
                                      'No activity yet.',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                      ),
                                    )
                                  else
                                    ...recentActivity.map(
                                      (r) => _ActivityRow(report: r),
                                    ),
                                ],
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

// ── Shared widgets ────────────────────────────────────────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AdminHoverCard(child: child);
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                color: subColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AckStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AckStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ResponseRow extends StatelessWidget {
  final String label, time;
  final Color color;
  final double value;
  const _ResponseRow({
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
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

class _AttentionRow extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  const _AttentionRow({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final adminName = auth.user?.fullName ?? 'Admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Brgy. ${report.barangay} · ${report.userFullName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: report.currentStatus),
          const SizedBox(width: 6),
          _QuickBtn(
            label: 'Validate',
            color: AppTheme.successGreen,
            onTap: () async {
              await ReportService().updateStatus(
                reportId: report.id,
                newStatus: AppConstants.statusValidated,
                updatedBy: adminName,
              );
            },
          ),
          const SizedBox(width: 4),
          _QuickBtn(
            label: 'Reject',
            color: AppTheme.primaryRed,
            onTap: () async {
              await ReportService().updateStatus(
                reportId: report.id,
                newStatus: AppConstants.statusRejected,
                updatedBy: adminName,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ReportModel report;
  const _ActivityRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final timeAgo = _timeAgo(report.updatedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                    children: [
                      TextSpan(
                        text: report.category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(
                        text: ' in Brgy. ',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      TextSpan(text: report.barangay),
                      const TextSpan(
                        text: ' → ',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      TextSpan(
                        text: report.currentStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
