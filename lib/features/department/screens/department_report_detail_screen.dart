import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/department_service.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

class DepartmentReportDetailScreen extends StatefulWidget {
  final String reportId;
  const DepartmentReportDetailScreen({super.key, required this.reportId});

  @override
  State<DepartmentReportDetailScreen> createState() =>
      _DepartmentReportDetailScreenState();
}

class _DepartmentReportDetailScreenState
    extends State<DepartmentReportDetailScreen> {
  final _service = DepartmentService();
  bool _submitting = false;

  void _showProgressUpdateSheet(ReportModel report) {
    final auth = context.read<AuthProvider>();
    String? selectedStatus;
    final remarksCtrl = TextEditingController();
    final List<XFile> photos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                'Add Progress Update',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                items: AppConstants.departmentStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setSheet(() => selectedStatus = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Action Notes',
                  hintText: 'Describe the action taken...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  setSheet(() => photos.addAll(picked));
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  photos.isEmpty
                      ? 'Add Photos (optional)'
                      : '${photos.length} photo(s) selected',
                ),
              ),
              const SizedBox(height: 16),
              // Submit for verification option
              if (selectedStatus == AppConstants.statusForVerification)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'This will submit the report for Admin verification. Make sure all photos and remarks are complete.',
                    style: TextStyle(fontSize: 12, color: Colors.purple),
                  ),
                ),
              ElevatedButton(
                onPressed: selectedStatus == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        setState(() => _submitting = true);
                        try {
                          if (selectedStatus ==
                              AppConstants.statusForVerification) {
                            await _service.submitForVerification(
                              reportId: report.id,
                              departmentName: auth.user?.department ?? '',
                              updatedByName: auth.user?.fullName ?? '',
                              reporterUserId: report.userId,
                              remarks: remarksCtrl.text.trim().isEmpty
                                  ? null
                                  : remarksCtrl.text.trim(),
                              completionPhotosWeb: photos.isEmpty
                                  ? null
                                  : photos,
                            );
                          } else {
                            await _service.addProgressUpdate(
                              reportId: report.id,
                              departmentUserId: auth.user!.uid,
                              departmentName: auth.user?.department ?? '',
                              updatedByName: auth.user?.fullName ?? '',
                              status: selectedStatus!,
                              remarks: remarksCtrl.text.trim().isEmpty
                                  ? null
                                  : remarksCtrl.text.trim(),
                              photosWeb: photos.isEmpty ? null : photos,
                              reporterUserId: report.userId,
                            );
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Progress updated'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.primaryRed,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedStatus == AppConstants.statusForVerification
                      ? Colors.purple
                      : AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  selectedStatus == AppConstants.statusForVerification
                      ? 'Submit for Admin Verification'
                      : 'Save Update',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Report Detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<ReportModel?>(
        stream: ReportService().getReport(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }

          final canUpdate =
              report.currentStatus != AppConstants.statusResolved &&
              report.currentStatus != AppConstants.statusForVerification;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(report: report),
                    const SizedBox(height: 16),
                    if (report.adminVerificationRemarks != null)
                      _RevisionBanner(
                        remarks: report.adminVerificationRemarks!,
                      ),
                    if (report.adminVerificationRemarks != null)
                      const SizedBox(height: 16),
                    _ProgressTimeline(report: report),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (canUpdate)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => _showProgressUpdateSheet(report),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      _submitting ? 'Saving...' : 'Add Progress Update',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

class _InfoCard extends StatelessWidget {
  final ReportModel report;
  const _InfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.category,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: report.currentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const Divider(height: 24),
          _Row(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'Brgy. ${report.barangay}',
          ),
          _Row(
            icon: Icons.person_outline,
            label: 'Reporter',
            value: report.isAnonymous ? 'Anonymous' : report.userFullName,
          ),
          _Row(
            icon: Icons.calendar_today_outlined,
            label: 'Submitted',
            value: DateFormat('MMM d, yyyy – h:mm a').format(report.createdAt),
          ),
          if (report.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report.photoUrls[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevisionBanner extends StatelessWidget {
  final String remarks;
  const _RevisionBanner({required this.remarks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revision Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.red[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin remarks: $remarks',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  final ReportModel report;
  const _ProgressTimeline({required this.report});

  @override
  Widget build(BuildContext context) {
    final updates = [...report.progressUpdates]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Updates',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (updates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No progress updates yet.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            ...updates.map((u) => _UpdateEntry(update: u)),
        ],
      ),
    );
  }
}

class _UpdateEntry extends StatelessWidget {
  final ProgressUpdate update;
  const _UpdateEntry({required this.update});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 60, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: update.status),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, h:mm a').format(update.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${update.updatedBy}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (update.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(update.remarks!, style: const TextStyle(fontSize: 12)),
                ],
                if (update.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: update.photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          update.photoUrls[i],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Assigned':
        return Colors.orange;
      case 'In Progress':
        return const Color(0xFF1565C0);
      case 'For Admin Verification':
        return Colors.purple;
      case 'Revision Required':
        return Colors.red;
      case 'Resolved':
        return AppTheme.successGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
