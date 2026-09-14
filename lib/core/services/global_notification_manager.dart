import 'package:flutter/material.dart';
import '../widgets/simple_notification_popup.dart';

/// Global notification manager that can show popups from anywhere
/// This uses a static overlay key approach that doesn't depend on Firestore listeners
class GlobalNotificationManager {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final List<_PendingNotification> _pendingNotifications = [];
  static bool _isProcessing = false;

  /// Initialize with the root navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    debugPrint('✨ GlobalNotificationManager initialized');
  }

  /// Show a notification popup immediately
  static void showNotification({
    required String title,
    required String message,
    required String type,
    String? reportId,
    String? notificationId,  // NEW: notification ID to mark as read
  }) {
    debugPrint('📢 GlobalNotificationManager.showNotification called');
    debugPrint('📢   Title: $title');
    debugPrint('📢   Type: $type');
    debugPrint('📢   ReportId: $reportId');
    debugPrint('📢   NotificationId: $notificationId');

    if (_navigatorKey == null) {
      debugPrint('📢 ⚠️  Navigator key not set, queueing notification');
      _pendingNotifications.add(_PendingNotification(
        title: title,
        message: message,
        type: type,
        reportId: reportId,
        notificationId: notificationId,
      ));
      return;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null || !context.mounted) {
      debugPrint('📢 ⚠️  Context not available, queueing notification');
      _pendingNotifications.add(_PendingNotification(
        title: title,
        message: message,
        type: type,
        reportId: reportId,
        notificationId: notificationId,
      ));
      return;
    }

    debugPrint('📢 ✅ Showing notification popup now');
    try {
      SimpleNotificationPopup.show(
        context: context,
        title: title,
        message: message,
        type: type,
        reportId: reportId,
        notificationId: notificationId,  // Pass it to the popup
      );
      debugPrint('📢 ✅ Popup call completed');
    } catch (e, stackTrace) {
      debugPrint('📢 ❌ Error showing popup: $e');
      debugPrint('📢 Stack trace: $stackTrace');
    }
  }

  /// Process any pending notifications
  static void processPendingNotifications() {
    if (_isProcessing || _pendingNotifications.isEmpty) return;
    
    _isProcessing = true;
    debugPrint('📢 Processing ${_pendingNotifications.length} pending notifications');

    final context = _navigatorKey?.currentContext;
    if (context != null && context.mounted) {
      for (final notification in _pendingNotifications) {
        try {
          SimpleNotificationPopup.show(
            context: context,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            reportId: notification.reportId,
            notificationId: notification.notificationId,  // Pass it
          );
        } catch (e) {
          debugPrint('📢 ❌ Error showing pending notification: $e');
        }
      }
      _pendingNotifications.clear();
    }

    _isProcessing = false;
  }
}

class _PendingNotification {
  final String title;
  final String message;
  final String type;
  final String? reportId;
  final String? notificationId;

  _PendingNotification({
    required this.title,
    required this.message,
    required this.type,
    this.reportId,
    this.notificationId,
  });
}
