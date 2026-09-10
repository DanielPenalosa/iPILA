import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  void _openImageViewer(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenImageViewer(
        urls: urls,
        initialIndex: initialIndex,
      ),
    );
  }

  void _showUpdateSheet(ReportModel report) {
    final auth = context.read<AuthProvider>();
    String? selectedStatus;
    final remarksCtrl = TextEditingController();
    final List<XFile> photos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final isDone = selectedStatus == AppConstants.statusDone;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            size: 18, color: Color(0xFF374151)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress Update',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111))),
                          Text('Update the status of this report',
                              style: TextStyle(fontSize: 12,
                                  color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // status picker
                  const Text('Status',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.departmentStatuses.map((s) {
                      final selected = selectedStatus == s;
                      final color = AppTheme.statusColor(s);
                      return GestureDetector(
                        onTap: () => set(() => selectedStatus = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.12)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? color : const Color(0xFFE5E7EB),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected ? color : const Color(0xFF6B7280),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // remarks
                  const Text('Notes / Remarks',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: selectedStatus == null
                          ? 'Select a status first...'
                          : isDone
                              ? 'Describe the completed work...'
                              : 'What actions have been taken? (optional)',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFFD1D5DB)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  // photo attach — only required/shown for Done
                  if (isDone) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 15, color: Color(0xFF7C3AED)),
                              SizedBox(width: 6),
                              Text('Completion Photo',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7C3AED))),
                              SizedBox(width: 4),
                              Text('(required)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFDC2626))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Attach a photo showing the completed work.',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              final picked =
                                  await ImagePicker().pickMultiImage();
                              set(() => photos
                                ..clear()
                                ..addAll(picked));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: photos.isEmpty
                                    ? Colors.white
                                    : const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: photos.isEmpty
                                      ? const Color(0xFFDDD6FE)
                                      : const Color(0xFF7C3AED),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    photos.isEmpty
                                        ? Icons.add_photo_alternate_outlined
                                        : Icons.check_circle_outline,
                                    size: 16,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    photos.isEmpty
                                        ? 'Attach photos'
                                        : '${photos.length} photo(s) attached',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Marking as Done will notify admin for final verification.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFD97706)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // save button
                  ElevatedButton(
                    onPressed: (selectedStatus == null ||
                            (isDone && photos.isEmpty))
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _submitting = true);
                            try {
                              if (isDone) {
                                await _service.submitForVerification(
                                  reportId: report.id,
                                  departmentName:
                                      auth.user?.department ?? '',
                                  updatedByName:
                                      auth.user?.fullName ?? '',
                                  reporterUserId: report.userId,
                                  remarks: remarksCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : remarksCtrl.text.trim(),
                                  completionPhotosWeb: photos,
                                );
                              } else {
                                await _service.addProgressUpdate(
                                  reportId: report.id,
                                  departmentUserId: auth.user!.uid,
                                  departmentName:
                                      auth.user?.department ?? '',
                                  updatedByName:
                                      auth.user?.fullName ?? '',
                                  status: selectedStatus!,
                                  remarks: remarksCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : remarksCtrl.text.trim(),
                                  photosWeb: null,
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
                              if (mounted)
                                setState(() => _submitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF111111),
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone
                              ? Icons.verified_outlined
                              : Icons.save_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? 'Mark as Done' : 'Save Update',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Top info bar (mirrors admin action bar) ──────────
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
                      _StatusBadge(status: report.currentStatus),
                      const SizedBox(width: 12),
                      if (report.urgencyLevel != null)
                        _InfoChip(
                          icon: report.urgencyLevel == 'Critical'
                              ? Icons.arrow_upward_rounded
                              : report.urgencyLevel == 'Minor'
                              ? Icons.arrow_downward_rounded
                              : Icons.remove_rounded,
                          label: '${report.urgencyLevel} Priority',
                          color: _urgencyColor(report.urgencyLevel),
                        ),
                      if (report.assignedDepartment != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.business_outlined,
                          label: report.assignedDepartment!,
                          color: Colors.purple,
                        ),
                      ],
                      const Spacer(),
                      // Go to Map button
                      _ActionBtn(
                        label: 'Go to Map',
                        icon: Icons.map_outlined,
                        color: AppTheme.primaryBlue,
                        onTap: () => context.go('/department/map'),
                      ),
                      const SizedBox(width: 8),
                      // Action button — only when dept can act
                      if (report.currentStatus == AppConstants.statusAssigned ||
                          report.currentStatus ==
                              AppConstants.statusInProgress ||
                          report.currentStatus ==
                              AppConstants.statusNeedsRevision)
                        _ActionBtn(
                          label: _submitting
                              ? 'Saving...'
                              : 'Add Progress Update',
                          icon: Icons.add_rounded,
                          color: const Color(0xFF111111),
                          onTap: _submitting
                              ? () {}
                              : () => _showUpdateSheet(report),
                        ),
                    ],
                  ),
                ),

                // ── Main content — two columns ────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left column ─────────────────────────────────
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status banners
                            _DeptStatusBanner(report: report),
                            const SizedBox(height: 16),

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
                                    icon: Icons.person_outline,
                                    label: 'Reporter',
                                    value: report.isAnonymous
                                        ? 'Anonymous'
                                        : report.userFullName,
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

                            // Photos
                            if (report.photoUrls.isNotEmpty) ...[
                              _SectionCard(
                                title: 'Submitted Photos',
                                child: SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: report.photoUrls.length,
                                    itemBuilder: (_, i) => GestureDetector(
                                      onTap: () => _openImageViewer(
                                        context,
                                        report.photoUrls,
                                        i,
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 10),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              report.photoUrls[i],
                                              width: 140,
                                              height: 140,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Revision remarks from admin
                            if (report.adminVerificationRemarks != null) ...[
                              _Banner(
                                icon: Icons.undo_rounded,
                                color: const Color(0xFFDC2626),
                                message:
                                    'Revision required: ${report.adminVerificationRemarks!}',
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Before & After photos (visible once admin resolves)
                            if (report.afterPhotoUrl != null &&
                                report.photoUrls.isNotEmpty) ...[
                              _SectionCard(
                                title: 'Resolution Evidence',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
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
                                                      BorderRadius.circular(6),
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
                                                onTap: () => _openImageViewer(
                                                  context,
                                                  report.photoUrls,
                                                  0,
                                                ),
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: AspectRatio(
                                                    aspectRatio: 4 / 3,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: Image.network(
                                                        report.photoUrls.first,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 48,
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: AppTheme.successGreen,
                                            size: 28,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
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
                                                onTap: () => _openImageViewer(
                                                  context,
                                                  [report.afterPhotoUrl!],
                                                  0,
                                                ),
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: AspectRatio(
                                                    aspectRatio: 4 / 3,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: Image.network(
                                                        report.afterPhotoUrl!,
                                                        fit: BoxFit.cover,
                                                      ),
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
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
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
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // ── Right column ─────────────────────────────────
                      SizedBox(
                        width: 300,
                        child: _SectionCard(
                          title: 'Status Timeline',
                          child: _StatusTimeline(history: report.statusHistory),
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
    );
  }

  Color _urgencyColor(String? u) {
    switch (u) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'Moderate':
        return const Color(0xFFF59E0B);
      case 'Minor':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

// ── Status banner for dept context ───────────────────────────────────────────

class _DeptStatusBanner extends StatelessWidget {
  final ReportModel report;
  const _DeptStatusBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    final status = report.currentStatus;

    if (status == AppConstants.statusPending ||
        status == AppConstants.statusUnderReview) {
      return _Banner(
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF6366F1),
        message: 'Waiting for admin to assign this report to your department.',
      );
    }
    if (status == AppConstants.statusDone) {
      return _Banner(
        icon: Icons.schedule_rounded,
        color: const Color(0xFF8B5CF6),
        message:
            'Work submitted for admin review. Waiting for final verification.',
      );
    }
    if (status == AppConstants.statusResolved) {
      return _Banner(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        message: 'Report resolved. No further updates needed.',
      );
    }
    if (status == AppConstants.statusNeedsRevision) {
      return _Banner(
        icon: Icons.replay_outlined,
        color: const Color(0xFFDC2626),
        message:
            'Admin returned this report for revision. Please review and resubmit.',
      );
    }
    // Assigned or In Progress — no banner needed, action btn is in top bar
    return const SizedBox.shrink();
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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
    final color = _color(status);
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
            width: 90,
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

// ── Full-screen image viewer ──────────────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullScreenImageViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Prev arrow
          if (_current > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

          // Next arrow
          if (_current < widget.urls.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _ctrl.nextPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

          // Page indicator
          if (widget.urls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Colors.white
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _StatusTimeline extends StatelessWidget {
  final List<ReportStatus> history;
  const _StatusTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    final allStatuses = AppConstants.reportStatuses;

    return Column(
      children: allStatuses.asMap().entries.map((entry) {
        final index = entry.key;
        final statusName = entry.value;
        final historyEntry = history
            .where((h) => h.status == statusName)
            .firstOrNull;
        final isCompleted = historyEntry != null;
        final isLast = index == allStatuses.length - 1;

        Color color;
        switch (statusName) {
          case 'Assigned':
            color = const Color(0xFFF59E0B);
            break;
          case 'In Progress':
            color = const Color(0xFF3B82F6);
            break;
          case 'Done':
            color = const Color(0xFF8B5CF6);
            break;
          case 'Needs Revision':
            color = const Color(0xFFDC2626);
            break;
          case 'Resolved':
            color = const Color(0xFF10B981);
            break;
          case 'Rejected':
            color = const Color(0xFFEF4444);
            break;
          default:
            color = const Color(0xFF9CA3AF);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted ? color : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? color : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      color: isCompleted
                          ? color.withValues(alpha: 0.3)
                          : Colors.grey[200],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCompleted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCompleted ? color : Colors.grey[400],
                      ),
                    ),
                    if (historyEntry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM d, yyyy · h:mm a',
                        ).format(historyEntry.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (historyEntry.updatedBy != null &&
                          historyEntry.updatedBy!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          'by ${historyEntry.updatedBy}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
