import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
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
  final _noteCtrl = TextEditingController();
  File? _afterPhoto;
  bool _isUpdating = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAfterPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null && !_disposed && mounted) {
      setState(() => _afterPhoto = File(picked.path));
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
      await _service.updateStatus(
        reportId: reportId,
        newStatus: newStatus,
        updatedBy: adminName,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        afterPhoto: newStatus == AppConstants.statusCompleted
            ? _afterPhoto
            : null,
      );
      if (!_disposed && mounted) {
        _noteCtrl.clear();
        setState(() => _afterPhoto = null);
        AppToast.show(
          context,
          'Status updated to $newStatus',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (!_disposed && mounted) {
        AppToast.show(
          context,
          'Failed to update status. Please try again.',
          type: ToastType.error,
        );
      }
    } finally {
      if (!_disposed && mounted) setState(() => _isUpdating = false);
    }
  }

  void _showUpdateDialog(ReportModel report, String adminName) {
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
              if (selectedStatus == AppConstants.statusCompleted) ...[
                const SizedBox(height: 12),
                AdminHoverButton(
                  label: _afterPhoto != null
                      ? 'After photo added ✓'
                      : 'Add After Photo',
                  icon: Icons.add_a_photo_outlined,
                  onTap: () async {
                    await _pickAfterPhoto();
                    setModalState(() {});
                  },
                  outlined: true,
                ),
              ],
              const SizedBox(height: 16),
              AdminHoverButton(
                label: 'Update Status',
                onTap: selectedStatus == null
                    ? null
                    : () {
                        final status = selectedStatus!;
                        if (Navigator.canPop(ctx)) {
                          Navigator.pop(ctx);
                        }
                        _updateStatus(report.id, status, adminName);
                      },
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
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
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  report.photoUrls.first,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
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
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  report.afterPhotoUrl!,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
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
                    label: 'Update Status',
                    icon: Icons.update_rounded,
                    onTap: _isUpdating
                        ? null
                        : () => _showUpdateDialog(report, adminName),
                    color: AppTheme.primaryBlue,
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
