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

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned':
        return const Color(0xFFF59E0B);
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Done':
        return const Color(0xFF8B5CF6);
      case 'Needs Revision':
        return const Color(0xFFDC2626);
      case 'Resolved':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  void _showUpdateSheet(ReportModel report) {
    final auth = context.read<AuthProvider>();
    String? selectedStatus;
    final remarksCtrl = TextEditingController();
    final List<XFile> photos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Add Progress Update',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 20),
              // Status dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                items: AppConstants.departmentStatuses
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => set(() => selectedStatus = v),
              ),
              const SizedBox(height: 14),
              // Remarks
              TextField(
                controller: remarksCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Action notes or remarks (optional)',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD1D5DB),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              // Photos button
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickMultiImage();
                  set(() => photos.addAll(picked));
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: Text(
                  photos.isEmpty
                      ? 'Attach photos'
                      : '${photos.length} photo(s) attached',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 6),
              if (selectedStatus == AppConstants.statusDone) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This marks the work as done and notifies admin for final review.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: selectedStatus == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        setState(() => _submitting = true);
                        try {
                          if (selectedStatus == AppConstants.statusDone) {
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
                                content: Text('Update saved'),
                                backgroundColor: Color(0xFF10B981),
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
                  backgroundColor: selectedStatus == AppConstants.statusDone
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  selectedStatus == AppConstants.statusDone
                      ? 'Mark as Done'
                      : 'Save Update',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Color(0xFF374151),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Detail',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF3F4F6)),
        ),
      ),
      body: StreamBuilder<ReportModel?>(
        stream: ReportService().getReport(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }

          final statusColor = _statusColor(report.currentStatus);

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Main info ──────────────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  report.category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (report.urgencyLevel != null) ...[
                                    _UrgencyBadge(
                                      urgency: report.urgencyLevel!,
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      report.currentStatus,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            report.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF3F4F6)),
                          const SizedBox(height: 12),
                          _Meta(
                            icon: Icons.location_on_outlined,
                            value: 'Brgy. ${report.barangay}',
                          ),
                          const SizedBox(height: 8),
                          _Meta(
                            icon: Icons.person_outline,
                            value: report.isAnonymous
                                ? 'Anonymous'
                                : report.userFullName,
                          ),
                          const SizedBox(height: 8),
                          _Meta(
                            icon: Icons.calendar_today_outlined,
                            value: DateFormat(
                              'MMM d, yyyy – h:mm a',
                            ).format(report.createdAt),
                          ),
                          if (report.photoUrls.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: report.photoUrls.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
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
                    ),
                    const SizedBox(height: 16),

                    // ── Revision banner ────────────────────────────────
                    if (report.adminVerificationRemarks != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Needs Revision',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    report.adminVerificationRemarks!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Timeline ───────────────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progress Updates',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Timeline(report: report),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              // ── Bottom action area ─────────────────────────────
              Positioned(
                bottom: 20,
                left: 24,
                right: 24,
                child: _DeptBottomAction(
                  report: report,
                  submitting: _submitting,
                  onUpdate: () => _showUpdateSheet(report),
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: child,
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Meta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD1D5DB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final ReportModel report;
  const _Timeline({required this.report});

  Color _color(String s) {
    switch (s) {
      case 'Assigned':
        return const Color(0xFFF59E0B);
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Done':
        return const Color(0xFF8B5CF6);
      case 'Needs Revision':
        return const Color(0xFFDC2626);
      case 'Resolved':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final updates = [...report.progressUpdates]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (updates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No progress updates yet.',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return Column(
      children: updates.map((u) {
        final c = _color(u.status);
        final isLast = u == updates.last;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline gutter
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 52,
                      color: const Color(0xFFF3F4F6),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            u.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, h:mm a').format(u.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${u.updatedBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (u.remarks != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        u.remarks!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                    if (u.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: u.photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              u.photoUrls[i],
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final String urgency;
  const _UrgencyBadge({required this.urgency});

  Color get _color {
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

  IconData get _icon {
    switch (urgency) {
      case 'High':
        return Icons.arrow_upward_rounded;
      case 'Medium':
        return Icons.remove_rounded;
      case 'Low':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            '$urgency Priority',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom action widget ──────────────────────────────────────────────────────

class _DeptBottomAction extends StatelessWidget {
  final ReportModel report;
  final bool submitting;
  final VoidCallback onUpdate;

  const _DeptBottomAction({
    required this.report,
    required this.submitting,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final status = report.currentStatus;

    // Waiting for admin to assign
    if (status == AppConstants.statusPending ||
        status == AppConstants.statusUnderReview) {
      return _InfoBanner(
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF6366F1),
        message: 'Waiting for admin to assign this report to your department.',
      );
    }

    // Department can act — Assigned or Needs Revision
    if (status == AppConstants.statusAssigned ||
        status == AppConstants.statusNeedsRevision ||
        status == AppConstants.statusInProgress) {
      return ElevatedButton.icon(
        onPressed: submitting ? null : onUpdate,
        icon: submitting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, size: 18),
        label: Text(submitting ? 'Saving...' : 'Add Progress Update'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Department submitted as Done — waiting for admin verification
    if (status == AppConstants.statusDone) {
      return _InfoBanner(
        icon: Icons.schedule_rounded,
        color: const Color(0xFF8B5CF6),
        message:
            'Work submitted for admin review. Waiting for final verification.',
      );
    }

    // Resolved — fully closed
    if (status == AppConstants.statusResolved) {
      return _InfoBanner(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        message: 'Report resolved. No further updates needed.',
      );
    }

    // Rejected or any other terminal state
    return _InfoBanner(
      icon: Icons.block_rounded,
      color: const Color(0xFF9CA3AF),
      message: 'This report is closed.',
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
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
                fontSize: 12,
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
