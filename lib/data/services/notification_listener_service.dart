import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/notification_popup.dart';

class NotificationListenerService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static DateTime? _lastNotificationTime;
  static bool _isInitialized = false;
  static String? _currentUserId;

  /// Start listening for new notifications for a user
  static void startListening(String userId, BuildContext context) {
    // If already listening for this user, don't restart
    if (_isInitialized && _currentUserId == userId) {
      return;
    }

    // Stop any existing listener
    stopListening();

    _isInitialized = true;
    _currentUserId = userId;
    _lastNotificationTime = DateTime.now();

    debugPrint('🔔 Starting notification listener for user: $userId');

    _subscription = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        debugPrint('🔔 No notifications found');
        return;
      }

      final latestNotif = snapshot.docs.first;
      final data = latestNotif.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final title = data['title'] as String? ?? 'New Notification';
      final body = data['body'] as String? ?? '';
      final type = data['type'] as String? ?? 'info';
      final reportId = data['reportId'] as String?;

      debugPrint('🔔 Latest notification: $title (type: $type) at $createdAt');
      debugPrint('🔔 Last notification time: $_lastNotificationTime');

      // Only show popup for notifications created after we started listening
      if (_lastNotificationTime != null &&
          createdAt.isAfter(_lastNotificationTime!)) {
        debugPrint('🔔 NEW NOTIFICATION DETECTED! Showing popup...');

        // Show popup with looping sound for important notifications
        if (type == 'new_report' || type == 'assignment') {
          // Use post frame callback to ensure context is valid
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigatorContext = Navigator.maybeOf(context)?.context;
            if (navigatorContext != null && navigatorContext.mounted) {
              NotificationPopup.show(
                context: navigatorContext,
                title: title,
                message: body,
                type: type,
                reportId: reportId,
              );
            } else {
              debugPrint('🔔 Context not available for popup');
            }
          });
        }
      } else {
        debugPrint('🔔 Old notification, skipping popup');
      }

      _lastNotificationTime = createdAt;
    }, onError: (error) {
      debugPrint('🔔 Error in notification listener: $error');
    });
  }

  /// Stop listening for notifications
  static void stopListening() {
    debugPrint('🔔 Stopping notification listener');
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _lastNotificationTime = null;
    _currentUserId = null;
    NotificationPopup.dismiss();
  }
}
