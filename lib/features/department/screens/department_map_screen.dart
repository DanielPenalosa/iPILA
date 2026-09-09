import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/department_service.dart';
import '../../auth/providers/auth_provider.dart';

class DepartmentMapScreen extends StatefulWidget {
  const DepartmentMapScreen({super.key});

  @override
  State<DepartmentMapScreen> createState() => _DepartmentMapScreenState();
}

class _DepartmentMapScreenState extends State<DepartmentMapScreen> {
  late final MapController _mapController;
  String _filterStatus = 'All';
  String _filterBarangay = 'All';
  String _mapStyle = 'Street';

  static const _center = LatLng(14.1637, 121.8647);

  static const _statuses = [
    'All',
    AppConstants.statusAssigned,
    AppConstants.statusInProgress,
    AppConstants.statusDone,
    AppConstants.statusNeedsRevision,
    AppConstants.statusResolved,
  ];

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

  List<ReportModel> _applyFilters(List<ReportModel> all) {
    return all.where((r) {
      if (_filterStatus != 'All' && r.currentStatus != _filterStatus)
        return false;
      if (_filterBarangay != 'All' && r.barangay != _filterBarangay)
        return false;
      return true;
    }).toList();
  }

  Color _statusColor(String status) => AppTheme.statusColor(status);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<ReportModel>>(
      stream: DepartmentService().getDepartmentReports(user.uid),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);

        // Build barangay list from actual reports
        final barangays = [
          'All',
          ...{...all.map((r) => r.barangay)}.toList()..sort(),
        ];

        return Column(
          children: [
            // ── Filter bar ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  _FilterDropdown(
                    label: 'Status',
                    value: _filterStatus,
                    items: _statuses,
                    onChanged: (v) => setState(() => _filterStatus = v!),
                  ),
                  const SizedBox(width: 12),
                  _FilterDropdown(
                    label: 'Barangay',
                    value: _filterBarangay,
                    items: barangays,
                    onChanged: (v) => setState(() => _filterBarangay = v!),
                  ),
                  const SizedBox(width: 12),
                  // Map style
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _mapStyle,
                      underline: const SizedBox(),
                      isDense: true,
                      icon: const Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                      items: ['Street', 'Satellite', 'Terrain']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _mapStyle = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ToolButton(
                    icon: Icons.my_location,
                    label: 'Center',
                    onPressed: () => _mapController.move(_center, 13),
                  ),
                  const Spacer(),
                  // Legend
                  Wrap(
                    spacing: 14,
                    children:
                        [
                              ('Assigned', AppTheme.statusColor('Assigned')),
                              (
                                'In Progress',
                                AppTheme.statusColor('In Progress'),
                              ),
                              ('Done', AppTheme.statusColor('Done')),
                              (
                                'Needs Revision',
                                AppTheme.statusColor('Needs Revision'),
                              ),
                              ('Resolved', AppTheme.statusColor('Resolved')),
                            ]
                            .map(
                              (e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
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
                                      color: Color(0xFF9CA3AF),
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
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Map + panel ───────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Map
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: _center,
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _mapStyle == 'Satellite'
                                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                  : _mapStyle == 'Terrain'
                                  ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
                                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.pila.ipila',
                            ),
                            MarkerLayer(
                              markers: filtered.map((r) {
                                final color = _statusColor(r.currentStatus);
                                return Marker(
                                  point: LatLng(r.latitude, r.longitude),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => _ReportDialog(
                                        report: r,
                                        statusColor: color,
                                      ),
                                    ),
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
                                            color: color.withValues(
                                              alpha: 0.35,
                                            ),
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

                        // Stats overlay
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _StatsCard(
                            reports: filtered,
                            statusColor: _statusColor,
                          ),
                        ),

                        // Zoom controls
                        Positioned(
                          right: 16,
                          bottom: 24,
                          child: _ZoomControls(controller: _mapController),
                        ),
                      ],
                    ),
                  ),

                  // Side list
                  Container(
                    width: 280,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Text(
                            '${filtered.length} report${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No reports match filters.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: Color(0xFFF9FAFB),
                                  ),
                                  itemBuilder: (_, i) {
                                    final r = filtered[i];
                                    return _ListItem(
                                      report: r,
                                      color: _statusColor(r.currentStatus),
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
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
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
        value: value,
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
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<ReportModel> reports;
  final Color Function(String) statusColor;

  const _StatsCard({required this.reports, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final byStatus = <String, int>{};
    for (final r in reports) {
      byStatus[r.currentStatus] = (byStatus[r.currentStatus] ?? 0) + 1;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${reports.length}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              letterSpacing: -1,
            ),
          ),
          const Text(
            'reports',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          if (byStatus.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),
            ...byStatus.entries.map((e) {
              final c = statusColor(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final MapController controller;
  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomBtn(
          icon: Icons.add,
          onTap: () {
            final z = controller.camera.zoom;
            controller.move(controller.camera.center, z + 1);
          },
        ),
        const SizedBox(height: 4),
        _ZoomBtn(
          icon: Icons.remove,
          onTap: () {
            final z = controller.camera.zoom;
            controller.move(controller.camera.center, z - 1);
          },
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF374151)),
        ),
      ),
    );
  }
}

class _ListItem extends StatefulWidget {
  final ReportModel report;
  final Color color;
  final VoidCallback onTap;

  const _ListItem({
    required this.report,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _hovered ? widget.color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _hovered ? 10 : 8,
                height: _hovered ? 10 : 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 5,
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
                        color: _hovered
                            ? widget.color
                            : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Brgy. ${widget.report.barangay}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.report.currentStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
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

// ── Report dialog ─────────────────────────────────────────────────────────────

class _ReportDialog extends StatelessWidget {
  final ReportModel report;
  final Color statusColor;

  const _ReportDialog({required this.report, required this.statusColor});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Coloured header banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Brgy. ${report.barangay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      report.currentStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _DialogRow(
                          icon: Icons.person_outline,
                          label: 'Reporter',
                          value: report.isAnonymous
                              ? 'Anonymous'
                              : report.userFullName,
                        ),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _DialogRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: report.address.isNotEmpty
                              ? report.address
                              : 'Brgy. ${report.barangay}',
                        ),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _DialogRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Reported',
                          value: _timeAgo(report.createdAt),
                        ),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _DialogRow(
                          icon: Icons.update_outlined,
                          label: 'Updated',
                          value: DateFormat(
                            'MMM d, yyyy – h:mm a',
                          ).format(report.updatedAt),
                        ),
                        if (report.assignedDepartment != null) ...[
                          const Divider(height: 16, color: Color(0xFFE5E7EB)),
                          _DialogRow(
                            icon: Icons.business_outlined,
                            label: 'Department',
                            value: report.assignedDepartment!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      report.description.isNotEmpty
                          ? report.description
                          : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Photos
                  if (report.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'PHOTOS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: report.photoUrls.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            report.photoUrls[i],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Latest progress update
                  if (report.progressUpdates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'LATEST UPDATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final latest = ([
                          ...report.progressUpdates,
                        ]..sort(
                                (a, b) =>
                                    b.timestamp.compareTo(a.timestamp)))
                            .first;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    latest.status,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              if (latest.remarks != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  latest.remarks!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'By ${latest.updatedBy} · ${DateFormat('MMM d, h:mm a').format(latest.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF9CA3AF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/department/reports/${report.id}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Full Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DialogRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFD1D5DB)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
