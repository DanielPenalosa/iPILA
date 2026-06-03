import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

// Persistent admin scaffold — sidebar stays alive, only content fades
class AdminScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdminScaffold({super.key, required this.navigationShell});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final ReportService _reportService = ReportService();

  static const _navItems = [
    _NavItem(label: 'Overview', icon: Icons.grid_view_rounded, route: '/admin'),
    _NavItem(
      label: 'Reports',
      icon: Icons.assignment_outlined,
      route: '/admin/reports',
    ),
    _NavItem(
      label: 'Users',
      icon: Icons.people_outline_rounded,
      route: '/admin/users',
    ),
    _NavItem(
      label: 'Analytics',
      icon: Icons.bar_chart_rounded,
      route: '/admin/analytics',
    ),
    _NavItem(
      label: 'Ordinances',
      icon: Icons.gavel_outlined,
      route: '/admin/ordinances',
    ),
    _NavItem(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      route: '/admin/alerts',
    ),
  ];

  void _navigate(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Row(
        children: [
          // ── Minimalist Sidebar ──────────────────────────────────
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simple Logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: AppTheme.black,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'iPILA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 16),

                // Minimal Nav items
                Expanded(
                  child: StreamBuilder<List<ReportModel>>(
                    stream: _reportService.getAllReports(),
                    builder: (context, snapshot) {
                      final reports = snapshot.data ?? [];
                      final newCount = reports
                          .where((r) => r.currentStatus == 'Submitted')
                          .length;
                      final alertCount = reports
                          .where(
                            (r) =>
                                r.currentStatus == 'Overdue' ||
                                r.currentStatus == 'Submitted',
                          )
                          .length;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _navItems.length,
                        itemBuilder: (_, i) {
                          int? badge;
                          if (_navItems[i].route == '/admin/reports' &&
                              newCount > 0) {
                            badge = newCount;
                          }
                          if (_navItems[i].route == '/admin/alerts' &&
                              alertCount > 0) {
                            badge = alertCount;
                          }

                          return _MinimalSidebarItem(
                            item: _navItems[i],
                            isActive: currentIndex == i,
                            badge: badge,
                            onTap: () => _navigate(i),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Minimal Admin footer
                Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Admin User',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout_outlined,
                          size: 18,
                          color: Colors.grey[600],
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

          // ── Content area with fade transition ───────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.015, 0),
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
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

// ── Minimal Sidebar Item ──────────────────────────────────────────────────────
class _MinimalSidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _MinimalSidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  State<_MinimalSidebarItem> createState() => _MinimalSidebarItemState();
}

class _MinimalSidebarItemState extends State<_MinimalSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primaryYellow.withValues(alpha: 0.1)
                : _hovered
                ? Colors.grey[100]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? Border.all(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.isActive ? AppTheme.textDark : Colors.grey[600],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.isActive
                        ? AppTheme.textDark
                        : Colors.grey[700],
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
                    color: AppTheme.primaryRed,
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
    );
  }
}

// ── Original Sidebar Item (kept for compatibility) ────────────────────────────
class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bg;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bg = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_SidebarItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _bg,
          builder: (_, child) => Container(
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isActive
                  ? const LinearGradient(
                      colors: [AppTheme.primaryYellow, AppTheme.lightYellow],
                    )
                  : null,
              color: !widget.isActive && _hovered
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.isActive
                      ? AppTheme.black
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isActive
                        ? AppTheme.black
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (widget.badge != null)
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Minimal Page Header ───────────────────────────────────────────────────────
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.8,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ── Legacy wrapper for screens not yet migrated to StatefulShellRoute ─────────
class AdminShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) => child;
}
