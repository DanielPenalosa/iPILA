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
    // Initialize to a time 5 minutes in the past to catch recent notifications
    _lastCheckTime = DateTime.now().subtract(const Duration(minutes: 5));
    _processedNotificationIds.clear();

    debugPrint('🔄 ===== STARTING NOTIFICATION POLLING =====');
    debugPrint('🔄 User ID: $userId');
    debugPrint('🔄 Check interval: 3 seconds');
    debugPrint('🔄 Last check time initialized to: $_lastCheckTime (5 min ago)');

    // Check immediately
    _checkForNewNotifications();

    // Then poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      debugPrint('🔄 ⏰ Polling check triggered...');
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

    debugPrint('🔄 Checking for new notifications...');
    debugPrint('🔄   UserId: $_userId');
    debugPrint('🔄   Last check time: $_lastCheckTime');

    try {
      // Query using descending order to get newest notifications first
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)  // Get newest first
          .limit(20)  // Increased limit to catch more recent notifications
          .get();

      debugPrint('🔄 Query completed - found ${snapshot.docs.length} total notifications');

      if (snapshot.docs.isEmpty) {
        debugPrint('🔄 No notifications found for this user');
        return;
      }

      int newNotificationCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final notifId = doc.id;
        final createdAt = (data['createdAt'] as Timestamp).toDate();

        // Skip if already processed
        if (_processedNotificationIds.contains(notifId)) {
          debugPrint('🔄   Skipping $notifId (already processed)');
          continue;
        }

        // Only process if newer than last check
        if (_lastCheckTime != null && !createdAt.isAfter(_lastCheckTime!)) {
          debugPrint('🔄   Skipping $notifId (older than last check: $createdAt vs $_lastCheckTime)');
          continue;
        }

        final title = data['title'] as String? ?? 'New Notification';
        final body = data['body'] as String? ?? '';
        final type = data['type'] as String? ?? 'info';
        final reportId = data['reportId'] as String?;

        newNotificationCount++;
        debugPrint('🔄 ✨ NEW NOTIFICATION DETECTED! (#$newNotificationCount)');
        debugPrint('🔄   ID: $notifId');
        debugPrint('🔄   Title: $title');
        debugPrint('🔄   Type: $type');
        debugPrint('🔄   ReportId: $reportId');
        debugPrint('🔄   Created: $createdAt');

        // Mark as processed
        _processedNotificationIds.add(notifId);

        // Show popup for important notifications
        if (type == 'new_report' || type == 'assignment') {
          debugPrint('🔄   ✅ Type matches - triggering popup!');
          GlobalNotificationManager.showNotification(
            title: title,
            message: body,
            type: type,
            reportId: reportId,
          );
        } else {
          debugPrint('🔄   ⏭️  Type ($type) doesn\'t match - skipping popup');
        }

        // Update last check time to the newest notification
        if (_lastCheckTime == null || createdAt.isAfter(_lastCheckTime!)) {
          _lastCheckTime = createdAt;
          debugPrint('🔄   Updated last check time to: $_lastCheckTime');
        }
      }

      if (newNotificationCount == 0) {
        debugPrint('🔄 No NEW notifications (all were already processed or too old)');
      } else {
        debugPrint('🔄 ✅ Processed $newNotificationCount new notifications');
      }
    } catch (e, stackTrace) {
      debugPrint('🔄 ❌ Error checking notifications: $e');
      debugPrint('🔄 Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
