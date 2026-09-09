import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/barangay_service.dart';
import '../../auth/providers/auth_provider.dart';

class BarangayReportsScreen extends StatefulWidget {
  const BarangayReportsScreen({super.key});

  @override
  State<BarangayReportsScreen> createState() => _BarangayReportsScreenState();
}

class _BarangayReportsScreenState extends State<BarangayReportsScreen> {
  String _filter = 'All';
  String _search = '';
  final Set<String> _selectedIds = {};

  static const _filters = [
    'All', 'Assigned', 'In Progress', 'Done', 'Needs Revision', 'Resolved',
  ];

  List<ReportModel> _apply(List<ReportModel> all) {
    var list = _filter == 'All'
        ? all
        : all.where((r) => r.currentStatus == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) =>
          r.category.toLowerCase().contains(q) ||
          r.barangay.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.userFullName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<ReportModel>>(
      stream: BarangayService().getBarangayReports(user.uid),
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
                  ..._filters.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  )),
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
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Column headers ─────────────────────────────────────
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Checkbox(
                      value: filtered.isNotEmpty &&
                          _selectedIds.containsAll(filtered.map((r) => r.id)),
                      tristate: true,
                      onChanged: (_) {
                        final allSel = _selectedIds.containsAll(filtered.map((r) => r.id));
                        setState(() {
                          if (allSel) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(filtered.map((r) => r.id));
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 80, child: Text('ID', style: _hStyle)),
                  const SizedBox(width: 180, child: Text('CATEGORY', style: _hStyle)),
                  const SizedBox(width: 140, child: Text('BARANGAY', style: _hStyle)),
                  const SizedBox(width: 120, child: Text('REPORTER', style: _hStyle)),
                  const SizedBox(width: 130, child: Text('DATE', style: _hStyle)),
                  const Expanded(child: Text('STATUS', style: _hStyle)),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── List ───────────────────────────────────────────────
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            _search.isNotEmpty
                                ? 'No results for "$_search"'
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
                          onView: () => context.push('/barangay/reports/${r.id}'),
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

const _hStyle = TextStyle(
  fontSize: 11, fontWeight: FontWeight.w700,
  color: AppTheme.textMuted, letterSpacing: 0.5,
);

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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
  final VoidCallback onView;

  const _ReportRow({
    required this.report,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(report.currentStatus);
    final date = DateFormat('MMM d, y').format(report.createdAt);
    final time = DateFormat('h:mm a').format(report.createdAt);
    final id = '#RPT-${report.id.substring(0, 4).toUpperCase()}';
    final needsAction = report.currentStatus == AppConstants.statusAssigned ||
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text(id,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  if (needsAction)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ACTION',
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B))),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.category,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  Text(report.description,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(
              width: 140,
              child: Text('Brgy. ${report.barangay}',
                  style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 120,
              child: Text(
                report.isAnonymous ? 'Anonymous' : report.userFullName.split(' ').first,
                style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(report.currentStatus,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
