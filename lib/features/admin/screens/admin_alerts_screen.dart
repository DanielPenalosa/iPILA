import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import 'admin_shell.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final Set<String> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/alerts',
      child: Column(
        children: [
          const AdminPageHeader(
            title: 'Alerts',
            subtitle: 'Municipality of Pila, Laguna',
          ),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: ReportService().getAllReports(),
              builder: (context, snapshot) {
                final reports = (snapshot.data ?? [])
                    .where((r) => !_dismissed.contains(r.id))
                    .toList();

                final alerts = _buildAlerts(reports);

                if (alerts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No alerts at this time.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: alerts.length,
                  separatorBuilder: (_, _x) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AlertRow(
                    alert: alerts[i],
                    onDismiss: () =>
                        setState(() => _dismissed.add(alerts[i].reportId)),
                    onView: alerts[i].reportId.isNotEmpty
                        ? () => context.push(
                            '/admin/reports/${alerts[i].reportId}',
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_AlertItem> _buildAlerts(List<ReportModel> reports) {
    final alerts = <_AlertItem>[];
    for (final r in reports) {
      final timeAgo = _timeAgo(r.updatedAt);
      if (r.currentStatus == 'Submitted') {
        alerts.add(
          _AlertItem(
            type: 'new',
            message:
                'New Report: ${r.category} in Brgy. ${r.barangay} awaiting validation. Reported by ${r.userFullName}.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.currentStatus == 'Overdue') {
        alerts.add(
          _AlertItem(
            type: 'overdue',
            message:
                'Overdue: ${r.category} in Brgy. ${r.barangay} is past the target resolution date.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.currentStatus == 'Completed') {
        alerts.add(
          _AlertItem(
            type: 'completed',
            message:
                'Completed: ${r.category} in Brgy. ${r.barangay} marked as completed.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else {
        alerts.add(
          _AlertItem(
            type: 'update',
            message:
                'Status Update: ${r.category} in Brgy. ${r.barangay} moved to ${r.currentStatus}.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      }
    }
    return alerts;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _AlertItem {
  final String type, message, reportId, time;
  const _AlertItem({
    required this.type,
    required this.message,
    required this.reportId,
    required this.time,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertItem alert;
  final VoidCallback onDismiss;
  final VoidCallback? onView;
  const _AlertRow({required this.alert, required this.onDismiss, this.onView});

  Color get _color {
    switch (alert.type) {
      case 'new':
        return Colors.orange;
      case 'overdue':
        return AppTheme.primaryRed;
      case 'completed':
        return AppTheme.successGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case 'new':
        return 'New Report';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Completed';
      default:
        return 'Status Update';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                    children: [
                      TextSpan(
                        text: '$_typeLabel: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _color,
                        ),
                      ),
                      TextSpan(
                        text: alert.message.replaceFirst('$_typeLabel: ', ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onView != null) ...[
            AdminHoverButton(
              label: 'View',
              onTap: onView!,
              color: AppTheme.primaryBlue,
              outlined: true,
              small: true,
            ),
            const SizedBox(width: 8),
          ],
          AdminHoverButton(
            label: 'Dismiss',
            onTap: onDismiss,
            color: AppTheme.textMuted,
            outlined: true,
            small: true,
          ),
        ],
      ),
    );
  }
}
