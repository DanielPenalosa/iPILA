import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/sound_service.dart';

class NotificationPopup {
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required String type,
    String? reportId,
  }) {
    debugPrint('🎯 NotificationPopup.show called');
    debugPrint('🎯   Title: $title');
    debugPrint('🎯   Type: $type');
    debugPrint('🎯   ReportId: $reportId');
    debugPrint('🎯   Context mounted: ${context.mounted}');
    
    // Remove existing popup if any
    dismiss();

    // Start looping sound
    debugPrint('🎯 Starting sound loop...');
    SoundService.playNotificationLoop();

    _currentOverlay = OverlayEntry(
      builder: (context) => _NotificationPopupWidget(
        title: title,
        message: message,
        type: type,
        reportId: reportId,
        onDismiss: dismiss,
      ),
    );

    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      debugPrint('🎯 Inserting overlay into root...');
      overlay.insert(_currentOverlay!);
      debugPrint('🎯 ✅ Popup shown successfully');
    } catch (e) {
      debugPrint('🎯 ❌ ERROR showing popup: $e');
      _currentOverlay = null;
    }
  }

  static void dismiss() {
    debugPrint('🎯 NotificationPopup.dismiss called');
    SoundService.stopNotificationLoop();
    _currentOverlay?.remove();
    _currentOverlay = null;
    debugPrint('🎯 Popup dismissed');
  }
}

class _NotificationPopupWidget extends StatefulWidget {
  final String title;
  final String message;
  final String type;
  final String? reportId;
  final VoidCallback onDismiss;

  const _NotificationPopupWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.reportId,
    required this.onDismiss,
  });

  @override
  State<_NotificationPopupWidget> createState() =>
      _NotificationPopupWidgetState();
}

class _NotificationPopupWidgetState extends State<_NotificationPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case 'new_report':
        return Icons.report_problem_outlined;
      case 'assignment':
        return Icons.assignment_ind_outlined;
      case 'progress':
        return Icons.sync_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color get _color {
    switch (widget.type) {
      case 'new_report':
        return const Color(0xFFDC2626);
      case 'assignment':
        return const Color(0xFFF59E0B);
      case 'progress':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  void _handleTap() {
    widget.onDismiss();
    if (widget.reportId != null && widget.reportId!.isNotEmpty) {
      // Navigate based on context - check current route
      final routerState = GoRouterState.of(context);
      final currentPath = routerState?.uri.path ?? '';
      if (currentPath.startsWith('/admin')) {
        context.go('/admin/reports/${widget.reportId}');
      } else if (currentPath.startsWith('/department')) {
        context.go('/department/reports/${widget.reportId}');
      } else if (currentPath.startsWith('/barangay')) {
        context.go('/barangay/reports/${widget.reportId}');
      } else {
        context.go('/report/${widget.reportId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 Building popup widget');
    return Stack(
      children: [
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            color: Colors.black.withValues(alpha: 0.7),
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with animated icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            _PulsingIcon(icon: _icon, color: _color),
                            const SizedBox(height: 16),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Message
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.onDismiss,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Dismiss',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.reportId != null &&
                                widget.reportId!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _handleTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _color,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'View Report',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: 48,
          color: widget.color,
        ),
      ),
    );
  }
}
