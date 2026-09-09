import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/department_service.dart';
import '../../../data/services/barangay_service.dart';
import '../../../data/services/user_management_service.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = FirebaseFirestore.instance;
  final _userService = UserManagementService();
  final _deptService = DepartmentService();
  final _brgyService = BarangayService();
  String _search = '';

  // Bulk selection — ValueNotifier to avoid full StreamBuilder rebuilds
  final _selectedPending = ValueNotifier<Set<String>>({});
  final _selectedActive = ValueNotifier<Set<String>>({});

  @override
  void dispose() {
    _selectedPending.dispose();
    _selectedActive.dispose();
    super.dispose();
  }

  void _togglePending(String uid) {
    final next = Set<String>.from(_selectedPending.value);
    next.contains(uid) ? next.remove(uid) : next.add(uid);
    _selectedPending.value = next;
  }

  void _toggleActive(String uid) {
    final next = Set<String>.from(_selectedActive.value);
    next.contains(uid) ? next.remove(uid) : next.add(uid);
    _selectedActive.value = next;
  }

  // ── Bulk helpers ─────────────────────────────────────────────────────────

  Future<void> _bulkPendingAction(String action) async {
    if (_selectedPending.value.isEmpty) return;
    final ids = _selectedPending.value.toList();
    final count = ids.length;

    final confirmed = await _showConfirmDialog(
      title: action == 'approve'
          ? 'Approve $count Users'
          : 'Reject $count Users',
      message: action == 'approve'
          ? 'Approve all $count selected registrations?'
          : 'Reject and delete all $count selected registrations? This cannot be undone.',
      confirmText: action == 'approve' ? 'Approve All' : 'Reject All',
      isDestructive: action != 'approve',
    );
    if (!confirmed) return;

    try {
      if (action == 'approve') {
        await _userService.bulkApproveUsers(ids);
      } else {
        await _userService.bulkRejectUsers(ids);
      }
      _selectedPending.value = {};
      if (mounted) {
        _userService.showSuccessMessage(
          context,
          '✓ $count users ${action == 'approve' ? 'approved' : 'rejected'}',
        );
      }
    } catch (e) {
      if (mounted) _userService.showErrorMessage(context, 'Error: $e');
    }
  }

  Future<void> _bulkActiveAction(String action) async {
    if (_selectedActive.value.isEmpty) return;
    final ids = _selectedActive.value.toList();
    final count = ids.length;

    final label = switch (action) {
      'suspend' => 'Suspend',
      'reactivate' => 'Reactivate',
      _ => 'Delete',
    };

    final confirmed = await _showConfirmDialog(
      title: '$label $count Users',
      message: '$label all $count selected users?',
      confirmText: '$label All',
      isDestructive: action != 'reactivate',
    );
    if (!confirmed) return;

    try {
      switch (action) {
        case 'suspend':
          await _userService.bulkSuspendUsers(ids);
        case 'reactivate':
          await _userService.bulkReactivateUsers(ids);
        default:
          await _userService.bulkDeleteUsers(ids);
      }
      _selectedActive.value = {};
      if (mounted) {
        _userService.showSuccessMessage(
          context,
          '✓ $count users ${label.toLowerCase()}d',
        );
      }
    } catch (e) {
      if (mounted) _userService.showErrorMessage(context, 'Error: $e');
    }
  }

  void _showCreateDepartmentDialog() {
    String? selectedDept;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool creating = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create Department Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department'),
                  value: selectedDept,
                  items: AppConstants.departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setDialog(() => selectedDept = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: creating || selectedDept == null
                  ? null
                  : () async {
                      setDialog(() => creating = true);
                      try {
                        // Create Firebase Auth account
                        final credential = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                            );
                        await _deptService.createDepartmentUser(
                          uid: credential.user!.uid,
                          fullName: nameCtrl.text.trim().isEmpty
                              ? selectedDept!
                              : nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          department: selectedDept!,
                        );
                        // Sign back in as admin (creating another account signs you out)
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Department account created for $selectedDept',
                              ),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialog(() => creating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.primaryRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBarangayDialog() {
    String? selectedBarangay;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool creating = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create Barangay Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Barangay'),
                  value: selectedBarangay,
                  items: AppConstants.barangays
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setDialog(() => selectedBarangay = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: creating || selectedBarangay == null
                  ? null
                  : () async {
                      setDialog(() => creating = true);
                      try {
                        final credential = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                        );
                        await _brgyService.createBarangayUser(
                          uid: credential.user!.uid,
                          fullName: nameCtrl.text.trim().isEmpty
                              ? 'Brgy. $selectedBarangay'
                              : nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          barangay: selectedBarangay!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Barangay account created for $selectedBarangay'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialog(() => creating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.primaryRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: creating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<UserModel>> _getUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => UserModel.fromFirestore(d))
              .where(
                (user) => user.approvalStatus != 'deleted',
              ) // Filter out deleted users
              .toList(),
        );
  }

  void _handleApprove(UserModel user) async {
    debugPrint('=== APPROVE USER DEBUG === Starting approval for ${user.uid}');
    final confirmed = await _showConfirmDialog(
      title: 'Approve Account',
      message:
          'Approve ${user.fullName}? They will be able to log in immediately.',
      confirmText: 'Approve',
      isDestructive: false,
    );

    debugPrint('=== APPROVE USER DEBUG === Confirmed: $confirmed');

    if (confirmed) {
      try {
        debugPrint('=== APPROVE USER DEBUG === Calling approveUser service');
        await _userService.approveUser(user.uid);
        debugPrint('=== APPROVE USER DEBUG === Success!');
        if (mounted) {
          _userService.showSuccessMessage(
            context,
            '✓ ${user.fullName} approved successfully',
          );
        }
      } catch (e) {
        debugPrint('=== APPROVE USER DEBUG === Error: $e');
        if (mounted) {
          _userService.showErrorMessage(context, 'Failed to approve: $e');
        }
      }
    }
  }

  void _handleReject(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Reject Registration',
      message:
          'Reject ${user.fullName}? This will permanently delete their registration.',
      confirmText: 'Reject & Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _userService.rejectUser(user.uid);
        if (mounted) {
          _userService.showSuccessMessage(
            context,
            '✓ Registration rejected and deleted',
          );
        }
      } catch (e) {
        if (mounted) {
          _userService.showErrorMessage(context, 'Failed to reject: $e');
        }
      }
    }
  }

  void _handleSuspend(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Suspend Account',
      message:
          'Suspend ${user.fullName}? They will not be able to log in until reactivated.',
      confirmText: 'Suspend',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _userService.suspendUser(user.uid);
        if (mounted) {
          _userService.showSuccessMessage(
            context,
            '✓ ${user.fullName} suspended successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          _userService.showErrorMessage(context, 'Failed to suspend: $e');
        }
      }
    }
  }

  void _handleReactivate(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Reactivate Account',
      message:
          'Reactivate ${user.fullName}? They will be able to log in again.',
      confirmText: 'Reactivate',
      isDestructive: false,
    );

    if (confirmed) {
      try {
        await _userService.reactivateUser(user.uid);
        if (mounted) {
          _userService.showSuccessMessage(
            context,
            '✓ ${user.fullName} reactivated successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          _userService.showErrorMessage(context, 'Failed to reactivate: $e');
        }
      }
    }
  }

  void _handleDeleteAccount(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'Permanently delete ${user.fullName}\'s account? This action cannot be undone. All their data including reports will remain but will be orphaned.',
      confirmText: 'Delete Account',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _userService.deleteUser(user.uid);
        if (mounted) {
          _userService.showSuccessMessage(
            context,
            '✓ ${user.fullName}\'s account deleted permanently',
          );
        }
      } catch (e) {
        if (mounted) {
          _userService.showErrorMessage(context, 'Failed to delete: $e');
        }
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AppTheme.primaryRed
                  : AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _viewIdPhoto(String url, String name) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Valid ID Document',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Image with scroll
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox(
                              height: 400,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => const SizedBox(
                              height: 400,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Failed to load ID photo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Hint text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.zoom_in,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pinch or scroll to zoom • Click and drag to pan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final pending = all
                    .where((u) => u.isPending && u.role == 'resident')
                    .toList();
                final active = all.where((u) => u.isApproved).toList();
                final filteredAll = _search.isEmpty
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
                // Split by role
                final citizens = filteredAll
                    .where((u) => u.role == 'resident')
                    .toList();
                final deptUsers = filteredAll
                    .where((u) => u.isDepartment)
                    .toList();
                final admins = filteredAll
                    .where((u) => u.isAdmin)
                    .toList();
                final filtered = filteredAll;

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
                            : ValueListenableBuilder<Set<String>>(
                                valueListenable: _selectedPending,
                                builder: (_, sel, __) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bulk bar
                                    if (sel.isNotEmpty)
                                      _UserBulkBar(
                                        count: sel.length,
                                        actions: [
                                          _BulkAction(
                                            label: 'Approve',
                                            color: AppTheme.successGreen,
                                            onTap: () =>
                                                _bulkPendingAction('approve'),
                                          ),
                                          _BulkAction(
                                            label: 'Reject',
                                            color: AppTheme.primaryRed,
                                            onTap: () =>
                                                _bulkPendingAction('reject'),
                                          ),
                                        ],
                                        onClear: () =>
                                            _selectedPending.value = {},
                                      ),
                                    _TableHeader(
                                      cols: const [
                                        '',
                                        'NAME',
                                        'EMAIL',
                                        'BARANGAY',
                                        'PHONE',
                                        'REGISTERED',
                                        'VALID ID',
                                        'ACTIONS',
                                      ],
                                      widths: const [
                                        36,
                                        150,
                                        190,
                                        110,
                                        120,
                                        110,
                                        80,
                                        0,
                                      ],
                                      selectAll: sel.length == pending.length,
                                      onSelectAll: () {
                                        if (sel.length == pending.length) {
                                          _selectedPending.value = {};
                                        } else {
                                          _selectedPending.value = Set.from(
                                            pending.map((u) => u.uid),
                                          );
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ...pending.map(
                                      (u) => _PendingRow(
                                        user: u,
                                        isSelected: sel.contains(u.uid),
                                        onToggleSelect: () =>
                                            _togglePending(u.uid),
                                        onAccept: () => _handleApprove(u),
                                        onReject: () => _handleReject(u),
                                        onViewId:
                                            u.idPhotoUrl != null &&
                                                u.idPhotoUrl!.isNotEmpty
                                            ? () => _viewIdPhoto(
                                                u.idPhotoUrl!,
                                                u.fullName,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
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
                            : ValueListenableBuilder<Set<String>>(
                                valueListenable: _selectedActive,
                                builder: (_, sel, __) {
                                  // Shared table header
                                  final tableHeader = _TableHeader(
                                    cols: const [
                                      '',
                                      'NAME',
                                      'EMAIL',
                                      'BARANGAY',
                                      'PHONE',
                                      'ROLE',
                                      'STATUS',
                                      'REGISTERED',
                                      'ACTIONS',
                                    ],
                                    widths: const [
                                      36,
                                      150,
                                      180,
                                      110,
                                      120,
                                      70,
                                      80,
                                      100,
                                      0,
                                    ],
                                    selectAll:
                                        filtered.isNotEmpty &&
                                        sel.length == filtered.length,
                                    onSelectAll: () {
                                      if (sel.length == filtered.length) {
                                        _selectedActive.value = {};
                                      } else {
                                        _selectedActive.value = Set.from(
                                          filtered.map((u) => u.uid),
                                        );
                                      }
                                    },
                                  );

                                  Widget buildGroup(
                                    List<UserModel> users,
                                    String label,
                                    Color accent,
                                    IconData icon,
                                  ) {
                                    final currentUid = FirebaseAuth
                                        .instance
                                        .currentUser
                                        ?.uid;
                                    if (users.isEmpty) return const SizedBox();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Group label bar
                                        Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            16,
                                            12,
                                            16,
                                            0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.07,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                icon,
                                                size: 14,
                                                color: accent,
                                              ),
                                              const SizedBox(width: 7),
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: accent,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: accent.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${users.length}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: accent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Rows with left accent border
                                        Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            16,
                                            6,
                                            16,
                                            0,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: accent,
                                                width: 3,
                                              ),
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                  topLeft: Radius.circular(4),
                                                ),
                                          ),
                                          child: Column(
                                            children: users.map((u) {
                                              return _ActiveRow(
                                                user: u,
                                                isSelected: sel.contains(u.uid),
                                                onToggleSelect: () =>
                                                    _toggleActive(u.uid),
                                                onToggleSuspend: () =>
                                                    u.isActive
                                                    ? _handleSuspend(u)
                                                    : _handleReactivate(u),
                                                onDelete: () =>
                                                    _handleDeleteAccount(u),
                                                accentColor: accent,
                                                isSelf: u.uid == currentUid,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (sel.isNotEmpty)
                                        _UserBulkBar(
                                          count: sel.length,
                                          actions: [
                                            _BulkAction(
                                              label: 'Suspend',
                                              color: Colors.orange,
                                              onTap: () =>
                                                  _bulkActiveAction('suspend'),
                                            ),
                                            _BulkAction(
                                              label: 'Reactivate',
                                              color: AppTheme.successGreen,
                                              onTap: () => _bulkActiveAction(
                                                'reactivate',
                                              ),
                                            ),
                                            _BulkAction(
                                              label: 'Delete',
                                              color: AppTheme.primaryRed,
                                              onTap: () =>
                                                  _bulkActiveAction('delete'),
                                            ),
                                          ],
                                          onClear: () =>
                                              _selectedActive.value = {},
                                        ),
                                      tableHeader,
                                      const Divider(height: 1),
                                      buildGroup(
                                        citizens,
                                        'Citizens',
                                        AppTheme.primaryBlue,
                                        Icons.people_outline,
                                      ),
                                      buildGroup(
                                        deptUsers,
                                        'Department',
                                        Colors.purple,
                                        Icons.business_outlined,
                                      ),
                                      buildGroup(
                                        admins,
                                        'Admin',
                                        const Color(0xFFDC2626),
                                        Icons.admin_panel_settings_outlined,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Department Accounts
                      _SectionCard(
                        header: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Department Accounts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showCreateDepartmentDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Department'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        child: StreamBuilder<List<UserModel>>(
                          stream: _deptService.getDepartmentUsers(),
                          builder: (ctx, snap) {
                            final deptUsers = snap.data ?? [];
                            if (deptUsers.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No department accounts yet.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              );
                            }
                            return Column(
                              children: deptUsers
                                  .map(
                                    (u) => ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.purple
                                            .withValues(alpha: 0.15),
                                        child: const Icon(
                                          Icons.business,
                                          color: Colors.purple,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        u.department ?? u.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        u.email,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Department',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.purple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Barangay Accounts
                      _SectionCard(
                        header: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Barangay Accounts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showCreateBarangayDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Barangay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        child: StreamBuilder<List<UserModel>>(
                          stream: _brgyService.getBarangayUsers(),
                          builder: (ctx, snap) {
                            final brgyUsers = snap.data ?? [];
                            if (brgyUsers.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No barangay accounts yet.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              );
                            }
                            return Column(
                              children: brgyUsers.map((u) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF10B981)
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.location_city_outlined,
                                      color: Color(0xFF10B981),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    u.barangay.isNotEmpty
                                        ? 'Brgy. ${u.barangay}'
                                        : u.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    u.email,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Barangay',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
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
  final bool selectAll;
  final VoidCallback? onSelectAll;
  const _TableHeader({
    required this.cols,
    required this.widths,
    this.selectAll = false,
    this.onSelectAll,
  });

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
          // First col is the checkbox column
          if (e.key == 0 && onSelectAll != null) {
            return SizedBox(
              width: w,
              child: Checkbox(
                value: selectAll,
                onChanged: (_) => onSelectAll!(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }
          final t = Text(e.value, style: _s);
          return w > 0 ? SizedBox(width: w, child: t) : Expanded(child: t);
        }).toList(),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onAccept, onReject;
  final VoidCallback? onViewId;

  const _PendingRow({
    required this.user,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onAccept,
    required this.onReject,
    this.onViewId,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(user.createdAt);
    return Container(
      color: isSelected ? const Color(0xFFF0F4FF) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
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
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Text(
                            'View ID',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
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
                    label: 'Approve',
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
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleSuspend;
  final VoidCallback onDelete;
  final Color? accentColor;
  final bool isSelf;
  const _ActiveRow({
    required this.user,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onToggleSuspend,
    required this.onDelete,
    this.accentColor,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(user.createdAt);
    final accent = accentColor ?? AppTheme.primaryBlue;
    return Container(
      color: isSelected
          ? accent.withValues(alpha: 0.07)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: isSelf
                  ? const SizedBox(width: 36)
                  : Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
            ),
            SizedBox(
              width: 150,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: accent,
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
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 10,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
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
                  if (isSelf)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Your account',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _ActionBtn(
                      label: user.isActive ? 'Suspend' : 'Reactivate',
                      color: user.isActive
                          ? Colors.orange
                          : AppTheme.successGreen,
                      onTap: onToggleSuspend,
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      label: 'Delete',
                      color: AppTheme.primaryRed,
                      onTap: onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk UI helpers ───────────────────────────────────────────────────────────

class _BulkAction {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BulkAction({
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _UserBulkBar extends StatelessWidget {
  final int count;
  final List<_BulkAction> actions;
  final VoidCallback onClear;
  const _UserBulkBar({
    required this.count,
    required this.actions,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
        color: Color(0xFFF6F8FF),
      ),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          ...actions.expand(
            (a) => [
              InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    a.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: a.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: const Color(0xFFDDE3F0),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Clear',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
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
    debugPrint('=== ACTION BUTTON === Building button: $label');
    return AdminHoverButton(
      label: label,
      onTap: () {
        debugPrint('=== ACTION BUTTON === Button tapped: $label');
        onTap();
      },
      color: color,
      small: true,
    );
  }
}
