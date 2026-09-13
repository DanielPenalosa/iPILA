import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../home/widgets/mobile_shell.dart';
import '../widgets/community_post_modal.dart';

class CommunityReportsScreen extends StatefulWidget {
  const CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() => _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen> {
  String? _categoryFilter;
  String? _statusFilter;
  String? _barangayFilter;

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Community Reports',
      currentIndex: 3,
      showBack: false,
      child: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: _categoryFilter ?? 'Category',
                        onTap: () => _showCategoryFilter(),
                        isActive: _categoryFilter != null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: _statusFilter ?? 'Status',
                        onTap: () => _showStatusFilter(),
                        isActive: _statusFilter != null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: _barangayFilter ?? 'Barangay',
                        onTap: () => _showBarangayFilter(),
                        isActive: _barangayFilter != null,
                      ),
                    ),
                  ],
                ),
                if (_categoryFilter != null ||
                    _statusFilter != null ||
                    _barangayFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _categoryFilter = null;
                        _statusFilter = null;
                        _barangayFilter = null;
                      }),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Filters'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Reports list
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: ReportService().getCommunityReports(
                categoryFilter: _categoryFilter,
                statusFilter: _statusFilter,
                barangayFilter: _barangayFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _categoryFilter != null ||
                                _statusFilter != null ||
                                _barangayFilter != null
                            ? 'No reports match your filters'
                            : 'No community reports yet',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _CommunityReportCard(
                      report: report,
                      onTap: () => showCommunityPostModal(
                        context,
                        report,
                        isAdmin: false,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppConstants.issueCategories
                      .map(
                        (category) => ListTile(
                          title: Text(category),
                          trailing: _categoryFilter == category
                              ? const Icon(Icons.check, color: AppTheme.primaryBlue)
                              : null,
                          onTap: () {
                            setState(() => _categoryFilter = category);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppConstants.reportStatuses
                      .map(
                        (status) => ListTile(
                          title: Text(status),
                          trailing: _statusFilter == status
                              ? const Icon(Icons.check, color: AppTheme.primaryBlue)
                              : null,
                          onTap: () {
                            setState(() => _statusFilter = status);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBarangayFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter by Barangay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: AppConstants.barangays
                    .map(
                      (barangay) => ListTile(
                        title: Text(barangay),
                        trailing: _barangayFilter == barangay
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.primaryBlue,
                              )
                            : null,
                        onTap: () {
                          setState(() => _barangayFilter = barangay);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppTheme.primaryBlue : AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _CommunityReportCard({required this.report, required this.onTap});

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'Moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
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
            // ── top bar: avatar + name + category ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppTheme.primaryBlue.withValues(alpha: 0.12),
                    child: Text(
                      report.isAnonymous
                          ? '?'
                          : report.userFullName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.isAnonymous
                              ? 'Anonymous'
                              : report.userFullName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111)),
                        ),
                        Text(
                          'Brgy. ${report.barangay} · ${timeago.format(report.createdAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  // status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(report.currentStatus,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── photo ───────────────────────────────────────────────────
            if (report.photoUrls.isNotEmpty)
              Image.network(
                report.photoUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.broken_image_outlined,
                      size: 40, color: Color(0xFFD1D5DB)),
                ),
              ),

            // ── action row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 22, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${report.heartCount}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 20, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${report.commentCount}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.notifications_none_outlined,
                      size: 20, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${report.followerCount}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (report.urgencyLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _urgencyColor(report.urgencyLevel)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.urgencyLevel!,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _urgencyColor(report.urgencyLevel)),
                      ),
                    ),
                ],
              ),
            ),

            // ── description ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${report.category}  ',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111)),
                    ),
                    TextSpan(
                      text: report.description.length > 90
                          ? '${report.description.substring(0, 90)}...'
                          : report.description,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
            ),

            // ── "view all comments" hint ────────────────────────────────
            if (report.commentCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                child: Text(
                  'View all ${report.commentCount} comments',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
