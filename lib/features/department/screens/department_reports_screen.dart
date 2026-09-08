import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/report_export_service.dart';
import '../../../core/widgets/app_ui.dart';
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
  String _search = '';

  // Date range
  DateTimeRange? _dateRange;
  String _dateRangeLabel = 'All Time';
  final GlobalKey _dateButtonKey = GlobalKey();
  OverlayEntry? _calendarOverlay;

  // Row selection
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const _filters = [
    'All',
    'Assigned',
    'In Progress',
    'Done',
    'Needs Revision',
    'Resolved',
  ];

  @override
  void dispose() {
    _calendarOverlay?.remove();
    super.dispose();
  }

  List<ReportModel> _apply(List<ReportModel> all) {
    var list = _filter == 'All'
        ? all
        : all.where((r) => r.currentStatus == _filter).toList();

    if (_dateRange != null) {
      list = list.where((r) {
        final d = r.createdAt;
        return d.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (r) =>
                r.category.toLowerCase().contains(q) ||
                r.barangay.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q) ||
                r.userFullName.toLowerCase().contains(q),
          )
          .toList();
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
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDateRangePicker,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            right: (MediaQuery.of(ctx).size.width - position.dx - size.width)
                .clamp(8.0, MediaQuery.of(ctx).size.width - 328),
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

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
        _selectionMode = true;
      }
    });
  }

  void _selectAll(List<ReportModel> reports) {
    setState(() {
      _selectedIds.addAll(reports.map((r) => r.id));
      _selectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<ReportModel>>(
      stream: DepartmentService().getDepartmentReports(user.uid),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _apply(all);

        return Column(
          children: [
            // ── Toolbar ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  // Status filter chips
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

                  // Date range button
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
                      onTap: () => setState(() {
                        _dateRange = null;
                        _dateRangeLabel = 'All Time';
                      }),
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

                  // Search
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

                  // Export button
                  Tooltip(
                    message: 'Export reports',
                    child: InkWell(
                      onTap: () => ReportExportService.showExportDialog(
                        context,
                        filtered,
                        label: 'Export Department Reports',
                        filePrefix: 'dept_reports',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 16,
                              color: Color(0xFF374151),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
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

            // ── Bulk action bar ────────────────────────────────────
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
                      '${_selectedIds.length} selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _BulkBtn(
                      label: 'Export Selected',
                      color: const Color(0xFF10B981),
                      onTap: () => ReportExportService.showExportDialog(
                        context,
                        filtered
                            .where((r) => _selectedIds.contains(r.id))
                            .toList(),
                        label: 'Export Selected Reports',
                        filePrefix: 'dept_selected',
                      ),
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

            // ── Column header row ──────────────────────────────────
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
                          _selectedIds.containsAll(filtered.map((r) => r.id)),
                      tristate: true,
                      onChanged: (_) {
                        final allSelected = _selectedIds.containsAll(
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
                    child: Text('CATEGORY', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 140,
                    child: Text('BARANGAY', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 120,
                    child: Text('REPORTER', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 130,
                    child: Text('DATE', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 130,
                    child: Text('STATUS', style: _hStyle),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Text('URGENCY', style: _hStyle),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isNotEmpty
                                ? 'No results for "$_search"'
                                : _dateRange != null
                                ? 'No reports in selected date range.'
                                : 'No reports here.',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = filtered[i];
                        return _ReportRow(
                          report: r,
                          isSelected: _selectedIds.contains(r.id),
                          onToggleSelect: () => _toggleSelect(r.id),
                          onView: () =>
                              context.push('/department/reports/${r.id}'),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Const header style ────────────────────────────────────────────────────────

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppTheme.textMuted,
  letterSpacing: 0.5,
);

// ── Filter chip ───────────────────────────────────────────────────────────────

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

// ── Bulk btn ──────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Report row ────────────────────────────────────────────────────────────────

class _ReportRow extends StatelessWidget {
  final ReportModel report;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onView;

  const _ReportRow({
    required this.report,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onView,
  });

  Color _urgencyColor(String? u) {
    switch (u) {
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

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final date = DateFormat('MMM d, y').format(report.createdAt);
    final time = DateFormat('h:mm a').format(report.createdAt);
    final id = '#RPT-${report.id.substring(0, 4).toUpperCase()}';
    final needsAction =
        report.currentStatus == AppConstants.statusAssigned ||
        report.currentStatus == AppConstants.statusNeedsRevision;

    return AdminTableRow(
      onTap: onView,
      child: Container(
        color: isSelected
            ? const Color(0xFFF0F4FF)
            : needsAction
            ? const Color(0xFFFFFBEB)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            // ID
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
                  if (needsAction)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Category
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    report.category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    report.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Barangay
            SizedBox(
              width: 140,
              child: Text(
                'Brgy. ${report.barangay}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Reporter
            SizedBox(
              width: 120,
              child: Text(
                report.isAnonymous
                    ? 'Anonymous'
                    : report.userFullName.split(' ').first,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Date
            SizedBox(
              width: 130,
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

            // Status
            SizedBox(
              width: 130,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.currentStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            // Urgency
            SizedBox(
              width: 100,
              child: report.urgencyLevel != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _urgencyColor(
                            report.urgencyLevel,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _urgencyColor(
                              report.urgencyLevel,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              report.urgencyLevel == 'High'
                                  ? Icons.arrow_upward_rounded
                                  : report.urgencyLevel == 'Low'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.remove_rounded,
                              size: 10,
                              color: _urgencyColor(report.urgencyLevel),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.urgencyLevel!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _urgencyColor(report.urgencyLevel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      '—',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Range Calendar ───────────────────────────────────────────────────────

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

  void _previousMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
  });

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
                : () => setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, i + 1, 1);
                    _pickerMode = null;
                  }),
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
            onTap: () => setState(() {
              _focusedMonth = DateTime(year, _focusedMonth.month, 1);
              _pickerMode = null;
            }),
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
          if (_pickerMode == 'month') _buildMonthPicker(),
          if (_pickerMode == 'year') _buildYearPicker(),
          if (_pickerMode != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _ActionRow(
              showClear: widget.initialRange != null,
              onClear: widget.onClear,
              onApply: (_rangeStart != null && _rangeEnd != null)
                  ? _applySelection
                  : null,
            ),
          ],
          if (_pickerMode == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => SizedBox(
                      width: 40,
                      child: Text(
                        d,
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

              final hasValidDay = weekWidgets.any((w) => w is GestureDetector);
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
            _ActionRow(
              showClear: widget.initialRange != null,
              onClear: widget.onClear,
              onApply: (_rangeStart != null && _rangeEnd != null)
                  ? _applySelection
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool showClear;
  final VoidCallback onClear;
  final VoidCallback? onApply;
  const _ActionRow({
    required this.showClear,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showClear) ...[
          Expanded(
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
