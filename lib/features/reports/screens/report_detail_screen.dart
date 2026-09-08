import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/mobile_shell.dart';
import '../providers/report_provider.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

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

  Future<void> _deleteReport(
    BuildContext context,
    String reportId,
    String userId,
  ) async {
    final result = await ReportService().deleteReport(
      reportId: reportId,
      userId: userId,
    );

    if (context.mounted) {
      if (result['success'] == true) {
        AppToast.show(
          context,
          'Report deleted successfully',
          type: ToastType.success,
        );
        Navigator.pop(context); // Go back to reports list
      } else {
        AppToast.show(
          context,
          result['error'] ?? 'Failed to delete report',
          type: ToastType.error,
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    ReportModel report,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.coral),
            const SizedBox(width: 8),
            const Text('Delete Report?'),
          ],
        ),
        content: Text(
          report.currentStatus == AppConstants.statusResolved
              ? 'This resolved report will be removed from your list. This action cannot be undone.'
              : 'Are you sure you want to delete this report? You can only delete pending reports.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteReport(context, report.id, userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFollowUpDialog(
    BuildContext context,
    ReportModel report,
    String userId,
    String userName,
  ) {
    final msgCtrl = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                color: Colors.orange[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Follow Up',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a message to the admin about this ${report.category} concern.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'e.g. "Still not fixed after 2 weeks..."',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: sending
                  ? null
                  : () async {
                      if (msgCtrl.text.trim().isEmpty) return;
                      setDialog(() => sending = true);
                      await ReportService().followUpOwnReport(
                        reportId: report.id,
                        userId: userId,
                        userFullName: userName,
                        message: msgCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          'Follow-up sent to admin!',
                          type: ToastType.success,
                        );
                      }
                    },
              icon: sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
    final provider = context.read<ReportProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.uid;

    return MobileShell(
      title: 'Report Details',
      currentIndex: 1,
      showBack: true,
      child: StreamBuilder<ReportModel?>(
        stream: provider.getReport(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('Report not found.'));
          }

          final isFollowing =
              currentUserId != null && report.followers.contains(currentUserId);
          final isOwnReport = currentUserId == report.userId;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportStatusBanner(status: report.currentStatus),
                const SizedBox(height: 16),

                // Follow Up button (not for own reports, only on active reports)
                if (!isOwnReport &&
                    currentUserId != null &&
                    report.currentStatus != AppConstants.statusResolved &&
                    report.currentStatus != AppConstants.statusRejected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (isFollowing) {
                          await ReportService().unfollowReport(
                            reportId,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppToast.show(
                              context,
                              'You stopped following up on this report',
                              type: ToastType.info,
                            );
                          }
                        } else {
                          await ReportService().followReport(
                            reportId,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppToast.show(
                              context,
                              'You are now following up on this report',
                              type: ToastType.success,
                            );
                          }
                        }
                      },
                      icon: Icon(
                        isFollowing
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                      ),
                      label: Text(
                        isFollowing
                            ? 'Following Up (${report.followerCount})'
                            : 'Follow Up Report',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFollowing
                            ? AppTheme.primaryBlue
                            : AppTheme.textDark,
                        side: BorderSide(
                          color: isFollowing
                              ? AppTheme.primaryBlue
                              : AppTheme.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Delete button for own reports (only for Pending or Completed)
                if (isOwnReport &&
                    currentUserId != null &&
                    (report.currentStatus == AppConstants.statusPending ||
                        report.currentStatus ==
                            AppConstants.statusResolved)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showDeleteDialog(context, report, currentUserId),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        report.currentStatus == AppConstants.statusResolved
                            ? 'Remove Resolved Report'
                            : 'Delete Report',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.coral,
                        side: const BorderSide(color: AppTheme.coral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Follow Up button — for own active reports to signal urgency to admin
                if (isOwnReport &&
                    currentUserId != null &&
                    report.currentStatus != AppConstants.statusResolved &&
                    report.currentStatus != AppConstants.statusRejected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showFollowUpDialog(
                        context,
                        report,
                        currentUserId,
                        auth.user?.fullName ?? 'Resident',
                      ),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Follow Up / Nudge Admin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[700]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (report.followerCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${report.followerCount} ${report.followerCount == 1 ? 'person is' : 'people are'} following this report',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                if (report.afterPhotoUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
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
                              'Issue Resolved!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                        if (report.completedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Completed on ${DateFormat('MMM d, yyyy').format(report.completedAt!)}',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen,
                                      borderRadius: BorderRadius.circular(4),
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
                                        borderRadius: BorderRadius.circular(8),
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
                            report.completionRemarks!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'What was done',
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
                              : report.userFullName,
                        ),
                        ReportDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Submitted',
                          value: DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(report.createdAt),
                        ),
                        if (report.assignedTo != null)
                          ReportDetailRow(
                            icon: Icons.engineering_outlined,
                            label: 'Assigned to',
                            value: report.assignedTo!,
                          ),
                        const Divider(height: 20),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.description,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Department progress updates
                if (report.assignedDepartment != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          size: 16,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Handled by: ${report.assignedDepartment}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (report.progressUpdates.isNotEmpty) ...[
                  const Text(
                    'Department Progress Updates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ...([...report.progressUpdates]
                        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)))
                      .map((u) => _ResidentProgressEntry(update: u)),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Transparency Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                ReportTimeline(history: report.statusHistory),

                // ── Feedback section (resolved reports only) ──────────
                if (report.currentStatus == AppConstants.statusResolved &&
                    currentUserId != null) ...[
                  const SizedBox(height: 28),
                  _FeedbackSection(
                    reportId: reportId,
                    currentUserId: currentUserId,
                    currentUserName: auth.user?.fullName ?? 'Resident',
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Shared widgets used by both citizen and admin detail screens

class _ResidentProgressEntry extends StatelessWidget {
  final ProgressUpdate update;
  const _ResidentProgressEntry({required this.update});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  update.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, h:mm a').format(update.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
          if (update.remarks != null) ...[
            const SizedBox(height: 6),
            Text(update.remarks!, style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text(
            'by ${update.department}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          // Note: dept completion photos are not shown here — only shown
          // after admin approves as the official "after" photo
        ],
      ),
    );
  }
}

// ── Feedback section widget ───────────────────────────────────────────────────

class _FeedbackSection extends StatefulWidget {
  final String reportId;
  final String currentUserId;
  final String currentUserName;

  const _FeedbackSection({
    required this.reportId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<_FeedbackSection> {
  final _service = ReportService();
  final _commentCtrl = TextEditingController();
  int _selectedRating = 0;
  bool _submitting = false;
  bool _showForm = false;
  ReportFeedback? _myFeedback;
  bool _loadedMine = false;

  @override
  void initState() {
    super.initState();
    _loadMyFeedback();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyFeedback() async {
    final f = await _service.getUserFeedback(
      widget.reportId,
      widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _myFeedback = f;
        _loadedMine = true;
        if (f != null) {
          _selectedRating = f.rating;
          _commentCtrl.text = f.comment;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      AppToast.show(context, 'Please select a rating', type: ToastType.warning);
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      AppToast.show(context, 'Please write a comment', type: ToastType.warning);
      return;
    }
    setState(() => _submitting = true);
    await _service.submitFeedback(
      reportId: widget.reportId,
      userId: widget.currentUserId,
      userFullName: widget.currentUserName,
      rating: _selectedRating,
      comment: _commentCtrl.text.trim(),
    );
    await _loadMyFeedback();
    if (mounted) {
      setState(() {
        _submitting = false;
        _showForm = false;
      });
      AppToast.show(context, 'Feedback submitted', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Community Feedback',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            if (_loadedMine && !_showForm)
              TextButton.icon(
                onPressed: () => setState(() => _showForm = true),
                icon: Icon(
                  _myFeedback == null ? Icons.add : Icons.edit_outlined,
                  size: 14,
                ),
                label: Text(
                  _myFeedback == null ? 'Leave feedback' : 'Edit',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Feedback form
        if (_showForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How satisfied are you with the resolution?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          star <= _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 34,
                          color: star <= _selectedRating
                              ? const Color(0xFFFBBF24)
                              : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _showForm = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 13),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Feedback list
        StreamBuilder<List<ReportFeedback>>(
          stream: _service.getFeedback(widget.reportId),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'No feedback yet. Be the first to share!',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              );
            }
            final avg =
                list.map((f) => f.rating).reduce((a, b) => a + b) / list.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                (i + 1) <= avg.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 16,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
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
                  (f) => _FeedbackCard(
                    feedback: f,
                    isOwn: f.userId == widget.currentUserId,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final ReportFeedback feedback;
  final bool isOwn;
  const _FeedbackCard({required this.feedback, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwn
            ? AppTheme.primaryBlue.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOwn
              ? AppTheme.primaryBlue.withValues(alpha: 0.2)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  feedback.userFullName.isNotEmpty
                      ? feedback.userFullName[0].toUpperCase()
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
                    Row(
                      children: [
                        Text(
                          isOwn ? 'You' : feedback.userFullName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'you',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('MMM d, y').format(feedback.createdAt),
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
                    (i + 1) <= feedback.rating
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
            feedback.comment,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}

// Shared widgets used by both citizen and admin detail screens

class ReportStatusBanner extends StatelessWidget {
  final String status;

  const ReportStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(AppTheme.statusIcon(status), color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ReportDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportTimeline extends StatelessWidget {
  final List<ReportStatus> history;

  const ReportTimeline({super.key, required this.history});

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
        final color = isCompleted
            ? AppTheme.statusColor(statusName)
            : Colors.grey[300]!;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? color : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    AppTheme.statusIcon(statusName),
                    size: 16,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? color.withAlpha(100)
                        : Colors.grey[200],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isCompleted ? AppTheme.textDark : Colors.grey,
                      ),
                    ),
                    if (historyEntry != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d, yyyy h:mm a',
                        ).format(historyEntry.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (historyEntry.updatedBy != null &&
                          historyEntry.updatedBy!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'by ${historyEntry.updatedBy}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (historyEntry.note != null &&
                          historyEntry.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  historyEntry.note!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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
