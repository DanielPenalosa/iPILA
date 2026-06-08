import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../../core/constants/app_constants.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _notificationService = NotificationService();

  // Submit a new report
  Future<String> submitReport({
    required String userId,
    required String userFullName,
    required String userBarangay,
    required String category,
    required String description,
    required String barangay,
    required double latitude,
    required double longitude,
    required String address,
    List<File>? photos,
    List<XFile>? photosWeb,
    bool isAnonymous = false,
  }) async {
    final reportId = _uuid.v4();

    // Upload photos to Cloudinary
    final photoUrls = <String>[];

    if (kIsWeb && photosWeb != null) {
      for (final photo in photosWeb) {
        final url = await CloudinaryService.uploadImageWeb(
          photo,
          folder: 'ipila/reports/$reportId',
        );
        if (url != null) photoUrls.add(url);
      }
    } else if (photos != null) {
      for (final photo in photos) {
        final url = await CloudinaryService.uploadImage(
          photo,
          folder: 'ipila/reports/$reportId',
        );
        if (url != null) photoUrls.add(url);
      }
    }

    final now = DateTime.now();
    final report = ReportModel(
      id: reportId,
      userId: userId,
      userFullName: isAnonymous ? 'Anonymous' : userFullName,
      userBarangay: userBarangay,
      category: category,
      description: description,
      barangay: barangay,
      latitude: latitude,
      longitude: longitude,
      address: address,
      photoUrls: photoUrls,
      currentStatus: AppConstants.statusSubmitted,
      statusHistory: [
        ReportStatus(
          status: AppConstants.statusSubmitted,
          timestamp: now,
          note: 'Report submitted by citizen.',
        ),
      ],
      createdAt: now,
      updatedAt: now,
      isAnonymous: isAnonymous,
    );

    await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .set(report.toMap());

    return reportId;
  }

  // Update report status (admin) with completion validation
  Future<Map<String, dynamic>> updateStatus({
    required String reportId,
    required String newStatus,
    required String updatedBy,
    String? note,
    String? adminRemarks,
    File? afterPhoto,
    XFile? afterPhotoWeb,
  }) async {
    // Get the report first to validate and get data
    final reportDoc = await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .get();

    if (!reportDoc.exists) {
      return {'success': false, 'error': 'Report not found'};
    }

    final reportData = reportDoc.data()!;
    final userId = reportData['userId'] as String;
    final category = reportData['category'] as String? ?? 'Report';
    final photoUrls = List<String>.from(reportData['photoUrls'] ?? []);

    // VALIDATION: For completion status, require after photo and before photo exists
    if (newStatus == AppConstants.statusCompleted) {
      if (photoUrls.isEmpty) {
        return {
          'success': false,
          'error': 'Cannot complete: No before photo exists for this report',
        };
      }

      if (afterPhoto == null && afterPhotoWeb == null) {
        return {
          'success': false,
          'error':
              'Cannot complete: After photo is required to mark report as completed',
        };
      }
    }

    // Upload after photo if provided
    String? afterPhotoUrl;
    if (afterPhoto != null || afterPhotoWeb != null) {
      if (kIsWeb && afterPhotoWeb != null) {
        afterPhotoUrl = await CloudinaryService.uploadImageWeb(
          afterPhotoWeb,
          folder: 'ipila/reports/$reportId/completion',
        );
      } else if (afterPhoto != null) {
        afterPhotoUrl = await CloudinaryService.uploadImage(
          afterPhoto,
          folder: 'ipila/reports/$reportId/completion',
        );
      }
    }

    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: newStatus,
      timestamp: now,
      note: note,
      updatedBy: updatedBy,
      adminRemarks: adminRemarks,
    );

    final updateData = <String, dynamic>{
      'currentStatus': newStatus,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    };

    // Add completion-specific data
    if (newStatus == AppConstants.statusCompleted) {
      if (afterPhotoUrl != null) {
        updateData['afterPhotoUrl'] = afterPhotoUrl;
      }
      if (adminRemarks != null && adminRemarks.isNotEmpty) {
        updateData['completionRemarks'] = adminRemarks;
      }
      updateData['completedAt'] = Timestamp.fromDate(now);
    }

    await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .update(updateData);

    // Send notification to user
    String notificationTitle;
    String notificationBody;
    String notificationType;

    switch (newStatus) {
      case 'Under Review':
        notificationTitle = 'Report Under Review';
        notificationBody =
            'Your $category report is now being reviewed by our team.';
        notificationType = 'info';
        break;
      case 'In Progress':
        notificationTitle = 'Work Started';
        notificationBody = 'We\'ve started working on your $category report.';
        notificationType = 'info';
        break;
      case 'Completed':
        notificationTitle = 'Report Completed! ✓';
        notificationBody =
            'Great news! Your $category report has been resolved. Check the before & after photos to see the improvement. Thank you for helping our community!';
        notificationType = 'success';
        break;
      case 'Rejected':
        notificationTitle = 'Report Update';
        notificationBody = 'Your $category report status has been updated.';
        notificationType = 'warning';
        break;
      default:
        notificationTitle = 'Report Updated';
        notificationBody = 'Your $category report status: $newStatus';
        notificationType = 'info';
    }

    if (note != null && note.isNotEmpty) {
      notificationBody += '\n\nNote: $note';
    }

    if (newStatus == AppConstants.statusCompleted &&
        adminRemarks != null &&
        adminRemarks.isNotEmpty) {
      notificationBody += '\n\nAdmin remarks: $adminRemarks';
    }

    await _notificationService.createReportNotification(
      userId: userId,
      reportId: reportId,
      title: notificationTitle,
      body: notificationBody,
      type: notificationType,
    );

    // Also notify all followers about completion
    if (newStatus == AppConstants.statusCompleted) {
      final followers = List<String>.from(reportData['followers'] ?? []);
      for (final followerId in followers) {
        if (followerId != userId) {
          // Don't duplicate for the original reporter
          await _notificationService.createReportNotification(
            userId: followerId,
            reportId: reportId,
            title: 'Followed Report Completed',
            body:
                'A $category report you were following in ${reportData['barangay']} has been completed. Check out the results!',
            type: 'success',
          );
        }
      }
    }

    return {'success': true, 'afterPhotoUrl': afterPhotoUrl};
  }

  // Assign report to staff
  Future<void> assignReport(String reportId, String staffName) async {
    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'assignedTo': staffName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get reports for a specific user
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _db
        .collection(AppConstants.reportsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ReportModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get all reports (admin)
  Stream<List<ReportModel>> getAllReports({
    String? statusFilter,
    String? barangayFilter,
  }) {
    // Use simple queries without orderBy to avoid composite index requirements
    // Sort client-side instead
    Query query = _db.collection(AppConstants.reportsCollection);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('currentStatus', isEqualTo: statusFilter);
    } else if (barangayFilter != null && barangayFilter.isNotEmpty) {
      query = query.where('barangay', isEqualTo: barangayFilter);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(ReportModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Apply barangay filter client-side when status filter is also active
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          barangayFilter != null &&
          barangayFilter.isNotEmpty) {
        return list.where((r) => r.barangay == barangayFilter).toList();
      }
      return list;
    });
  }

  // Get single report
  Stream<ReportModel?> getReport(String reportId) {
    return _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .snapshots()
        .map((doc) => doc.exists ? ReportModel.fromFirestore(doc) : null);
  }

  // Analytics: count by barangay
  Future<Map<String, int>> getReportCountByBarangay() async {
    final snap = await _db.collection(AppConstants.reportsCollection).get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final barangay = doc.data()['barangay'] as String? ?? 'Unknown';
      counts[barangay] = (counts[barangay] ?? 0) + 1;
    }
    return counts;
  }

  // Analytics: count by category
  Future<Map<String, int>> getReportCountByCategory() async {
    final snap = await _db.collection(AppConstants.reportsCollection).get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final cat = doc.data()['category'] as String? ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  // Analytics: count by status
  Future<Map<String, int>> getReportCountByStatus() async {
    final snap = await _db.collection(AppConstants.reportsCollection).get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final status = doc.data()['currentStatus'] as String? ?? 'Submitted';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  // Get all community reports (for homepage visibility)
  Stream<List<ReportModel>> getCommunityReports({
    String? categoryFilter,
    String? statusFilter,
    String? barangayFilter,
  }) {
    Query query = _db.collection(AppConstants.reportsCollection);

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('category', isEqualTo: categoryFilter);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('currentStatus', isEqualTo: statusFilter);
    }
    if (barangayFilter != null && barangayFilter.isNotEmpty) {
      query = query.where('barangay', isEqualTo: barangayFilter);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(ReportModel.fromFirestore).toList();
      // Sort by priority (descending) then by date (descending)
      list.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  // Get reports with high follower count (follow-ups)
  Stream<List<ReportModel>> getFollowUpReports({int minFollowers = 2}) {
    return _db
        .collection(AppConstants.reportsCollection)
        .where('followerCount', isGreaterThanOrEqualTo: minFollowers)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ReportModel.fromFirestore).toList();
          // Sort by follower count (descending) then by date (descending)
          list.sort((a, b) {
            final followerCompare = b.followerCount.compareTo(a.followerCount);
            if (followerCompare != 0) return followerCompare;
            return b.createdAt.compareTo(a.createdAt);
          });
          return list;
        });
  }

  // Find similar reports for duplicate detection
  Future<List<ReportModel>> findSimilarReports({
    required String category,
    required String barangay,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    // Query reports with same category and barangay
    final snap = await _db
        .collection(AppConstants.reportsCollection)
        .where('category', isEqualTo: category)
        .where('barangay', isEqualTo: barangay)
        .where(
          'currentStatus',
          whereIn: [
            AppConstants.statusSubmitted,
            AppConstants.statusSeen,
            AppConstants.statusValidated,
            AppConstants.statusQueued,
            AppConstants.statusInProgress,
          ],
        )
        .get();

    final reports = snap.docs.map(ReportModel.fromFirestore).toList();
    final similar = <ReportModel>[];

    for (final report in reports) {
      // Check description similarity (simple keyword matching)
      final descWords = description.toLowerCase().split(' ');
      final reportWords = report.description.toLowerCase().split(' ');
      final commonWords = descWords
          .where((w) => reportWords.contains(w))
          .length;
      final similarity = commonWords / descWords.length;

      // Check location proximity (within ~100 meters)
      bool isNearby = false;
      if (latitude != null && longitude != null) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          report.latitude,
          report.longitude,
        );
        isNearby = distance < 100; // 100 meters
      }

      // Consider it similar if description similarity > 40% or location is nearby
      if (similarity > 0.4 || isNearby) {
        similar.add(report);
      }
    }

    return similar;
  }

  // Add follower to a report
  Future<void> followReport(String reportId, String userId) async {
    final reportRef = _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final followers = List<String>.from(data['followers'] ?? []);

      if (!followers.contains(userId)) {
        followers.add(userId);
        final newCount = followers.length;
        final newPriority = _calculatePriority(newCount);

        transaction.update(reportRef, {
          'followers': followers,
          'followerCount': newCount,
          'priority': newPriority,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });

    // Notify admin about new follower
    await _notifyAdminAboutFollower(reportId, userId);
  }

  // Remove follower from a report
  Future<void> unfollowReport(String reportId, String userId) async {
    final reportRef = _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final followers = List<String>.from(data['followers'] ?? []);

      if (followers.contains(userId)) {
        followers.remove(userId);
        final newCount = followers.length;
        final newPriority = _calculatePriority(newCount);

        transaction.update(reportRef, {
          'followers': followers,
          'followerCount': newCount,
          'priority': newPriority,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  // Calculate priority based on follower count
  int _calculatePriority(int followerCount) {
    if (followerCount >= 20) return 5; // Critical
    if (followerCount >= 10) return 4; // High
    if (followerCount >= 5) return 3; // Medium
    if (followerCount >= 2) return 2; // Low
    return 1; // Normal
  }

  // Notify admin about new follower
  Future<void> _notifyAdminAboutFollower(String reportId, String userId) async {
    try {
      final reportDoc = await _db
          .collection(AppConstants.reportsCollection)
          .doc(reportId)
          .get();

      if (!reportDoc.exists) return;

      final reportData = reportDoc.data()!;
      final followerCount = reportData['followerCount'] ?? 0;
      final category = reportData['category'] ?? 'Report';
      final barangay = reportData['barangay'] ?? 'Unknown';
      final description = reportData['description'] ?? '';
      final shortDesc = description.length > 50
          ? '${description.substring(0, 50)}...'
          : description;

      // Get user info for personalized notification
      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      final userName = userDoc.exists
          ? (userDoc.data()?['fullName'] ?? 'A citizen')
          : 'A citizen';

      // Get all admin users
      final adminsSnap = await _db
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['admin', 'superadmin'])
          .get();

      // Create appropriate notification based on follower count
      String title;
      String body;
      String notificationType;

      if (followerCount == 1) {
        title = 'New Report Follow-Up';
        body =
            '$userName is following up on a $category report in Brgy. $barangay. "$shortDesc"';
        notificationType = 'info';
      } else if (followerCount >= 5) {
        title = 'High Priority Report';
        body =
            '$category report now has $followerCount citizens following. This issue needs attention! Brgy. $barangay: "$shortDesc"';
        notificationType = 'warning';
      } else {
        title = 'Report Follow-Up';
        body =
            '$followerCount citizens are now following this $category report in Brgy. $barangay. Consider prioritizing.';
        notificationType = 'info';
      }

      for (final adminDoc in adminsSnap.docs) {
        await _notificationService.createNotification(
          userId: adminDoc.id,
          title: title,
          body: body,
          type: notificationType,
          data: {
            'reportId': reportId,
            'type': 'report_follow_up',
            'followerCount': followerCount.toString(),
          },
        );
      }
    } catch (e) {
      // Silent fail - notification is not critical
      debugPrint('Error notifying admin about follower: $e');
    }
  }
}
