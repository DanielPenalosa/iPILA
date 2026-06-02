import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/user_model.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  Stream<List<UserModel>> _getUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<void> _setApproval(String uid, bool accept) async {
    // Capture the ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (accept) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Approve Account',
        message:
            'Are you sure you want to approve this resident account? They will be able to log in immediately.',
        confirmLabel: 'Approve',
      );
      if (!confirmed || !mounted) return;

      try {
        await _db.collection('users').doc(uid).update({
          'isActive': true,
          'approvalStatus': 'approved',
        });

        // Use captured messenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Account approved successfully.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: AppTheme.primaryRed,
            content: Text('Approval failed: $e'),
          ),
        );
      }
    } else {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Reject Registration',
        message:
            'Rejecting this account will permanently delete the registration. The resident will need to register again.',
        confirmLabel: 'Reject & Delete',
        isDanger: true,
      );
      if (!confirmed || !mounted) return;

      try {
        await _db.collection('users').doc(uid).delete();

        // Use captured messenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Registration rejected and deleted.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: AppTheme.primaryRed,
            content: Text('Delete failed: $e'),
          ),
        );
      }
    }
  }

  Future<void> _toggleSuspend(UserModel user) async {
    // Capture the ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final willSuspend = user.isActive;

    final confirmed = await AppDialog.confirm(
      context,
      title: willSuspend ? 'Suspend Account' : 'Reactivate Account',
      message: willSuspend
          ? 'This will prevent ${user.fullName} from logging in. They can be reactivated later.'
          : 'This will allow ${user.fullName} to log in again.',
      confirmLabel: willSuspend ? 'Suspend' : 'Reactivate',
      isDanger: willSuspend,
    );
    if (!confirmed || !mounted) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'isActive': !willSuspend,
      });

      // Use captured messenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: willSuspend ? AppTheme.primaryRed : AppTheme.successGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  willSuspend
                      ? Icons.error_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    willSuspend
                        ? 'Account suspended successfully.'
                        : 'Account reactivated successfully.',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: AppTheme.primaryRed,
          content: Text('Action failed: $e'),
        ),
      );
    }
  }

  void _viewIdPhoto(BuildContext context, String url, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$name — Valid ID',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/users',
      child: Column(
        children: [
          const AdminPageHeader(
            title: 'Users',
            subtitle: 'Municipality of Pila, Laguna',
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _getUsers(),
              builder: (context, snapshot) {
                final all = snapshot.data ?? [];
                final pending = all
                    .where((u) => u.isPending && u.role == 'resident')
                    .toList();
                final active = all.where((u) => u.isApproved).toList();
                final filtered = _search.isEmpty
                    ? active
                    : active
                          .where(
                            (u) =>
                                u.fullName.toLowerCase().contains(
                                  _search.toLowerCase(),
                                ) ||
                                u.email.toLowerCase().contains(
                                  _search.toLowerCase(),
                                ),
                          )
                          .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            value: '${all.length}',
                            label: 'Total Registered',
                            sub: 'All time',
                            subColor: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '${pending.length}',
                            label: 'Pending Approval',
                            sub: pending.isEmpty ? 'All clear' : 'Needs action',
                            subColor: pending.isEmpty
                                ? AppTheme.successGreen
                                : Colors.orange,
                            valueColor: pending.isEmpty
                                ? AppTheme.textDark
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            value: '${active.length}',
                            label: 'Active Users',
                            sub: 'Verified residents',
                            subColor: AppTheme.successGreen,
                            valueColor: AppTheme.successGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pending approval
                      _SectionCard(
                        header: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pending Approval',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${pending.length} accounts awaiting review',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        child: pending.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No pending approvals.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              )
                            : Column(
                                children: [
                                  const _TableHeader(
                                    cols: [
                                      'NAME',
                                      'EMAIL',
                                      'BARANGAY',
                                      'PHONE',
                                      'REGISTERED',
                                      'VALID ID',
                                      'ACTIONS',
                                    ],
                                    widths: [150, 190, 110, 120, 110, 80, 0],
                                  ),
                                  const Divider(height: 1),
                                  ...pending.map(
                                    (u) => _PendingRow(
                                      user: u,
                                      onAccept: () => _setApproval(u.uid, true),
                                      onReject: () =>
                                          _setApproval(u.uid, false),
                                      onViewId: u.idPhotoUrl != null
                                          ? () => _viewIdPhoto(
                                              context,
                                              u.idPhotoUrl!,
                                              u.fullName,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Active users
                      _SectionCard(
                        header: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Users',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              height: 34,
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: InputDecoration(
                                  hintText: 'Search users...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: filtered.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No active users yet.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              )
                            : Column(
                                children: [
                                  const _TableHeader(
                                    cols: [
                                      'NAME',
                                      'EMAIL',
                                      'BARANGAY',
                                      'PHONE',
                                      'ROLE',
                                      'STATUS',
                                      'REGISTERED',
                                      'ACTIONS',
                                    ],
                                    widths: [
                                      150,
                                      180,
                                      110,
                                      120,
                                      70,
                                      80,
                                      100,
                                      0,
                                    ],
                                  ),
                                  const Divider(height: 1),
                                  ...filtered.map(
                                    (u) => _ActiveRow(
                                      user: u,
                                      onToggleSuspend: () => _toggleSuspend(u),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  final Widget header, child;
  const _SectionCard({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: header,
          ),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> cols;
  final List<double> widths;
  const _TableHeader({required this.cols, required this.widths});

  static const _s = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppTheme.textMuted,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: cols.asMap().entries.map((e) {
          final w = widths[e.key];
          final t = Text(e.value, style: _s);
          return w > 0 ? SizedBox(width: w, child: t) : Expanded(child: t);
        }).toList(),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAccept, onReject;
  final VoidCallback? onViewId;

  const _PendingRow({
    required this.user,
    required this.onAccept,
    required this.onReject,
    this.onViewId,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(user.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              user.fullName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 190,
            child: Text(
              user.email,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'Brgy. ${user.barangay}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(user.phone, style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 110,
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          SizedBox(
            width: 80,
            child: onViewId != null
                ? GestureDetector(
                    onTap: onViewId,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'View ID',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    'No ID',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
          ),
          Expanded(
            child: Row(
              children: [
                _ActionBtn(
                  label: 'Accept',
                  color: AppTheme.successGreen,
                  onTap: onAccept,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Reject',
                  color: AppTheme.primaryRed,
                  onTap: onReject,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggleSuspend;
  const _ActiveRow({required this.user, required this.onToggleSuspend});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(user.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              user.email,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'Brgy. ${user.barangay}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(user.phone, style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.role,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppTheme.successGreen.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Suspended',
                style: TextStyle(
                  fontSize: 10,
                  color: user.isActive ? AppTheme.successGreen : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _ActionBtn(
                  label: user.isActive ? 'Suspend' : 'Reactivate',
                  color: user.isActive ? Colors.orange : AppTheme.successGreen,
                  onTap: onToggleSuspend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminHoverButton(
      label: label,
      onTap: onTap,
      color: color,
      small: true,
    );
  }
}
