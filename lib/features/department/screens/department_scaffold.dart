import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/department_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Full sidebar scaffold for department users — mirrors admin layout.
class DepartmentScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigate;

  const DepartmentScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<DepartmentScaffold> createState() => _DepartmentScaffoldState();
}

class _DepartmentScaffoldState extends State<DepartmentScaffold> {
  bool _collapsed = false;

  static const _navItems = [
    _DeptNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
    _DeptNavItem(label: 'Reports', icon: Icons.assignment_outlined),
    _DeptNavItem(label: 'Map', icon: Icons.map_outlined),
    _DeptNavItem(label: 'Notifications', icon: Icons.notifications_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: _collapsed ? 80 : 240,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _collapsed ? 12 : 20,
                    24,
                    _collapsed ? 12 : 20,
                    20,
                  ),
                  child: _collapsed
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'iPILA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    user?.department ?? 'Department Portal',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: _DeptNotificationBadgeBuilder(
                    userId: user?.uid ?? '',
                    builder: (unread) => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (_, i) {
                        final badge = i == 3 && unread > 0 ? unread : null;
                        return _SidebarItem(
                          item: _navItems[i],
                          isActive: widget.currentIndex == i,
                          badge: badge,
                          isCollapsed: _collapsed,
                          onTap: () => widget.onNavigate(i),
                        );
                      },
                    ),
                  ),
                ),

                const Divider(height: 1),
                // Footer
                _collapsed
                    ? Padding(
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
                    : Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.purple,
                              child: Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : 'D',
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
                                    user?.department ?? 'Department',
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

          // ── Animated content ─────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                _DeptTopBar(
                  onToggleSidebar: () =>
                      setState(() => _collapsed = !_collapsed),
                  userId: user?.uid ?? '',
                  departmentName: user?.department ?? '',
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.012, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(widget.currentIndex),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptTopBar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final String userId;
  final String departmentName;

  const _DeptTopBar({
    required this.onToggleSidebar,
    required this.userId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.grey[700], size: 22),
            onPressed: onToggleSidebar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              departmentName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          // Notification bell
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.notificationsCollection)
                .where('userId', isEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final unread = snap.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey[700],
                      size: 22,
                    ),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeptNotificationBadgeBuilder extends StatelessWidget {
  final String userId;
  final Widget Function(int unread) builder;

  const _DeptNotificationBadgeBuilder({
    required this.userId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (_, snap) => builder(snap.data?.docs.length ?? 0),
    );
  }
}

class _DeptNavItem {
  final String label;
  final IconData icon;
  const _DeptNavItem({required this.label, required this.icon});
}

class _SidebarItem extends StatefulWidget {
  final _DeptNavItem item;
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
                  ? Colors.purple.withValues(alpha: 0.1)
                  : _hovered
                  ? const Color(0xFFF5F6FA)
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
                              ? Colors.purple
                              : AppTheme.textMuted,
                        ),
                        if (widget.badge != null)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryRed,
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
                            ? Colors.purple
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
                                ? Colors.purple
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
      ),
    );
  }
}
