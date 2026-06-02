import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_shell.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  final ReportService _service = ReportService();
  String _filter = 'All';
  String _search = '';
  late TabController _tabController;

  static const _filters = ['All', 'New', 'In Progress', 'Completed', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    var list = reports;
    if (_filter != 'All') {
      list = list.where((r) {
        if (_filter == 'New')
          return r.currentStatus == AppConstants.statusSubmitted;
        if (_filter == 'Overdue') return r.currentStatus == 'Overdue';
        return r.currentStatus == _filter;
      }).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (r) =>
                r.category.toLowerCase().contains(q) ||
                r.barangay.toLowerCase().contains(q) ||
                r.userFullName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  Future<void> _showConfirmDialog(
    ReportModel report,
    String newStatus,
    String actionLabel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${actionLabel.toLowerCase()} this report?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Report #${report.id.substring(0, 6).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _InfoRow('Category', report.category),
                  _InfoRow('Location', 'Brgy. ${report.barangay}'),
                  _InfoRow('Reporter', report.userFullName),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == AppConstants.statusRejected
                  ? AppTheme.primaryRed
                  : AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(report, newStatus);
    }
  }

  Future<void> _updateStatus(ReportModel report, String newStatus) async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final adminName = auth.user?.fullName ?? 'Admin';

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Updating status...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _service.updateStatus(
        reportId: report.id,
        newStatus: newStatus,
        updatedBy: adminName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report marked as $newStatus'),
            backgroundColor: newStatus == AppConstants.statusRejected
                ? AppTheme.primaryRed
                : AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _showStatusDialog(ReportModel report) {
    final auth = context.read<AuthProvider>();
    final adminName = auth.user?.fullName ?? 'Admin';
    String? selectedStatus;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'New Status'),
                items: AppConstants.reportStatuses
                    .where((s) => s != report.currentStatus)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => selectedStatus = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            AdminHoverButton(
              label: 'Cancel',
              onTap: () {
                if (Navigator.canPop(ctx)) {
                  Navigator.pop(ctx);
                }
              },
              outlined: true,
              small: true,
            ),
            const SizedBox(width: 8),
            AdminHoverButton(
              label: 'Update',
              onTap: selectedStatus == null
                  ? null
                  : () async {
                      final status = selectedStatus!;
                      final note = noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim();
                      if (Navigator.canPop(ctx)) {
                        Navigator.pop(ctx);
                      }

                      if (!mounted) return;

                      try {
                        await _service.updateStatus(
                          reportId: report.id,
                          newStatus: status,
                          updatedBy: adminName,
                          note: note,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to $status'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update status'),
                              backgroundColor: AppTheme.primaryRed,
                            ),
                          );
                        }
                      }
                    },
              color: AppTheme.primaryBlue,
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/reports',
      child: Column(
        children: [
          const AdminPageHeader(
            title: 'Reports',
            subtitle: 'Municipality of Pila, Laguna',
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Manage Reports'),
                Tab(text: 'Community View'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildManageReportsTab(), _buildCommunityViewTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageReportsTab() {
    return StreamBuilder<List<ReportModel>>(
      stream: _service.getAllReports(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _applyFilter(all);

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  ..._filters.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: f,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    height: 36,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search reports...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: const Row(
                children: [
                  SizedBox(width: 80, child: Text('ID', style: _hStyle)),
                  SizedBox(width: 180, child: Text('ISSUE', style: _hStyle)),
                  SizedBox(width: 120, child: Text('CATEGORY', style: _hStyle)),
                  SizedBox(width: 120, child: Text('BARANGAY', style: _hStyle)),
                  SizedBox(width: 90, child: Text('REPORTER', style: _hStyle)),
                  SizedBox(width: 100, child: Text('DATE', style: _hStyle)),
                  SizedBox(width: 110, child: Text('STATUS', style: _hStyle)),
                  Expanded(child: Text('ACTIONS', style: _hStyle)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No reports found.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _x) => const Divider(height: 1),
                      itemBuilder: (_, i) => _ReportRow(
                        report: filtered[i],
                        onView: () =>
                            context.push('/admin/reports/${filtered[i].id}'),
                        onValidate: () => _showConfirmDialog(
                          filtered[i],
                          AppConstants.statusValidated,
                          'Approve',
                        ),
                        onReject: () => _showConfirmDialog(
                          filtered[i],
                          AppConstants.statusRejected,
                          'Reject',
                        ),
                        onStatusChange: () => _showStatusDialog(filtered[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunityViewTab() {
    return StreamBuilder<List<ReportModel>>(
      stream: _service.getAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No community reports yet',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _CommunityReportCard(
              report: report,
              onTap: () => context.push('/admin/reports/${report.id}'),
            );
          },
        );
      },
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppTheme.textMuted,
  letterSpacing: 0.5,
);

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.textDark : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.textDark,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onView, onValidate, onReject, onStatusChange;
  const _ReportRow({
    required this.report,
    required this.onView,
    required this.onValidate,
    required this.onReject,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final date = DateFormat('MMM d, y').format(report.createdAt);
    final time = DateFormat('h:mm a').format(report.createdAt);
    final id = '#RPT-${report.id.substring(0, 4).toUpperCase()}';
    final isNew = report.currentStatus == AppConstants.statusSubmitted;

    return AdminTableRow(
      onTap: onView,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                id,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
            SizedBox(
              width: 180,
              child: Text(
                report.category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.category,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                'Brgy. ${report.barangay}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                report.userFullName.split(' ').first,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.currentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _Btn(label: 'View', onTap: onView, outlined: true),
                  const SizedBox(width: 4),
                  if (isNew) ...[
                    _Btn(
                      label: 'Validate',
                      onTap: onValidate,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 4),
                    _Btn(
                      label: 'Reject',
                      onTap: onReject,
                      color: AppTheme.primaryRed,
                    ),
                  ] else
                    _Btn(
                      label: 'Update',
                      onTap: onStatusChange,
                      color: AppTheme.primaryBlue,
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

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;
  const _Btn({
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminHoverButton(
      label: label,
      onTap: onTap,
      color: color ?? AppTheme.textDark,
      outlined: outlined,
      small: true,
    );
  }
}

class _CommunityReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _CommunityReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final priorityLabel = _getPriorityLabel(report.priority);
    final priorityColor = _getPriorityColor(report.priority);

    return AdminHoverCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview (if available)
          if (report.photoUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                report.photoUrls.first,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 140,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.report_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (report.priority > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.description.length > 60
                        ? '${report.description.substring(0, 60)}...'
                        : report.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Brgy. ${report.barangay}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            report.currentStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (report.followerCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.people_outline,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${report.followerCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
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
