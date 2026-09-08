import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_shell.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllRead(String adminUid) =>
      _notifService.markAllAsRead(adminUid);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final adminUid = auth.user?.uid ?? '';

    return AdminShell(
      currentRoute: '/admin/alerts',
      child: Column(
        children: [
          AdminPageHeader(
            title: 'Alerts & Notifications',
            subtitle: 'Follow-ups, status changes, and system activity',
            actions: [
              TextButton.icon(
                onPressed: () => _markAllRead(adminUid),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Notifications'),
                Tab(text: 'Report Alerts'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NotificationsTab(adminUid: adminUid, service: _notifService),
                _ReportAlertsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Real Firestore notifications ──────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final String adminUid;
  final NotificationService service;
  const _NotificationsTab({required this.adminUid, required this.service});

  Color _typeColor(String type) {
    switch (type) {
      case 'reporter_followup':
        return Colors.orange[700]!;
      case 'citizen_feedback':
        return Colors.purple;
      case 'report_follow_up':
        return Colors.deepPurple;
      case 'warning':
        return Colors.orange;
      case 'success':
        return AppTheme.successGreen;
      case 'error':
        return AppTheme.primaryRed;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'reporter_followup':
        return Icons.campaign_outlined;
      case 'citizen_feedback':
        return Icons.rate_review_outlined;
      case 'report_follow_up':
        return Icons.people_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (adminUid.isEmpty) {
      return const Center(child: Text('Not authenticated'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: adminUid)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Error loading notifications: ${snap.error}',
              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 12),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
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
                  'No notifications yet.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        final notifs =
            docs.map((d) => NotificationModel.fromFirestore(d)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final unreadCount = notifs.where((n) => !n.isRead).length;

        return Column(
          children: [
            if (unreadCount > 0)
              Container(
                width: double.infinity,
                color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  final color = _typeColor(n.type);
                  final icon = _typeIcon(n.type);
                  return _NotifCard(
                    notif: n,
                    color: color,
                    icon: icon,
                    onRead: () => service.markAsRead(n.id),
                    onView: n.reportId != null && n.reportId!.isNotEmpty
                        ? () {
                            service.markAsRead(n.id);
                            context.push('/admin/reports/${n.reportId}');
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final Color color;
  final IconData icon;
  final VoidCallback onRead;
  final VoidCallback? onView;

  const _NotifCard({
    required this.notif,
    required this.color,
    required this.icon,
    required this.onRead,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onView != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onView ?? onRead,
        child: Container(
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: notif.isRead ? Colors.grey[300]! : color,
                width: notif.isRead ? 2 : 3,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: notif.isRead ? Colors.grey[400] : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: notif.isRead
                                    ? AppTheme.textMuted
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: notif.isRead
                              ? Colors.grey[500]
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _timeAgo(notif.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          if (onView != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· Tap to view report →',
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!notif.isRead)
                  AdminHoverButton(
                    label: 'Read',
                    onTap: onRead,
                    color: AppTheme.textMuted,
                    outlined: true,
                    small: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Tab 2: Report-derived alerts (same as before) ────────────────────────────

class _ReportAlertsTab extends StatefulWidget {
  @override
  State<_ReportAlertsTab> createState() => _ReportAlertsTabState();
}

class _ReportAlertsTabState extends State<_ReportAlertsTab> {
  final Set<String> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportModel>>(
      stream: ReportService().getAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  'No report alerts.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _AlertRow(
            alert: alerts[i],
            onDismiss: () => setState(() => _dismissed.add(alerts[i].reportId)),
            onView: alerts[i].reportId.isNotEmpty
                ? () => context.push('/admin/reports/${alerts[i].reportId}')
                : null,
          ),
        );
      },
    );
  }

  List<_AlertItem> _buildAlerts(List<ReportModel> reports) {
    final alerts = <_AlertItem>[];
    final sorted = List<ReportModel>.from(reports)
      ..sort((a, b) {
        if (a.followerCount >= 5 && b.followerCount < 5) return -1;
        if (b.followerCount >= 5 && a.followerCount < 5) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    for (final r in sorted) {
      final timeAgo = _timeAgo(r.updatedAt);
      if (r.followerCount >= 5) {
        alerts.add(
          _AlertItem(
            type: 'followup',
            message:
                '${r.category} in Brgy. ${r.barangay} has ${r.followerCount} residents following — HIGH PRIORITY.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.followerCount >= 2 &&
          r.currentStatus == AppConstants.statusPending) {
        alerts.add(
          _AlertItem(
            type: 'followup',
            message:
                '${r.category} in Brgy. ${r.barangay} has ${r.followerCount} followers.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.currentStatus == AppConstants.statusPending) {
        alerts.add(
          _AlertItem(
            type: 'new',
            message:
                'New: ${r.category} in Brgy. ${r.barangay} awaiting validation.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.currentStatus == 'Overdue') {
        alerts.add(
          _AlertItem(
            type: 'overdue',
            message: '${r.category} in Brgy. ${r.barangay} is overdue.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else if (r.currentStatus == AppConstants.statusResolved) {
        alerts.add(
          _AlertItem(
            type: 'completed',
            message: '${r.category} in Brgy. ${r.barangay} resolved.',
            reportId: r.id,
            time: timeAgo,
          ),
        );
      } else {
        alerts.add(
          _AlertItem(
            type: 'update',
            message:
                '${r.category} in Brgy. ${r.barangay} → ${r.currentStatus}.',
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
      case 'followup':
        return Colors.deepPurple;
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

  IconData get _icon {
    switch (alert.type) {
      case 'followup':
        return Icons.people_outline;
      case 'new':
        return Icons.fiber_new_outlined;
      case 'overdue':
        return Icons.timer_off_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.update_rounded;
    }
  }

  String get _label {
    switch (alert.type) {
      case 'followup':
        return 'Community';
      case 'new':
        return 'New Report';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Resolved';
      default:
        return 'Update';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onView != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onView,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icon(_icon, size: 18, color: _color),
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
                            text: '$_label: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _color,
                            ),
                          ),
                          TextSpan(text: alert.message),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          alert.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (onView != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· Tap to view →',
                            style: TextStyle(
                              fontSize: 11,
                              color: _color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminHoverButton(
                label: 'Dismiss',
                onTap: onDismiss,
                color: AppTheme.textMuted,
                outlined: true,
                small: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
