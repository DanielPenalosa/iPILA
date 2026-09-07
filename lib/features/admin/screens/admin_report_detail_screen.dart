import 'dart:io';
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

  void _showAssignDialog(ReportModel report) {
    final ctrl = TextEditingController(text: report.assignedTo);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Report'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Staff Name'),
        ),
        actions: [
          AdminHoverButton(
            label: 'Cancel',
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            outlined: true,
            small: true,
          ),
          const SizedBox(width: 8),
          AdminHoverButton(
            label: 'Assign',
            onTap: () async {
              final staffName = ctrl.text.trim();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              if (!_disposed && mounted) {
                await _service.assignReport(report.id, staffName);
              }
            },
            color: AppTheme.primaryBlue,
            small: true,
          ),
        ],
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
                      // Admin action bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assigned to',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    report.assignedTo ?? 'Unassigned',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (report.assignedDepartment != null)
                                    Text(
                                      'Dept: ${report.assignedDepartment}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAssignDialog(report),
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 16,
                              ),
                              label: const Text('Assign'),
                            ),
                            if (report.assignedDepartment == null)
                              TextButton.icon(
                                onPressed: () => _showAssignToDepartmentDialog(
                                  report,
                                  adminName,
                                ),
                                icon: const Icon(
                                  Icons.business_outlined,
                                  size: 16,
                                ),
                                label: const Text('Dept'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.purple,
                                ),
                              ),
                            if (report.currentStatus ==
                                AppConstants.statusDone) ...[
                              TextButton.icon(
                                onPressed: () =>
                                    _showVerifyDialog(report, adminName),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Resolve'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.successGreen,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _showReturnDialog(report, adminName),
                                icon: const Icon(
                                  Icons.replay_outlined,
                                  size: 16,
                                ),
                                label: const Text('Return'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReportStatusBanner(status: report.currentStatus),
                            const SizedBox(height: 16),
                            // Lock indicator for resolved reports
                            if (report.currentStatus ==
                                AppConstants.statusResolved) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.successGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: AppTheme.successGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This report is resolved and locked. No further status updates can be made.',
                                        style: TextStyle(
                                          color: AppTheme.successGreen,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (report.photoUrls.isNotEmpty) ...[
                              const Text(
                                'Photos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: report.photoUrls.length,
                                  itemBuilder: (_, i) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        report.photoUrls[i],
                                        width: 200,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Before & After Photos Display
                            if (report.afterPhotoUrl != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.successGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppTheme.successGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Resolution Evidence',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (report.completedAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Completed: ${DateFormat('MMM d, yyyy h:mm a').format(report.completedAt!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'BEFORE',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () => _showImageViewer(
                                                  context,
                                                  report.photoUrls.first,
                                                  'Before Photo',
                                                ),
                                                child: AspectRatio(
                                                  aspectRatio: 4 / 3,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      report.photoUrls.first,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 24),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: AppTheme.successGreen,
                                                size: 32,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'AFTER',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () => _showImageViewer(
                                                  context,
                                                  report.afterPhotoUrl!,
                                                  'After Photo',
                                                ),
                                                child: AspectRatio(
                                                  aspectRatio: 4 / 3,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      report.afterPhotoUrl!,
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
                                    if (report.completionRemarks != null &&
                                        report
                                            .completionRemarks!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Resolution Details',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  report.completionRemarks!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReportDetailRow(
                                      icon: Icons.category_outlined,
                                      label: 'Category',
                                      value: report.category,
                                    ),
                                    ReportDetailRow(
                                      icon: Icons.location_on_outlined,
                                      label: 'Barangay',
                                      value: 'Brgy. ${report.barangay}',
                                    ),
                                    ReportDetailRow(
                                      icon: Icons.gps_fixed,
                                      label: 'GPS',
                                      value:
                                          '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                                    ),
                                    ReportDetailRow(
                                      icon: Icons.person_outlined,
                                      label: 'Reported by',
                                      value: report.isAnonymous
                                          ? 'Anonymous'
                                          : '${report.userFullName} (Brgy. ${report.userBarangay})',
                                    ),
                                    if (report.followerCount > 0) ...[
                                      const Divider(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                            report.priority,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _getPriorityColor(
                                              report.priority,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.people_outline,
                                                  size: 20,
                                                  color: _getPriorityColor(
                                                    report.priority,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${report.followerCount} ${report.followerCount == 1 ? 'Follower' : 'Followers'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getPriorityColor(
                                                      report.priority,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getPriorityColor(
                                                      report.priority,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _getPriorityLabel(
                                                      report.priority,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'This report has gained community attention. Consider prioritizing this issue.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 20),
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      report.description,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Transparency Timeline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportTimeline(history: report.statusHistory),
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
                  child: AdminHoverButton(
                    label: report.currentStatus == AppConstants.statusResolved
                        ? 'Report Resolved'
                        : 'Update',
                    icon: report.currentStatus == AppConstants.statusResolved
                        ? Icons.check_circle
                        : Icons.update_rounded,
                    onTap:
                        (report.currentStatus == AppConstants.statusResolved ||
                            _isUpdating)
                        ? null
                        : () => _showUpdateDialog(report, adminName),
                    color: report.currentStatus == AppConstants.statusResolved
                        ? Colors.grey
                        : AppTheme.primaryBlue,
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
