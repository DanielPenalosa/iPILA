import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  // Bulk selection state
  bool _selectionMode = false;
  final Set<String> _selectedReportIds = {};

  // Status update state
  File? _afterPhoto;
  XFile? _afterPhotoWeb;

  // Date range filter state
  DateTimeRange? _dateRange;
  String _dateRangeLabel = 'All Time';
  final GlobalKey _dateButtonKey = GlobalKey();
  OverlayEntry? _calendarOverlay;

  static const _filters = ['All', 'New', 'In Progress', 'Completed', 'Overdue'];
  bool _sortByPriority = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _calendarOverlay?.remove();
    super.dispose();
  }

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    var list = reports;

    // Apply status filter
    if (_filter != 'All') {
      list = list.where((r) {
        if (_filter == 'New')
          return r.currentStatus == AppConstants.statusPending;
        if (_filter == 'Overdue') return r.currentStatus == 'Overdue';
        return r.currentStatus == _filter;
      }).toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      list = list.where((r) {
        final reportDate = r.createdAt;
        return reportDate.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            reportDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply search filter
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

    // Sort by priority descending if toggled
    if (_sortByPriority) {
      list.sort((a, b) {
        final pc = b.priority.compareTo(a.priority);
        return pc != 0 ? pc : b.createdAt.compareTo(a.createdAt);
      });
    }

    return list;
  }

  void _showDateRangePicker() {
    if (_calendarOverlay != null) {
      _hideDateRangePicker();
      return;
    }

    final renderBox =
        _dateButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _calendarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDateRangePicker,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            right:
                (MediaQuery.of(context).size.width - position.dx - size.width)
                    .clamp(8.0, MediaQuery.of(context).size.width - 328),
            top: position.dy + size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: _DateRangeCalendar(
                initialRange: _dateRange,
                onRangeSelected: (range) {
                  setState(() {
                    _dateRange = range;
                    _dateRangeLabel = range == null
                        ? 'All Time'
                        : '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d, y').format(range.end)}';
                  });
                  _hideDateRangePicker();
                },
                onClear: () {
                  setState(() {
                    _dateRange = null;
                    _dateRangeLabel = 'All Time';
                  });
                  _hideDateRangePicker();
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_calendarOverlay!);
  }

  void _hideDateRangePicker() {
    _calendarOverlay?.remove();
    _calendarOverlay = null;
  }

  void _applyQuickRange(String range) {
    final now = DateTime.now();
    DateTimeRange dateRange;

    switch (range) {
      case 'Today':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
        break;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        dateRange = DateTimeRange(
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: now,
        );
        break;
      case 'This Month':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
        break;
      case 'Last 30 Days':
        dateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      default:
        return;
    }

    setState(() {
      _dateRange = dateRange;
      _dateRangeLabel = range;
    });
    _hideDateRangePicker();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK SELECTION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleSelection(String reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
        if (_selectedReportIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedReportIds.add(reportId);
        _selectionMode = true;
      }
    });
  }

  void _selectAll(List<ReportModel> reports) {
    setState(() {
      _selectedReportIds.addAll(reports.map((r) => r.id));
      _selectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedReportIds.clear();
      _selectionMode = false;
    });
  }

  Future<void> _bulkChangeStatus(String newStatus) async {
    if (_selectedReportIds.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Status for ${_selectedReportIds.length} Reports'),
        content: Text('Set status to "$newStatus" for all selected reports?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.bulkUpdateStatus(
        reportIds: _selectedReportIds.toList(),
        newStatus: newStatus,
        adminEmail: auth.user?.email ?? '',
      );

      _clearSelection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Updated ${_selectedReportIds.length} reports'),
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
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedReportIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedReportIds.length} Reports'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.bulkDeleteReports(_selectedReportIds.toList());
      _clearSelection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Reports deleted'),
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
    }
  }

  Future<void> _deleteReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permanently delete this report? This action cannot be undone.',
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.bulkDeleteReports([report.id]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Report deleted'),
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
    }
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

  Future<void> _pickAfterPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null && mounted) {
      setState(() {
        _afterPhotoWeb = picked;
        if (!kIsWeb) {
          _afterPhoto = File(picked.path);
        }
      });
    }
  }

  void _showStatusDialog(ReportModel report) {
    final auth = context.read<AuthProvider>();
    final adminName = auth.user?.fullName ?? 'Admin';
    String? selectedStatus;
    final noteCtrl = TextEditingController();

    // Reset photo state
    _afterPhoto = null;
    _afterPhotoWeb = null;

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
                controller: noteCtrl,
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
                    : () async {
                        final status = selectedStatus!;
                        final note = noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim();

                        if (Navigator.canPop(ctx)) {
                          Navigator.pop(ctx);
                        }

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Updating status...'),
                              ],
                            ),
                            duration: Duration(seconds: 30),
                          ),
                        );

                        try {
                          final result = await _service.updateStatus(
                            reportId: report.id,
                            newStatus: status,
                            updatedBy: adminName,
                            note: note,
                            afterPhoto: status == AppConstants.statusResolved
                                ? _afterPhoto
                                : null,
                            afterPhotoWeb: status == AppConstants.statusResolved
                                ? _afterPhotoWeb
                                : null,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            if (result['success'] == true) {
                              _afterPhoto = null;
                              _afterPhotoWeb = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Status updated to $status'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['error'] ?? 'Failed to update',
                                  ),
                                  backgroundColor: AppTheme.primaryRed,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.primaryRed,
                              ),
                            );
                          }
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
                  // Date range filter button
                  InkWell(
                    key: _dateButtonKey,
                    onTap: _showDateRangePicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateRange != null
                              ? AppTheme.primaryBlue
                              : const Color(0xFFE0E0E0),
                          width: _dateRange != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _dateRange != null
                            ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                            : Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: _dateRange != null
                                ? AppTheme.primaryBlue
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dateRangeLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _dateRange != null
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _dateRange != null
                                  ? AppTheme.primaryBlue
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: _dateRange != null
                                ? AppTheme.primaryBlue
                                : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _dateRange = null;
                          _dateRangeLabel = 'All Time';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.clear,
                          size: 16,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 8),
                  // Priority sort toggle
                  Tooltip(
                    message: _sortByPriority
                        ? 'Sorting by priority'
                        : 'Sort by priority',
                    child: InkWell(
                      onTap: () =>
                          setState(() => _sortByPriority = !_sortByPriority),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _sortByPriority
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _sortByPriority
                                ? Colors.red.withValues(alpha: 0.5)
                                : const Color(0xFFE0E0E0),
                            width: _sortByPriority ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 15,
                              color: _sortByPriority
                                  ? Colors.red[700]
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _sortByPriority
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _sortByPriority
                                    ? Colors.red[700]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Bulk action bar ──────────────────────────────────
            if (_selectionMode)
              Container(
                color: const Color(0xFFF0F4FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedReportIds.length} selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _BulkBtn(
                      label: 'Approve',
                      color: AppTheme.successGreen,
                      onTap: () =>
                          _bulkChangeStatus(AppConstants.statusUnderReview),
                    ),
                    const SizedBox(width: 8),
                    _BulkBtn(
                      label: 'In Progress',
                      color: const Color(0xFF1565C0),
                      onTap: () =>
                          _bulkChangeStatus(AppConstants.statusInProgress),
                    ),
                    const SizedBox(width: 8),
                    _BulkBtn(
                      label: 'Resolve',
                      color: const Color(0xFF059669),
                      onTap: () =>
                          _bulkChangeStatus(AppConstants.statusResolved),
                    ),
                    const SizedBox(width: 8),
                    _BulkBtn(
                      label: 'Reject',
                      color: Colors.orange,
                      onTap: () =>
                          _bulkChangeStatus(AppConstants.statusRejected),
                    ),
                    const SizedBox(width: 8),
                    _BulkBtn(
                      label: 'Delete',
                      color: AppTheme.primaryRed,
                      onTap: _bulkDelete,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearSelection,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Column header row ─────────────────────────────────
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Checkbox(
                      value:
                          filtered.isNotEmpty &&
                          _selectedReportIds.containsAll(
                            filtered.map((r) => r.id),
                          ),
                      tristate: true,
                      onChanged: (_) {
                        final allSelected = _selectedReportIds.containsAll(
                          filtered.map((r) => r.id),
                        );
                        allSelected ? _clearSelection() : _selectAll(filtered);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 80, child: Text('ID', style: _hStyle)),
                  const SizedBox(
                    width: 180,
                    child: Text('ISSUE', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 120,
                    child: Text('CATEGORY', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 120,
                    child: Text('BARANGAY', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text('REPORTER', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Text('DATE', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 110,
                    child: Text('STATUS', style: _hStyle),
                  ),
                  const Expanded(child: Text('ACTIONS', style: _hStyle)),
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
                        isSelected: _selectedReportIds.contains(filtered[i].id),
                        onToggleSelect: () => _toggleSelection(filtered[i].id),
                        onView: () =>
                            context.push('/admin/reports/${filtered[i].id}'),
                        onValidate: () => _showConfirmDialog(
                          filtered[i],
                          AppConstants.statusUnderReview,
                          'Review',
                        ),
                        onReject: () => _showConfirmDialog(
                          filtered[i],
                          AppConstants.statusRejected,
                          'Reject',
                        ),
                        onStatusChange: () => _showStatusDialog(filtered[i]),
                        onDelete: () => _deleteReport(filtered[i]),
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
          padding: const EdgeInsets.all(40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 32,
            mainAxisSpacing: 32,
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
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onView, onValidate, onReject, onStatusChange, onDelete;
  const _ReportRow({
    required this.report,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onView,
    required this.onValidate,
    required this.onReject,
    required this.onStatusChange,
    required this.onDelete,
  });

  static Color _priorityColor(int p) {
    if (p >= 5) return Colors.red[700]!;
    if (p >= 4) return Colors.orange[700]!;
    if (p >= 3) return Colors.amber[700]!;
    if (p >= 2) return Colors.blue[600]!;
    return Colors.grey[400]!;
  }

  static String _priorityLabel(int p) {
    if (p >= 5) return 'CRITICAL';
    if (p >= 4) return 'HIGH';
    if (p >= 3) return 'MEDIUM';
    if (p >= 2) return 'LOW';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final date = DateFormat('MMM d, y').format(report.createdAt);
    final time = DateFormat('h:mm a').format(report.createdAt);
    final id = '#RPT-${report.id.substring(0, 4).toUpperCase()}';
    final isNew = report.currentStatus == AppConstants.statusPending;
    final hasPriority = report.priority >= 2;

    return AdminTableRow(
      onTap: onView,
      child: Container(
        color: isSelected
            ? const Color(0xFFF0F4FF)
            : (report.priority >= 4
                  ? Colors.red.withValues(alpha: 0.02)
                  : Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (hasPriority)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _priorityColor(
                          report.priority,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 9,
                            color: _priorityColor(report.priority),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _priorityLabel(report.priority),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _priorityColor(report.priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                      label: 'Review',
                      onTap: onValidate,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 4),
                    _Btn(
                      label: 'Reject',
                      onTap: onReject,
                      color: AppTheme.primaryRed,
                    ),
                  ] else if (report.currentStatus !=
                      AppConstants.statusResolved)
                    _Btn(
                      label: 'Update',
                      onTap: onStatusChange,
                      color: AppTheme.primaryBlue,
                    ),
                  if (!isNew) ...[
                    const SizedBox(width: 4),
                    _Btn(
                      label: 'Delete',
                      onTap: onDelete,
                      color: AppTheme.primaryRed,
                    ),
                  ],
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

class _BulkBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BulkBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.report_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
            ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
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

class _DateRangeCalendar extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange?) onRangeSelected;
  final VoidCallback onClear;

  const _DateRangeCalendar({
    required this.initialRange,
    required this.onRangeSelected,
    required this.onClear,
  });

  @override
  State<_DateRangeCalendar> createState() => _DateRangeCalendarState();
}

class _DateRangeCalendarState extends State<_DateRangeCalendar> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // null = calendar, 'month' = month picker, 'year' = year picker
  String? _pickerMode;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
    if (_rangeStart != null) {
      _focusedMonth = DateTime(_rangeStart!.year, _rangeStart!.month, 1);
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = date;
        _rangeEnd = null;
      } else if (date.isBefore(_rangeStart!)) {
        _rangeEnd = _rangeStart;
        _rangeStart = date;
      } else {
        _rangeEnd = date;
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _applySelection() {
    if (_rangeStart != null && _rangeEnd != null) {
      widget.onRangeSelected(
        DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
      );
    }
  }

  Widget _buildMonthPicker() {
    return SizedBox(
      height: 220,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 12,
        itemBuilder: (_, i) {
          final isCurrent = i + 1 == _focusedMonth.month;
          final isFuture = DateTime(
            _focusedMonth.year,
            i + 1,
          ).isAfter(DateTime.now());
          return GestureDetector(
            onTap: isFuture
                ? null
                : () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, i + 1, 1);
                      _pickerMode = null;
                    });
                  },
            child: Container(
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppTheme.primaryBlue : Colors.grey[300]!,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _months[i].substring(0, 3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isFuture
                      ? Colors.grey[300]
                      : isCurrent
                      ? Colors.white
                      : AppTheme.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 2019, (i) => currentYear - i);
    return SizedBox(
      height: 220,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: years.length,
        itemBuilder: (_, i) {
          final year = years[i];
          final isCurrent = year == _focusedMonth.year;
          return GestureDetector(
            onTap: () {
              setState(() {
                _focusedMonth = DateTime(year, _focusedMonth.month, 1);
                _pickerMode = null;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppTheme.primaryBlue : Colors.grey[300]!,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$year',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isCurrent ? Colors.white : AppTheme.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with tappable month and year
          Row(
            children: [
              if (_pickerMode == null)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_pickerMode != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => setState(() => _pickerMode = null),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                        () => _pickerMode = _pickerMode == 'month'
                            ? null
                            : 'month',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _pickerMode == 'month'
                              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMMM').format(_focusedMonth),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () =>
                            _pickerMode = _pickerMode == 'year' ? null : 'year',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _pickerMode == 'year'
                              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_focusedMonth.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_pickerMode == null)
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _focusedMonth.year < DateTime.now().year ||
                          (_focusedMonth.year == DateTime.now().year &&
                              _focusedMonth.month < DateTime.now().month)
                      ? _nextMonth
                      : null,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_pickerMode != null) const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 12),
          // Month or year picker overlay
          if (_pickerMode == 'month') _buildMonthPicker(),
          if (_pickerMode == 'year') _buildYearPicker(),
          if (_pickerMode != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.initialRange != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                if (widget.initialRange != null) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_rangeStart != null && _rangeEnd != null)
                        ? _applySelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
          if (_pickerMode == null) ...[
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            ...List.generate(6, (weekIndex) {
              final weekWidgets = List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 40, height: 32);
                }

                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayNumber,
                );
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                final isSelected =
                    (_rangeStart != null &&
                        DateUtils.isSameDay(date, _rangeStart!)) ||
                    (_rangeEnd != null &&
                        DateUtils.isSameDay(date, _rangeEnd!));
                final isInRange =
                    _rangeStart != null &&
                    _rangeEnd != null &&
                    date.isAfter(_rangeStart!) &&
                    date.isBefore(_rangeEnd!);
                final isFuture = date.isAfter(DateTime.now());

                return GestureDetector(
                  onTap: isFuture ? null : () => _selectDate(date),
                  child: Container(
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : isInRange
                          ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryBlue, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isFuture
                            ? Colors.grey[300]
                            : isSelected
                            ? Colors.white
                            : isInRange
                            ? AppTheme.primaryBlue
                            : AppTheme.textDark,
                      ),
                    ),
                  ),
                );
              });

              // Only show row if it has at least one valid day
              final hasValidDay = weekWidgets.any(
                (widget) => widget is GestureDetector,
              );
              if (!hasValidDay) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekWidgets,
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.initialRange != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                if (widget.initialRange != null) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_rangeStart != null && _rangeEnd != null)
                        ? _applySelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ], // end if (_pickerMode == null)
        ],
      ),
    );
  }
}
