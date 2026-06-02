import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a notification for a specific user about their report update
  Future<void> createReportNotification({
    required String userId,
    required String reportId,
    required String title,
    required String body,
    String type = 'info',
  }) async {
    final notificationId = _uuid.v4();

    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .set({
          'id': notificationId,
          'userId': userId,
          'reportId': reportId,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  /// Create a broadcast notification for all users
  Future<void> createBroadcastNotification({
    required String title,
    required String body,
    String type = 'info',
  }) async {
    final notificationId = _uuid.v4();

    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .set({
          'id': notificationId,
          'title': title,
          'body': body,
          'type': type,
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Get unread count for a user
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// Create a generic notification with custom data
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    final notificationId = _uuid.v4();

    final notificationData = <String, Object>{
      'id': notificationId,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };

    if (data != null) {
      data.forEach((key, value) {
        if (value != null) {
          notificationData[key] = value;
        }
      });
    }

    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .set(notificationData);
  }
}
