import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/notification_popup.dart';

class NotificationListenerService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static DateTime? _lastNotificationTime;
  static bool _isInitialized = false;
  static BuildContext? _context;

  /// Start listening for new notifications for a user
  static void startListening(String userId, BuildContext context) {
    if (_isInitialized) {
      return; // Already listening
    }

    _isInitialized = true;
    _context = context;
    _lastNotificationTime = DateTime.now();

    _subscription = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      if (_context == null || !_context!.mounted) return;

      final latestNotif = snapshot.docs.first;
      final data = latestNotif.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();

      // Only show popup for notifications created after we started listening
      if (_lastNotificationTime != null &&
          createdAt.isAfter(_lastNotificationTime!)) {
        final title = data['title'] as String? ?? 'New Notification';
        final body = data['body'] as String? ?? '';
        final type = data['type'] as String? ?? 'info';
        final reportId = data['reportId'] as String?;

        // Show popup with looping sound for important notifications
        if (type == 'new_report' || type == 'assignment') {
          NotificationPopup.show(
            context: _context!,
            title: title,
            message: body,
            type: type,
            reportId: reportId,
          );
        }
      }

      _lastNotificationTime = createdAt;
    });
  }

  /// Update the context (useful when navigating)
  static void updateContext(BuildContext context) {
    _context = context;
  }

  /// Stop listening for notifications
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _lastNotificationTime = null;
    _context = null;
    NotificationPopup.dismiss();
  }
}
