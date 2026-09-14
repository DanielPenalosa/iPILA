import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/global_notification_manager.dart';

/// Provider that polls Firestore for new notifications and shows popups
class NotificationProvider extends ChangeNotifier {
  Timer? _pollTimer;
  String? _userId;
  DateTime? _lastCheckTime;
  final Set<String> _processedNotificationIds = {};
  bool _isActive = false;

  /// Start polling for notifications for a specific user
  void startPolling(String userId) {
    if (_isActive && _userId == userId) {
      debugPrint('🔄 Notification polling already active for user: $userId');
      return;
    }

    stopPolling();

    _userId = userId;
    _isActive = true;
    _lastCheckTime = DateTime.now();
    _processedNotificationIds.clear();

    debugPrint('🔄 ===== STARTING NOTIFICATION POLLING =====');
    debugPrint('🔄 User ID: $userId');
    debugPrint('🔄 Check interval: 3 seconds');

    // Check immediately
    _checkForNewNotifications();

    // Then poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkForNewNotifications();
    });
  }

  /// Stop polling for notifications
  void stopPolling() {
    debugPrint('🔄 Stopping notification polling');
    _pollTimer?.cancel();
    _pollTimer = null;
    _isActive = false;
    _userId = null;
    _lastCheckTime = null;
    _processedNotificationIds.clear();
  }

  /// Check Firestore for new notifications
  Future<void> _checkForNewNotifications() async {
    if (_userId == null || !_isActive) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: _userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(_lastCheckTime!))
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      debugPrint('🔄 Found ${snapshot.docs.length} new notifications');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final notifId = doc.id;

        // Skip if already processed
        if (_processedNotificationIds.contains(notifId)) {
          continue;
        }

        final title = data['title'] as String? ?? 'New Notification';
        final body = data['body'] as String? ?? '';
        final type = data['type'] as String? ?? 'info';
        final reportId = data['reportId'] as String?;
        final createdAt = (data['createdAt'] as Timestamp).toDate();

        debugPrint('🔄 New notification found:');
        debugPrint('🔄   ID: $notifId');
        debugPrint('🔄   Title: $title');
        debugPrint('🔄   Type: $type');
        debugPrint('🔄   ReportId: $reportId');

        // Mark as processed
        _processedNotificationIds.add(notifId);

        // Show popup for important notifications
        if (type == 'new_report' || type == 'assignment') {
          debugPrint('🔄   📢 Triggering popup via GlobalNotificationManager');
          GlobalNotificationManager.showNotification(
            title: title,
            message: body,
            type: type,
            reportId: reportId,
          );
        }

        // Update last check time
        if (_lastCheckTime == null || createdAt.isAfter(_lastCheckTime!)) {
          _lastCheckTime = createdAt;
        }
      }
    } catch (e) {
      debugPrint('🔄 ❌ Error checking notifications: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
