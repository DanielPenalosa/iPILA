import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/department_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/report_detail_screen.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final String reportId;

  const AdminReportDetailScreen({super.key, required this.reportId});

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final ReportService _service = ReportService();
  final DepartmentService _deptService = DepartmentService();
  final _noteCtrl = TextEditingController();
  File? _afterPhoto;
  XFile? _afterPhotoWeb;
  bool _isUpdating = false;
  bool _disposed = false;
  bool _hasMarkedAsSeen = false;

  @override
  void initState() {
    super.initState();
    _markReportAsSeen();
  }

  Future<void> _markReportAsSeen() async {
    // Wait a bit to get the report data first
    await Future.delayed(const Duration(milliseconds: 500));

    if (_disposed || !mounted || _hasMarkedAsSeen) return;

    try {
      final reportSnapshot = await _service.getReport(widget.reportId).first;
      if (reportSnapshot == null) return;

      // Auto-update to "Under Review" when admin opens a Pending report
      if (reportSnapshot.currentStatus == AppConstants.statusPending) {
        final auth = context.read<AuthProvider>();
        final adminName = auth.user?.fullName ?? 'Admin';

        await _service.updateStatus(
          reportId: widget.reportId,
          newStatus: AppConstants.statusUnderReview,
          updatedBy: adminName,
          note: 'Report viewed by admin',
        );

        _hasMarkedAsSeen = true;
      }
    } catch (e) {
      debugPrint('Error marking report as seen: $e');
      // Silent fail - not critical
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _noteCtrl.dispose();
    super.dispose();
  }

  void _showImageViewer(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAfterPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null && !_disposed && mounted) {
      setState(() {
        _afterPhotoWeb = picked; // Store XFile for web
        // Only create File for mobile
        if (!kIsWeb) {
          _afterPhoto = File(picked.path);
        }
      });
    }
  }

  Future<void> _updateStatus(
    String reportId,
    String newStatus,
    String adminName,
  ) async {
    if (_disposed || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final result = await _service.updateStatus(
        reportId: reportId,
        newStatus: newStatus,
        updatedBy: adminName,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        adminRemarks: null,
        afterPhoto: newStatus == AppConstants.statusResolved
            ? _afterPhoto
            : null,
        afterPhotoWeb: newStatus == AppConstants.statusResolved
            ? _afterPhotoWeb
            : null,
      );

      if (!_disposed && mounted) {
        if (result['success'] == true) {
          _noteCtrl.clear();
          setState(() {
            _afterPhoto = null;
            _afterPhotoWeb = null;
          });
          AppToast.show(
            context,
            'Status updated to $newStatus',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            result['error'] ?? 'Failed to update status',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (!_disposed && mounted) {
        AppToast.show(context, 'Error: ${e.toString()}', type: ToastType.error);
      }
    } finally {
      if (!_disposed && mounted) setState(() => _isUpdating = false);
    }
  }

  void _showUpdateDialog(ReportModel report, String adminName) {
    // Prevent updating resolved reports
    if (report.currentStatus == AppConstants.statusResolved) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              const SizedBox(width: 8),
              const Text('Report Completed'),
            ],
          ),
          content: const Text(
            'This report is marked as completed and locked. No further status updates can be made to maintain data integrity.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Prevent admin from updating when dept is actively working on it
    final deptInProgress =
        report.assignedDepartment != null &&
        report.currentStatus != AppConstants.statusDone &&
        report.currentStatus != AppConstants.statusResolved;

    if (deptInProgress) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Department In Progress'),
            ],
          ),
          content: Text(
            'This report is assigned to ${report.assignedDepartment}. '
            'Status updates are locked until the department marks it as Done.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    String? selectedStatus;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Update Report Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'New Status'),
                items: AppConstants.reportStatuses
                    .where((s) => s != report.currentStatus)
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(
                              AppTheme.statusIcon(s),
                              size: 16,
                              color: AppTheme.statusColor(s),
                            ),
                            const SizedBox(width: 8),
                            Text(s),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModalState(() => selectedStatus = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a note for this status update...',
                ),
                maxLines: 2,
              ),
              if (selectedStatus == AppConstants.statusResolved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.primaryYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will mark the report as officially Resolved.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AdminHoverButton(
                  label: (_afterPhoto != null || _afterPhotoWeb != null)
                      ? 'After photo added ✓'
                      : 'Add After Photo (optional)',
                  icon: Icons.add_a_photo_outlined,
                  onTap: () async {
                    await _pickAfterPhoto();
                    setModalState(() {});
                  },
                  outlined: true,
                  color: (_afterPhoto != null || _afterPhotoWeb != null)
                      ? AppTheme.successGreen
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              AdminHoverButton(
                label: selectedStatus == AppConstants.statusResolved
                    ? 'Resolve'
                    : 'Update',
                onTap: selectedStatus == null
                    ? null
                    : () {
                        final status = selectedStatus!;
                        if (Navigator.canPop(ctx)) {
                          Navigator.pop(ctx);
                        }
                        if (status == AppConstants.statusResolved) {
                          _showCompletionConfirmation(
                            report,
                            status,
                            adminName,
                          );
                        } else {
                          _updateStatus(report.id, status, adminName);
                        }
                      },
                color: selectedStatus == AppConstants.statusResolved
                    ? AppTheme.successGreen
                    : AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionConfirmation(
    ReportModel report,
    String status,
    String adminName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.primaryYellow),
            const SizedBox(width: 8),
            const Text('Final Confirmation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are about to mark this report as COMPLETED.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),
              const Text(
                'This means:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _bulletPoint('The issue has been fully resolved'),
              _bulletPoint('Before & after photos will be published'),
              _bulletPoint('Citizens will be notified of completion'),
              _bulletPoint('The report will be LOCKED (no further edits)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.coral.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppTheme.coral, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. Are you absolutely sure?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.coral,
                        ),
                      ),
                    ),
                  ],
                ),
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
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(report.id, status, adminName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
            child: const Text('Yes, Mark as Completed'),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showAssignToDepartmentDialog(ReportModel report, String adminName) {
    String? selectedDeptUserId;
    String? selectedDeptName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => StreamBuilder(
          stream: _deptService.getDepartmentUsers(),
          builder: (ctx, snapshot) {
            final deptUsers = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Assign to Department'),
              content: deptUsers.isEmpty
                  ? const Text('No department accounts found.')
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Department',
                      ),
                      value: selectedDeptUserId,
                      items: deptUsers
                          .map(
                            (u) => DropdownMenuItem(
                              value: u.uid,
                              child: Text(u.department ?? u.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setDialog(() {
                          selectedDeptUserId = v;
                          selectedDeptName = deptUsers
                              .firstWhere((u) => u.uid == v)
                              .department;
                        });
                      },
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedDeptUserId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await _deptService.assignToDepartment(
                              reportId: report.id,
                              departmentUserId: selectedDeptUserId!,
                              departmentName: selectedDeptName ?? '',
                              assignedByName: adminName,
                              reporterUserId: report.userId,
                            );
                            if (mounted)
                              AppToast.show(
                                context,
                                'Assigned to $selectedDeptName',
                                type: ToastType.success,
                              );
                          } catch (e) {
                            if (mounted)
                              AppToast.show(
                                context,
                                'Error: $e',
                                type: ToastType.error,
                              );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showVerifyDialog(ReportModel report, String adminName) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify & Resolve'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mark this report as officially Resolved.'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _deptService.approveResolution(
                  reportId: report.id,
                  adminName: adminName,
                  reporterUserId: report.userId,
                  departmentUserId: report.assignedDepartmentUserId,
                  remarks: remarksCtrl.text.trim().isEmpty
                      ? null
                      : remarksCtrl.text.trim(),
                );
                if (mounted)
                  AppToast.show(
                    context,
                    'Report resolved',
                    type: ToastType.success,
                  );
              } catch (e) {
                if (mounted)
                  AppToast.show(context, 'Error: $e', type: ToastType.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Resolve'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(ReportModel report, String adminName) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return for Revision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Specify what the department needs to fix.'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (required)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (remarksCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _deptService.returnForRevision(
                  reportId: report.id,
                  adminName: adminName,
                  departmentUserId: report.assignedDepartmentUserId,
                  reporterUserId: report.userId,
                  remarks: remarksCtrl.text.trim(),
                );
                if (mounted)
                  AppToast.show(
                    context,
                    'Returned for revision',
                    type: ToastType.success,
                  );
              } catch (e) {
                if (mounted)
                  AppToast.show(context, 'Error: $e', type: ToastType.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Return for Revision'),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  void _showUrgencyDialog(ReportModel report) {
    String? selected = report.urgencyLevel;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Set Urgency Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['High', 'Medium', 'Low'].map((level) {
              final color = _urgencyColor(level);
              return RadioListTile<String>(
                value: level,
                groupValue: selected,
                onChanged: (v) => set(() => selected = v),
                title: Row(
                  children: [
                    Icon(
                      level == 'High'
                          ? Icons.arrow_upward_rounded
                          : level == 'Low'
                          ? Icons.arrow_downward_rounded
                          : Icons.remove_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                activeColor: color,
              );
            }).toList(),
          ),
          actions: [
            if (report.urgencyLevel != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.setUrgencyLevel(report.id, null);
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _service.setUrgencyLevel(report.id, selected);
                      if (mounted) {
                        AppToast.show(
                          context,
                          'Urgency set to $selected',
                          type: ToastType.success,
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final adminName = auth.user?.fullName ?? 'Admin';

    return PopScope(
      canPop: !_isUpdating,
      onPopInvoked: (didPop) {
        if (!didPop && _isUpdating) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for the update to complete'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Details'),
          actions: [
            if (_isUpdating)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        body: StreamBuilder<ReportModel?>(
          stream: _service.getReport(widget.reportId),
          builder: (context, snapshot) {
            if (_disposed) {
              return const SizedBox.shrink();
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final report = snapshot.data;
            if (report == null) {
              return const Center(child: Text('Report not found.'));
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      // ── Top action bar ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status badge
                            _StatusBadge(status: report.currentStatus),
                            const SizedBox(width: 12),
                            // Department chip
                            if (report.assignedDepartment != null)
                              _InfoChip(
                                icon: Icons.business_outlined,
                                label: report.assignedDepartment!,
                                color: Colors.purple,
                              )
                            else
                              _InfoChip(
                                icon: Icons.person_outline,
                                label: 'Unassigned',
                                color: Colors.grey,
                              ),
                            // Urgency chip
                            if (report.urgencyLevel != null) ...[
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: Icons.flag_outlined,
                                label: report.urgencyLevel!,
                                color: _urgencyColor(report.urgencyLevel),
                              ),
                            ],
                            const Spacer(),
                            // Action buttons
                            if (report.assignedDepartment == null &&
                                report.currentStatus !=
                                    AppConstants.statusResolved)
                              _ActionBtn(
                                label: 'Assign Dept',
                                icon: Icons.business_outlined,
                                color: Colors.purple,
                                onTap: () => _showAssignToDepartmentDialog(
                                  report,
                                  adminName,
                                ),
                              ),
                            if (report.currentStatus ==
                                AppConstants.statusDone) ...[
                              const SizedBox(width: 8),
                              _ActionBtn(
                                label: 'Resolve',
                                icon: Icons.check_circle_outline,
                                color: AppTheme.successGreen,
                                onTap: () =>
                                    _showVerifyDialog(report, adminName),
                              ),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                label: 'Return',
                                icon: Icons.replay_outlined,
                                color: Colors.orange,
                                onTap: () =>
                                    _showReturnDialog(report, adminName),
                              ),
                            ],
                            if (report.currentStatus !=
                                    AppConstants.statusResolved &&
                                report.currentStatus !=
                                    AppConstants.statusDone) ...[
                              const SizedBox(width: 8),
                              _ActionBtn(
                                label: report.urgencyLevel ?? 'Set Urgency',
                                icon: Icons.flag_outlined,
                                color: _urgencyColor(report.urgencyLevel),
                                onTap: () => _showUrgencyDialog(report),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Main content — two columns ──────────────────
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Left column ──────────────────────────
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Resolved / locked banner
                                  if (report.currentStatus ==
                                      AppConstants.statusResolved) ...[
                                    _Banner(
                                      icon: Icons.lock_outline,
                                      color: AppTheme.successGreen,
                                      message:
                                          'This report is resolved and locked. No further status updates can be made.',
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  // Dept locked banner
                                  if (report.assignedDepartment != null &&
                                      report.currentStatus !=
                                          AppConstants.statusDone &&
                                      report.currentStatus !=
                                          AppConstants.statusResolved) ...[
                                    _Banner(
                                      icon: Icons.lock_clock_outlined,
                                      color: Colors.orange,
                                      message:
                                          'Assigned to ${report.assignedDepartment}. Status locked until department marks it Done.',
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Report info card
                                  _SectionCard(
                                    title: 'Report Information',
                                    child: Column(
                                      children: [
                                        _DetailRow(
                                          icon: Icons.category_outlined,
                                          label: 'Category',
                                          value: report.category,
                                        ),
                                        _DetailRow(
                                          icon: Icons.location_on_outlined,
                                          label: 'Barangay',
                                          value: 'Brgy. ${report.barangay}',
                                        ),
                                        _DetailRow(
                                          icon: Icons.gps_fixed,
                                          label: 'Coordinates',
                                          value:
                                              '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                                        ),
                                        _DetailRow(
                                          icon: Icons.person_outlined,
                                          label: 'Reporter',
                                          value: report.isAnonymous
                                              ? 'Anonymous'
                                              : '${report.userFullName} · Brgy. ${report.userBarangay}',
                                        ),
                                        _DetailRow(
                                          icon: Icons.access_time_outlined,
                                          label: 'Submitted',
                                          value: DateFormat(
                                            'MMM d, yyyy · h:mm a',
                                          ).format(report.createdAt),
                                        ),
                                        const Divider(height: 24),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Description',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                report.description,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Community attention card
                                  if (report.followerCount > 0)
                                    _SectionCard(
                                      title: 'Community Attention',
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                report.priority,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.people_outline,
                                              color: _getPriorityColor(
                                                report.priority,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${report.followerCount} ${report.followerCount == 1 ? 'follower' : 'followers'}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: _getPriorityColor(
                                                      report.priority,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                const Text(
                                                  'This report has gained community attention.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                report.priority,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getPriorityLabel(
                                                report.priority,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (report.followerCount > 0)
                                    const SizedBox(height: 16),

                                  // Photos
                                  if (report.photoUrls.isNotEmpty)
                                    _SectionCard(
                                      title: 'Submitted Photos',
                                      child: SizedBox(
                                        height: 160,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: report.photoUrls.length,
                                          itemBuilder: (_, i) =>
                                              GestureDetector(
                                                onTap: () => _showImageViewer(
                                                  context,
                                                  report.photoUrls[i],
                                                  'Photo ${i + 1}',
                                                ),
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 10,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: Image.network(
                                                      report.photoUrls[i],
                                                      width: 160,
                                                      height: 160,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),

                                  if (report.photoUrls.isNotEmpty)
                                    const SizedBox(height: 16),

                                  // Before & After
                                  if (report.afterPhotoUrl != null)
                                    _SectionCard(
                                      title: 'Resolution Evidence',
                                      subtitle: report.completedAt != null
                                          ? 'Completed: ${DateFormat('MMM d, yyyy · h:mm a').format(report.completedAt!)}'
                                          : null,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'BEFORE',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textMuted,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _showImageViewer(
                                                            context,
                                                            report
                                                                .photoUrls
                                                                .first,
                                                            'Before',
                                                          ),
                                                      child: AspectRatio(
                                                        aspectRatio: 4 / 3,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.network(
                                                            report
                                                                .photoUrls
                                                                .first,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: AppTheme.successGreen,
                                                  size: 28,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .successGreen,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'AFTER',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _showImageViewer(
                                                            context,
                                                            report
                                                                .afterPhotoUrl!,
                                                            'After',
                                                          ),
                                                      child: AspectRatio(
                                                        aspectRatio: 4 / 3,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.network(
                                                            report
                                                                .afterPhotoUrl!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (report.completionRemarks !=
                                                  null &&
                                              report
                                                  .completionRemarks!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 14),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Text(
                                              report.completionRemarks!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textMuted,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                  if (report.afterPhotoUrl != null)
                                    const SizedBox(height: 16),

                                  // Follow-ups
                                  _AdminFollowUpsView(reportId: report.id),

                                  // Feedback
                                  if (report.currentStatus ==
                                      AppConstants.statusResolved) ...[
                                    const SizedBox(height: 16),
                                    _AdminFeedbackView(reportId: report.id),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // ── Right column ──────────────────────────
                            SizedBox(
                              width: 300,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline
                                  _SectionCard(
                                    title: 'Status Timeline',
                                    child: ReportTimeline(
                                      history: report.statusHistory,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Builder(
                    builder: (context) {
                      // When assigned to a department and dept hasn't finished yet,
                      // admin cannot manually update status — must wait for dept.
                      final isAssignedToDept =
                          report.assignedDepartment != null;
                      final deptInProgress =
                          isAssignedToDept &&
                          report.currentStatus != AppConstants.statusDone &&
                          report.currentStatus != AppConstants.statusResolved;

                      if (deptInProgress) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_clock_outlined,
                                size: 18,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Assigned to ${report.assignedDepartment}. Status updates are locked until the department marks it as Done.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return AdminHoverButton(
                        label:
                            report.currentStatus == AppConstants.statusResolved
                            ? 'Report Resolved'
                            : 'Update',
                        icon:
                            report.currentStatus == AppConstants.statusResolved
                            ? Icons.check_circle
                            : Icons.update_rounded,
                        onTap:
                            (report.currentStatus ==
                                    AppConstants.statusResolved ||
                                _isUpdating)
                            ? null
                            : () => _showUpdateDialog(report, adminName),
                        color:
                            report.currentStatus == AppConstants.statusResolved
                            ? Colors.grey
                            : AppTheme.primaryBlue,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 5:
        return 'CRITICAL';
      case 4:
        return 'HIGH';
      case 3:
        return 'MEDIUM';
      case 2:
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ── Admin read-only feedback view ─────────────────────────────────────────────

class _AdminFeedbackView extends StatelessWidget {
  final String reportId;
  const _AdminFeedbackView({required this.reportId});

  @override
  Widget build(BuildContext context) {
    final service = ReportService();
    return StreamBuilder<List<ReportFeedback>>(
      stream: service.getFeedback(reportId),
      builder: (context, snap) {
        final list = snap.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.rate_review_outlined,
                  size: 18,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Citizen Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 8),
                if (list.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${list.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No citizen feedback yet.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              )
            else ...[
              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Text(
                      (list.map((f) => f.rating).reduce((a, b) => a + b) /
                              list.length)
                          .toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            final avg =
                                list
                                    .map((f) => f.rating)
                                    .reduce((a, b) => a + b) /
                                list.length;
                            return Icon(
                              (i + 1) <= avg.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: const Color(0xFFFBBF24),
                            );
                          }),
                        ),
                        Text(
                          '${list.length} ${list.length == 1 ? 'review' : 'reviews'}',
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
              const SizedBox(height: 10),
              ...list.map(
                (f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryBlue.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              f.userFullName.isNotEmpty
                                  ? f.userFullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.userFullName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, y').format(f.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                (i + 1) <= f.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.comment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Reporter follow-ups widget ────────────────────────────────────────────────

class _AdminFollowUpsView extends StatelessWidget {
  final String reportId;
  const _AdminFollowUpsView({required this.reportId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .collection('followups')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 18,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Reporter Follow-Ups',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${docs.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final name = d['userFullName'] ?? 'Reporter';
              final msg = d['message'] ?? '';
              final ts = (d['createdAt'] as Timestamp?)?.toDate();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person_pin_circle_outlined,
                      size: 18,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (ts != null)
                                Text(
                                  DateFormat('MMM d, h:mm a').format(ts),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Clean UI widgets for redesigned detail page ──────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
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

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SectionCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                    letterSpacing: 0.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
