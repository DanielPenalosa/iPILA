import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

class AdminScaffoldWidget extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdminScaffoldWidget({super.key, required this.navigationShell});

  @override
  State<AdminScaffoldWidget> createState() => AdminScaffoldWidgetState();

  // Static method to toggle sidebar from anywhere
  static void toggleSidebar() {
    AdminScaffoldWidgetState._instance?.toggleSidebar();
  }
}

class AdminScaffoldWidgetState extends State<AdminScaffoldWidget> {
  final ReportService _reportService = ReportService();
  bool _isSidebarCollapsed = false;

  // Static reference to allow access from anywhere
  static AdminScaffoldWidgetState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  static const _navItems = [
    _NavItem(label: 'Overview', icon: Icons.grid_view_rounded, index: 0),
    _NavItem(label: 'Reports', icon: Icons.assignment_outlined, index: 1),
    _NavItem(label: 'Users', icon: Icons.people_outline_rounded, index: 2),
    _NavItem(label: 'Analytics', icon: Icons.bar_chart_rounded, index: 3),
    _NavItem(label: 'Map', icon: Icons.map_outlined, index: 4),
    _NavItem(label: 'Ordinances', icon: Icons.gavel_outlined, index: 5),
    _NavItem(label: 'Alerts', icon: Icons.notifications_outlined, index: 6),
    _NavItem(label: 'Settings', icon: Icons.settings_outlined, index: 7),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          // ── Persistent sidebar ──────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: _isSidebarCollapsed ? 72 : 232,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: const Color(0xFFF3F4F6))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _isSidebarCollapsed ? 12 : 20,
                    24,
                    _isSidebarCollapsed ? 12 : 20,
                    20,
                  ),
                  child: _isSidebarCollapsed
                      ? Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'iPILA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'LGU Admin Portal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<ReportModel>>(
                    stream: _reportService.getAllReports(),
                    builder: (context, snapshot) {
                      final reports = snapshot.data ?? [];
                      final newCount = reports
                          .where(
                            (r) =>
                                r.currentStatus == AppConstants.statusPending,
                          )
                          .length;
                      final alertCount = reports
                          .where(
                            (r) =>
                                r.currentStatus == 'Overdue' ||
                                r.currentStatus == AppConstants.statusPending,
                          )
                          .length;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _navItems.length,
                        itemBuilder: (_, i) {
                          int? badge;
                          if (i == 1 && newCount > 0) badge = newCount;
                          if (i == 6 && alertCount > 0) badge = alertCount;

                          return _SidebarItem(
                            item: _navItems[i],
                            isActive: currentIndex == i,
                            badge: badge,
                            isCollapsed: _isSidebarCollapsed,
                            onTap: () => widget.navigationShell.goBranch(
                              i,
                              initialLocation: i == currentIndex,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                if (_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => auth.signOut(),
                        tooltip: 'Sign out',
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF111111),
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Admin User',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => auth.signOut(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Sign out',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Animated content area ───────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.012, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(currentIndex),
                child: widget.navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.index,
  });
}

class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final int? badge;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.isCollapsed,
    this.badge,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.isCollapsed ? widget.item.label : '',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? const Color(0xFF111111).withValues(alpha: 0.06)
                  : _hovered
                  ? const Color(0xFFF9FAFB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.isCollapsed
                ? Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          widget.item.icon,
                          size: 18,
                          color: widget.isActive
                              ? const Color(0xFF111111)
                              : AppTheme.textMuted,
                        ),
                        if (widget.badge != null)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.badge}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        widget.item.icon,
                        size: 18,
                        color: widget.isActive
                            ? const Color(0xFF111111)
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: widget.isActive
                                ? const Color(0xFF111111)
                                : AppTheme.textDark,
                          ),
                        ),
                      ),
                      if (widget.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.badge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
