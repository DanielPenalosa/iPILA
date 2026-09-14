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
  static Set<String> _processedNotificationIds = {};
  static GlobalKey<NavigatorState>? _globalNavigatorKey;

  /// Set the global navigator key for reliable context access
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _globalNavigatorKey = key;
    debugPrint('🔔 Global navigator key set');
  }

  /// Start listening for new notifications for a user
  static void startListening(String userId, BuildContext context) {
    // If already listening for this user, don't restart
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('🔔 Already listening for user: $userId');
      return;
    }

    // Stop any existing listener
    stopListening();

    _isInitialized = true;
    _currentUserId = userId;
    _lastNotificationTime = DateTime.now();
    _processedNotificationIds.clear();

    debugPrint('🔔 ===== STARTING NOTIFICATION LISTENER =====');
    debugPrint('🔔 User ID: $userId');
    debugPrint('🔔 Started at: $_lastNotificationTime');

    _subscription = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(5) // Check last 5 notifications
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔔 ----- Notification snapshot received -----');
      debugPrint('🔔 Number of notifications: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('🔔 No notifications found for this user yet');
        return;
      }

      // Process all recent notifications
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final notifId = doc.id;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final title = data['title'] as String? ?? 'New Notification';
        final body = data['body'] as String? ?? '';
        final type = data['type'] as String? ?? 'info';
        final reportId = data['reportId'] as String?;

        debugPrint('🔔 Processing notification:');
        debugPrint('🔔   ID: $notifId');
        debugPrint('🔔   Title: $title');
        debugPrint('🔔   Type: $type');
        debugPrint('🔔   Created: $createdAt');
        debugPrint('🔔   Last check: $_lastNotificationTime');

        // Skip if already processed
        if (_processedNotificationIds.contains(notifId)) {
          debugPrint('🔔   ⏭️  Already processed, skipping');
          continue;
        }

        // Check if this is a new notification
        final isNew = _lastNotificationTime != null &&
            createdAt.isAfter(_lastNotificationTime!);

        if (isNew) {
          debugPrint('🔔   🆕 NEW NOTIFICATION DETECTED!');
          debugPrint('🔔   Will show popup: ${type == 'new_report' || type == 'assignment'}');

          // Mark as processed
          _processedNotificationIds.add(notifId);

          // Show popup for important notifications
          if (type == 'new_report' || type == 'assignment') {
            debugPrint('🔔   📢 Triggering popup...');
            
            // Use post frame callback to ensure overlay is ready
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('🔔   🎯 Post-frame callback executing...');
              
              // Get the root navigator context which is always available
              final navigatorKey = _globalNavigatorKey;
              if (navigatorKey != null && navigatorKey.currentContext != null) {
                final rootContext = navigatorKey.currentContext!;
                debugPrint('🔔   ✅ Using global navigator context');
                debugPrint('🔔   🚀 Showing popup NOW!');
                
                NotificationPopup.show(
                  context: rootContext,
                  title: title,
                  message: body,
                  type: type,
                  reportId: reportId,
                );
              } else {
                debugPrint('🔔   ⚠️  Global navigator key not set, trying provided context...');
                
                // Fallback to provided context
                if (context.mounted) {
                  debugPrint('🔔   ✅ Using provided context as fallback');
                  NotificationPopup.show(
                    context: context,
                    title: title,
                    message: body,
                    type: type,
                    reportId: reportId,
                  );
                } else {
                  debugPrint('🔔   ❌ ERROR: No valid context available!');
                }
              }
            });
          } else {
            debugPrint('🔔   ℹ️  Not an important notification type, skipping popup');
          }
        } else {
          debugPrint('🔔   ⏰ Old notification (before listener started), skipping');
        }
      }

      // Update last check time to most recent notification
      if (snapshot.docs.isNotEmpty) {
        final mostRecent = (snapshot.docs.first.data()['createdAt'] as Timestamp).toDate();
        if (_lastNotificationTime == null || mostRecent.isAfter(_lastNotificationTime!)) {
          _lastNotificationTime = mostRecent;
          debugPrint('🔔 Updated last notification time to: $_lastNotificationTime');
        }
      }
    }, onError: (error) {
      debugPrint('🔔 ❌ ERROR in notification listener: $error');
    });

    debugPrint('🔔 ===== LISTENER SETUP COMPLETE =====');
  }

  /// Stop listening for notifications
  static void stopListening() {
    debugPrint('🔔 🛑 Stopping notification listener');
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _lastNotificationTime = null;
    _currentUserId = null;
    _processedNotificationIds.clear();
    NotificationPopup.dismiss();
  }
}
