import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import 'admin_shell.dart';

class AdminMapScreen extends StatefulWidget {
  final double? focusLat;
  final double? focusLng;
  final String? focusReportId;

  const AdminMapScreen({
    super.key,
    this.focusLat,
    this.focusLng,
    this.focusReportId,
  });

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  late final MapController _mapController;
  String _filterStatus = 'All';
  String _filterBarangay = 'All';
  String _filterCategory = 'All';
  bool _clusterMarkers = true;
  String _mapStyle = 'Street';
  bool _didFocus = false;
  bool _didOpenDialog = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFocus && widget.focusLat != null && widget.focusLng != null) {
      _didFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.focusLat!, widget.focusLng!),
          16,
        );
      });
    }
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

  Color _markerColor(String status) => AppTheme.statusColor(status);

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
          // Filter and control bar
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
                const SizedBox(width: 16),
                // Map style selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _mapStyle,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(Icons.map, size: 18),
                    items: ['Street', 'Satellite', 'Terrain']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _mapStyle = v!),
                  ),
                ),
                const SizedBox(width: 12),
                // View options
                _MapToggleButton(
                  icon: Icons.location_searching,
                  label: 'Center',
                  onPressed: () => _mapController.move(_center, 13),
                ),
                const SizedBox(width: 8),
                _MapToggleButton(
                  icon: Icons.layers,
                  label: 'Cluster',
                  active: _clusterMarkers,
                  onPressed: () =>
                      setState(() => _clusterMarkers = !_clusterMarkers),
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

                // Auto-open the focused report dialog once data loads
                if (widget.focusReportId != null && !_didOpenDialog && reports.isNotEmpty) {
                  final target = reports.cast<ReportModel?>().firstWhere(
                    (r) => r!.id == widget.focusReportId,
                    orElse: () => null,
                  );
                  if (target != null) {
                    _didOpenDialog = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => _ReportDialog(report: target),
                        );
                      }
                    });
                  }
                }

                return Row(
                  children: [
                    // Map
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: const ValueKey('admin_map'),
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
                                  final color = _markerColor(r.currentStatus);
                                  return Marker(
                                    point: LatLng(r.latitude, r.longitude),
                                    width: 36,
                                    height: 36,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              _ReportDialog(report: r),
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
                                              color: color.withValues(
                                                alpha: 0.4,
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
                          // Statistics overlay
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _MapStatsCard(reports: filtered),
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
                    // Side panel
                    Container(
                      width: 280,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Legend
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children:
                                  [
                                        (
                                          'Pending',
                                          AppTheme.statusColor('Pending'),
                                        ),
                                        (
                                          'Under Review',
                                          AppTheme.statusColor('Under Review'),
                                        ),
                                        (
                                          'Assigned',
                                          AppTheme.statusColor('Assigned'),
                                        ),
                                        (
                                          'In Progress',
                                          AppTheme.statusColor('In Progress'),
                                        ),
                                        ('Done', AppTheme.statusColor('Done')),
                                        (
                                          'Needs Revision',
                                          AppTheme.statusColor(
                                            'Needs Revision',
                                          ),
                                        ),
                                        (
                                          'Resolved',
                                          AppTheme.statusColor('Resolved'),
                                        ),
                                        (
                                          'Rejected',
                                          AppTheme.statusColor('Rejected'),
                                        ),
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
                                                fontSize: 10,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          const Divider(height: 1),
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

// Map toggle button
class _MapToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _MapToggleButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppTheme.primaryYellow.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? AppTheme.primaryYellow : AppTheme.borderColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppTheme.primaryYellow : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? AppTheme.primaryYellow : AppTheme.textDark,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Map statistics overlay card
class _MapStatsCard extends StatelessWidget {
  final List<ReportModel> reports;
  const _MapStatsCard({required this.reports});

  @override
  Widget build(BuildContext context) {
    final byStatus = <String, int>{};
    for (final r in reports) {
      byStatus[r.currentStatus] = (byStatus[r.currentStatus] ?? 0) + 1;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                size: 16,
                color: AppTheme.primaryYellow,
              ),
              const SizedBox(width: 6),
              const Text(
                'Map Statistics',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${reports.length}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const Text(
            'Total Reports',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ...byStatus.entries.map((e) {
            final color = AppTheme.statusColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Zoom controls
class _ZoomControls extends StatelessWidget {
  final MapController controller;
  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: Icons.add,
          onPressed: () {
            final zoom = controller.camera.zoom;
            controller.move(controller.camera.center, zoom + 1);
          },
        ),
        const SizedBox(height: 4),
        _ZoomButton(
          icon: Icons.remove,
          onPressed: () {
            final zoom = controller.camera.zoom;
            controller.move(controller.camera.center, zoom - 1);
          },
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppTheme.textDark),
          ),
        ),
      ),
    );
  }
}

// Enhanced report dialog
class _ReportDialog extends StatelessWidget {
  final ReportModel report;
  const _ReportDialog({required this.report});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(report.currentStatus);
    final statusIcon = AppTheme.statusIcon(report.currentStatus);

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
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
                            Icon(Icons.place_outlined, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              'Brgy. ${report.barangay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
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
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Reporter',
                          value: report.isAnonymous ? 'Anonymous' : report.userFullName,
                        ),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: report.address.isNotEmpty
                              ? report.address
                              : 'Brgy. ${report.barangay}',
                        ),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _InfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Reported',
                          value: _formatDate(report.createdAt),
                        ),
                        if (report.followerCount > 0) ...[
                          const Divider(height: 16, color: Color(0xFFE5E7EB)),
                          _InfoRow(
                            icon: Icons.group_outlined,
                            label: 'Followers',
                            value: '${report.followerCount} citizens',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  _SectionLabel(label: 'Description'),
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
                      report.description.isNotEmpty ? report.description : '—',
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
                    _SectionLabel(label: 'Photos'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: report.photoUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
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

                  const SizedBox(height: 20),
                ],
              ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/admin/reports/${report.id}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Full Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
