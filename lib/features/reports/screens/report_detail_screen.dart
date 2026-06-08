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

                // Follow/Unfollow button (not for own reports)
                if (!isOwnReport && currentUserId != null) ...[
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
                              'You unfollowed this report',
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
                              'You are now following this report',
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
                            ? 'Following (${report.followerCount})'
                            : 'Follow Report',
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

                // Follower count display
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
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        report.photoUrls.first,
                                        fit: BoxFit.contain,
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
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        report.afterPhotoUrl!,
                                        fit: BoxFit.contain,
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
                const Text(
                  'Transparency Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                ReportTimeline(history: report.statusHistory),
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
                        color: isCompleted ? AppTheme.textDark : Colors.grey,
                      ),
                    ),
                    if (historyEntry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM d, yyyy h:mm a',
                        ).format(historyEntry.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (historyEntry.note != null)
                        Text(
                          historyEntry.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
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
