import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import 'admin_shell.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  late final MapController _mapController;
  String _filterStatus = 'All';
  String _filterBarangay = 'All';
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Pila, Laguna center
  static const _center = LatLng(14.1500, 121.3667);

  List<ReportModel> _applyFilters(List<ReportModel> reports) {
    return reports.where((r) {
      if (_filterStatus != 'All' && r.currentStatus != _filterStatus) {
        return false;
      }
      if (_filterBarangay != 'All' && r.barangay != _filterBarangay) {
        return false;
      }
      if (_filterCategory != 'All' && r.category != _filterCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  Color _markerColor(String status) {
    switch (status) {
      case 'Submitted':
        return Colors.orange;
      case 'Seen':
        return Colors.purple;
      case 'Validated':
        return Colors.cyan;
      case 'Queued':
        return Colors.amber;
      case 'In Progress':
        return AppTheme.primaryBlue;
      case 'Completed':
        return AppTheme.successGreen;
      case 'Rejected':
        return AppTheme.primaryRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/map',
      child: Column(
        children: [
          const AdminPageHeader(
            title: 'Report Map',
            subtitle: 'Municipality of Pila, Laguna',
          ),
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                _FilterDropdown(
                  label: 'Status',
                  value: _filterStatus,
                  items: ['All', ...AppConstants.reportStatuses],
                  onChanged: (v) => setState(() => _filterStatus = v!),
                ),
                const SizedBox(width: 12),
                _FilterDropdown(
                  label: 'Barangay',
                  value: _filterBarangay,
                  items: ['All', ...AppConstants.barangays],
                  onChanged: (v) => setState(() => _filterBarangay = v!),
                ),
                const SizedBox(width: 12),
                _FilterDropdown(
                  label: 'Category',
                  value: _filterCategory,
                  items: ['All', ...AppConstants.issueCategories],
                  onChanged: (v) => setState(() => _filterCategory = v!),
                ),
                const Spacer(),
                Wrap(
                  spacing: 12,
                  children:
                      [
                            ('New', Colors.orange),
                            ('In Progress', AppTheme.primaryBlue),
                            ('Completed', AppTheme.successGreen),
                            ('Rejected', AppTheme.primaryRed),
                          ]
                          .map(
                            (e) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: e.$2,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.$1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: ReportService().getAllReports(),
              builder: (context, snapshot) {
                final reports = snapshot.data ?? [];
                final filtered = _applyFilters(reports);

                return Row(
                  children: [
                    // Map
                    Expanded(
                      flex: 3,
                      child: FlutterMap(
                        key: const ValueKey('admin_map'),
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _center,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.pila.ipila',
                          ),
                          MarkerLayer(
                            markers: filtered.map((r) {
                              final color = _markerColor(r.currentStatus);
                              return Marker(
                                point: LatLng(r.latitude, r.longitude),
                                width: 36,
                                height: 36,
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(r.category),
                                        content: Text(
                                          'Brgy. ${r.barangay}\n'
                                          'Status: ${r.currentStatus}\n'
                                          'Reported by: ${r.isAnonymous ? "Anonymous" : r.userFullName}',
                                        ),
                                        actions: [
                                          AdminHoverButton(
                                            label: 'Close',
                                            onTap: () => Navigator.pop(context),
                                            outlined: true,
                                            small: true,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    // Side panel
                    Container(
                      width: 280,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '${filtered.length} reports shown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No reports match filters.',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final r = filtered[i];
                                      final color = AppTheme.statusColor(
                                        r.currentStatus,
                                      );
                                      return _ReportListItem(
                                        report: r,
                                        color: color,
                                        onTap: () => _mapController.move(
                                          LatLng(r.latitude, r.longitude),
                                          16,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        items: items
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ReportListItem extends StatefulWidget {
  final ReportModel report;
  final Color color;
  final VoidCallback onTap;

  const _ReportListItem({
    required this.report,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ReportListItem> createState() => _ReportListItemState();
}

class _ReportListItemState extends State<_ReportListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _hovered ? widget.color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          transform: _hovered
              ? (Matrix4.identity()..translate(4.0, 0.0))
              : Matrix4.identity(),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _hovered ? 12 : 10,
                height: _hovered ? 12 : 10,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _hovered
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _hovered ? widget.color : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Brgy. ${widget.report.barangay}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(
                  horizontal: _hovered ? 8 : 6,
                  vertical: _hovered ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: _hovered ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.report.currentStatus,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.color,
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
}
