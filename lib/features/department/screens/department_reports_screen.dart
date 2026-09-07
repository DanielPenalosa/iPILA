import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/department_service.dart';
import '../../auth/providers/auth_provider.dart';

class DepartmentReportsScreen extends StatefulWidget {
  const DepartmentReportsScreen({super.key});

  @override
  State<DepartmentReportsScreen> createState() =>
      _DepartmentReportsScreenState();
}

class _DepartmentReportsScreenState extends State<DepartmentReportsScreen> {
  String _filter = 'All';
  final _filters = [
    'All',
    'Assigned',
    'In Progress',
    'For Admin Verification',
    'Revision Required',
  ];

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    if (_filter == 'All') return reports;
    return reports.where((r) => r.currentStatus == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.department ?? 'Department Portal',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            Text(
              'Municipality of Pila, Laguna',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: DepartmentService().getDepartmentReports(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);

          final pending = all
              .where(
                (r) =>
                    r.currentStatus == AppConstants.statusAssigned ||
                    r.currentStatus == AppConstants.statusRevisionRequired,
              )
              .length;
          final inProgress = all
              .where((r) => r.currentStatus == AppConstants.statusInProgress)
              .length;
          final forVerification = all
              .where(
                (r) => r.currentStatus == AppConstants.statusForVerification,
              )
              .length;

          return Column(
            children: [
              // Stats row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${all.length}',
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Action Required',
                      value: '$pending',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'In Progress',
                      value: '$inProgress',
                      color: const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'For Verification',
                      value: '$forVerification',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              // Filter chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primaryBlue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 56,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reports',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ReportTile(report: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final ReportModel report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.currentStatus);
    final needsAction =
        report.currentStatus == AppConstants.statusAssigned ||
        report.currentStatus == AppConstants.statusRevisionRequired;

    return GestureDetector(
      onTap: () => context.push('/department/report/${report.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: needsAction
              ? Border.all(color: Colors.orange, width: 1.5)
              : Border.all(color: Colors.transparent),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 6),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Brgy. ${report.barangay}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(report.updatedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            if (report.currentStatus == AppConstants.statusRevisionRequired &&
                report.adminVerificationRemarks != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Admin remarks: ${report.adminVerificationRemarks}',
                        style: TextStyle(fontSize: 11, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
