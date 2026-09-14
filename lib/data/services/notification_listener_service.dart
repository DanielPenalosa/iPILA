import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import 'sound_service.dart';

class NotificationListenerService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static DateTime? _lastNotificationTime;
  static bool _isInitialized = false;

  /// Start listening for new notifications for a user
  static void startListening(String userId) {
    if (_isInitialized) {
      return; // Already listening
    }

    _isInitialized = true;
    _lastNotificationTime = DateTime.now();

    _subscription = FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final latestNotif = snapshot.docs.first;
      final data = latestNotif.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();

      // Only play sound for notifications created after we started listening
      if (_lastNotificationTime != null &&
          createdAt.isAfter(_lastNotificationTime!)) {
        // Play sound for new notifications
        SoundService.playNotificationSound();
      }

      _lastNotificationTime = createdAt;
    });
  }

  /// Stop listening for notifications
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    _lastNotificationTime = null;
  }
}
