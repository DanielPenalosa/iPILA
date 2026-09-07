import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

class DepartmentNotificationsScreen extends StatelessWidget {
  const DepartmentNotificationsScreen({super.key});

  Future<void> _markAllRead(String userId) async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .doc(docId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(60)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final notifications =
            docs.map((d) => NotificationModel.fromFirestore(d)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final unread = notifications.where((n) => !n.isRead).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (unread > 0)
                    TextButton(
                      onPressed: () => _markAllRead(user.uid),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              if (notifications.isEmpty)
                const _Empty()
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFF9FAFB),
                      indent: 56,
                    ),
                    itemBuilder: (_, i) => _NotifTile(
                      n: notifications[i],
                      onTap: () {
                        if (!notifications[i].isRead)
                          _markRead(notifications[i].id);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 12),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel n;
  final VoidCallback onTap;
  const _NotifTile({required this.n, required this.onTap});

  IconData get _icon {
    switch (n.type) {
      case 'assignment':
        return Icons.assignment_ind_outlined;
      case 'progress':
        return Icons.sync_rounded;
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (n.type) {
      case 'assignment':
        return const Color(0xFFF59E0B);
      case 'progress':
        return const Color(0xFF3B82F6);
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : const Color(0xFFFAFAFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 16, color: _color),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a').format(n.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!n.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
