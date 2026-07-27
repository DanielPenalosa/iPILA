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
  bool _clusterMarkers = true;
  String _mapStyle = 'Street';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.statusColor(
                      report.currentStatus,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppTheme.statusIcon(report.currentStatus),
                    color: AppTheme.statusColor(report.currentStatus),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Brgy. ${report.barangay}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.person,
              label: 'Reporter',
              value: report.isAnonymous ? 'Anonymous' : report.userFullName,
            ),
            _InfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: report.address,
            ),
            _InfoRow(
              icon: Icons.flag,
              label: 'Status',
              value: report.currentStatus,
              valueColor: AppTheme.statusColor(report.currentStatus),
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Reported',
              value: _formatDate(report.createdAt),
            ),
            if (report.followerCount > 0)
              _InfoRow(
                icon: Icons.group,
                label: 'Followers',
                value: '${report.followerCount} citizens',
              ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(report.description, style: const TextStyle(fontSize: 14)),
            if (report.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminHoverButton(
                  label: 'View Full Report',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to report detail
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
