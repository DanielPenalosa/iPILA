import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class BarangayService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _notifications = NotificationService();

  /// Notify all admins/superadmins
  Future<void> _notifyAdmins({
    required String title,
    required String body,
    required String type,
    String reportId = '',
  }) async {
    try {
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['admin', 'superadmin'])
          .get();
      for (final doc in snap.docs) {
        await _notifications.createNotification(
          userId: doc.id,
          title: title,
          body: body,
          type: type,
          data: reportId.isNotEmpty ? {'reportId': reportId, 'type': type} : null,
        );
      }
    } catch (_) {}
  }

  /// Get all reports assigned to this barangay user
  Stream<List<ReportModel>> getBarangayReports(String barangayUserId) {
    return _db
        .collection(AppConstants.reportsCollection)
        .where('assignedBarangayUserId', isEqualTo: barangayUserId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ReportModel.fromFirestore).toList();
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  /// Get all barangay users
  Stream<List<UserModel>> getBarangayUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleBarangay)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  /// Create a barangay user account (admin action)
  Future<void> createBarangayUser({
    required String uid,
    required String fullName,
    required String email,
    required String barangay,
  }) async {
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: '',
      barangay: barangay,
      role: AppConstants.roleBarangay,
      department: barangay,
      approvalStatus: 'approved',
      createdAt: DateTime.now(),
      isActive: true,
    );
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toMap());
  }

  /// Assign a report to a barangay user (admin action)
  Future<void> assignToBarangay({
    required String reportId,
    required String barangayUserId,
    required String barangayName,
    required String assignedByName,
    required String reporterUserId,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusAssigned,
      timestamp: now,
      note: 'Assigned to Brgy. $barangayName',
      updatedBy: assignedByName,
      department: 'Brgy. $barangayName',
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusAssigned,
      'assignedBarangay': barangayName,
      'assignedBarangayUserId': barangayUserId,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });

    await _notifications.createNotification(
      userId: barangayUserId,
      title: 'New Report Assigned',
      body: 'A report has been assigned to Brgy. $barangayName.',
      type: 'assignment',
      data: {'reportId': reportId},
    );

    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Assigned',
      body: 'Your report has been assigned to Brgy. $barangayName for action.',
      type: 'info',
      data: {'reportId': reportId},
    );
  }

  /// Barangay adds a progress update
  Future<void> addProgressUpdate({
    required String reportId,
    required String barangayUserId,
    required String barangayName,
    required String updatedByName,
    required String status,
    String? remarks,
    List<XFile>? photosWeb,
    required String reporterUserId,
  }) async {
    final updateId = _uuid.v4();
    final now = DateTime.now();

    final photoUrls = <String>[];
    if (photosWeb != null) {
      for (final photo in photosWeb) {
        final url = await CloudinaryService.uploadImageWeb(
          photo,
          folder: 'ipila/reports/$reportId/progress',
        );
        if (url != null) photoUrls.add(url);
      }
    }

    final progressUpdate = ProgressUpdate(
      id: updateId,
      updatedBy: updatedByName,
      department: barangayName,
      status: status,
      remarks: remarks,
      photoUrls: photoUrls,
      timestamp: now,
    );

    final statusEntry = ReportStatus(
      status: status,
      timestamp: now,
      note: remarks,
      updatedBy: updatedByName,
      department: barangayName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': status,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'progressUpdates': FieldValue.arrayUnion([progressUpdate.toMap()]),
    });

    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Progress Update',
      body: '$barangayName updated your report status to: $status',
      type: 'progress',
      data: {'reportId': reportId},
    );

    await _notifyAdmins(
      title: '🏘️ Barangay Progress: $status',
      body: '$barangayName updated report status to "$status"'
          '${remarks != null && remarks.isNotEmpty ? ': $remarks' : ''}.',
      type: 'barangay_update',
      reportId: reportId,
    );
  }

  /// Barangay submits as done — awaiting admin verification
  Future<void> submitForVerification({
    required String reportId,
    required String barangayName,
    required String updatedByName,
    required String reporterUserId,
    String? remarks,
    List<XFile>? completionPhotosWeb,
  }) async {
    final now = DateTime.now();

    final photoUrls = <String>[];
    if (completionPhotosWeb != null) {
      for (final photo in completionPhotosWeb) {
        final url = await CloudinaryService.uploadImageWeb(
          photo,
          folder: 'ipila/reports/$reportId/completion',
        );
        if (url != null) photoUrls.add(url);
      }
    }

    final updateId = _uuid.v4();
    final progressUpdate = ProgressUpdate(
      id: updateId,
      updatedBy: updatedByName,
      department: barangayName,
      status: AppConstants.statusDone,
      remarks: remarks,
      photoUrls: photoUrls,
      timestamp: now,
    );

    final statusEntry = ReportStatus(
      status: AppConstants.statusDone,
      timestamp: now,
      note: remarks ?? 'Marked as done, awaiting admin verification',
      updatedBy: updatedByName,
      department: barangayName,
    );

    final updateData = <String, dynamic>{
      'currentStatus': AppConstants.statusDone,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'progressUpdates': FieldValue.arrayUnion([progressUpdate.toMap()]),
    };

    if (photoUrls.isNotEmpty) {
      updateData['pendingAfterPhotoUrl'] = photoUrls.first;
    }

    await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .update(updateData);

    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Work Completed',
      body: '$barangayName has finished work on your report. Awaiting admin review.',
      type: 'info',
      data: {'reportId': reportId},
    );

    await _notifyAdmins(
      title: '✅ Ready for Verification',
      body: '$barangayName marked a report as Done and needs your approval.'
          '${remarks != null && remarks.isNotEmpty ? ' Remarks: $remarks' : ''}',
      type: 'barangay_done',
      reportId: reportId,
    );
  }

  /// Admin approves — marks as Resolved
  Future<void> approveResolution({
    required String reportId,
    required String adminName,
    required String reporterUserId,
    required String? barangayUserId,
    String? remarks,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusResolved,
      timestamp: now,
      note: remarks ?? 'Verified and resolved by admin.',
      updatedBy: adminName,
    );

    final reportDoc = await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .get();
    final pendingPhoto = reportDoc.data()?['pendingAfterPhotoUrl'] as String?;

    final updateData = <String, dynamic>{
      'currentStatus': AppConstants.statusResolved,
      'completedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'pendingAfterPhotoUrl': FieldValue.delete(),
    };

    if (remarks != null && remarks.isNotEmpty) {
      updateData['completionRemarks'] = remarks;
    }
    if (pendingPhoto != null) {
      updateData['afterPhotoUrl'] = pendingPhoto;
    }

    await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .update(updateData);

    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Resolved ✓',
      body: 'Your report has been officially resolved. Thank you for helping improve our community!',
      type: 'success',
      data: {'reportId': reportId},
    );

    if (barangayUserId != null) {
      await _notifications.createNotification(
        userId: barangayUserId,
        title: 'Report Approved & Resolved',
        body: 'Admin has verified and resolved the report.',
        type: 'success',
        data: {'reportId': reportId},
      );
    }
  }

  /// Admin returns for revision
  Future<void> returnForRevision({
    required String reportId,
    required String adminName,
    required String? barangayUserId,
    required String reporterUserId,
    required String remarks,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusNeedsRevision,
      timestamp: now,
      note: remarks,
      updatedBy: adminName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusNeedsRevision,
      'adminVerificationRemarks': remarks,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });

    if (barangayUserId != null) {
      await _notifications.createNotification(
        userId: barangayUserId,
        title: 'Report Needs Revision',
        body: 'Admin returned a report for further action. Remarks: $remarks',
        type: 'warning',
        data: {'reportId': reportId},
      );
    }
  }
}
