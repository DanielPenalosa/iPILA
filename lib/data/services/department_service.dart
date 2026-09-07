import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class DepartmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _notifications = NotificationService();

  /// Assign a report to a department user (admin action)
  Future<void> assignToDepartment({
    required String reportId,
    required String departmentUserId,
    required String departmentName,
    required String assignedByName,
    required String reporterUserId,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusAssigned,
      timestamp: now,
      note: 'Assigned to $departmentName',
      updatedBy: assignedByName,
      department: departmentName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusAssigned,
      'assignedDepartment': departmentName,
      'assignedDepartmentUserId': departmentUserId,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });

    // Notify the department user
    await _notifications.createNotification(
      userId: departmentUserId,
      title: 'New Report Assigned',
      body: 'A report has been assigned to your department: $departmentName',
      type: 'assignment',
      data: {'reportId': reportId},
    );

    // Notify the reporter
    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Assigned',
      body: 'Your report has been assigned to $departmentName for action.',
      type: 'info',
      data: {'reportId': reportId},
    );
  }

  /// Department adds a progress update
  Future<void> addProgressUpdate({
    required String reportId,
    required String departmentUserId,
    required String departmentName,
    required String updatedByName,
    required String status,
    String? remarks,
    List<XFile>? photosWeb,
    required String reporterUserId,
  }) async {
    final updateId = _uuid.v4();
    final now = DateTime.now();

    // Upload progress photos
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
      department: departmentName,
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
      department: departmentName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': status,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'progressUpdates': FieldValue.arrayUnion([progressUpdate.toMap()]),
    });

    // Notify reporter on every progress update
    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Progress Update',
      body: '$departmentName updated your report status to: $status',
      type: 'progress',
      data: {'reportId': reportId},
    );
  }

  /// Department submits for admin verification
  Future<void> submitForVerification({
    required String reportId,
    required String departmentName,
    required String updatedByName,
    required String reporterUserId,
    String? remarks,
    List<XFile>? completionPhotosWeb,
  }) async {
    final now = DateTime.now();

    // Upload completion photos
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
      department: departmentName,
      status: AppConstants.statusForVerification,
      remarks: remarks,
      photoUrls: photoUrls,
      timestamp: now,
    );

    final statusEntry = ReportStatus(
      status: AppConstants.statusForVerification,
      timestamp: now,
      note: remarks ?? 'Submitted for admin verification',
      updatedBy: updatedByName,
      department: departmentName,
    );

    final updateData = <String, dynamic>{
      'currentStatus': AppConstants.statusForVerification,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'progressUpdates': FieldValue.arrayUnion([progressUpdate.toMap()]),
    };

    if (photoUrls.isNotEmpty) {
      updateData['afterPhotoUrl'] = photoUrls.first;
    }

    await _db
        .collection(AppConstants.reportsCollection)
        .doc(reportId)
        .update(updateData);

    // Notify reporter
    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Under Verification',
      body:
          '$departmentName has completed action on your report. Awaiting admin verification.',
      type: 'info',
      data: {'reportId': reportId},
    );
  }

  /// Admin approves — marks as Resolved
  Future<void> approveResolution({
    required String reportId,
    required String adminName,
    required String reporterUserId,
    required String? departmentUserId,
    String? remarks,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusResolved,
      timestamp: now,
      note: remarks ?? 'Verified and resolved by admin.',
      updatedBy: adminName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusResolved,
      'completedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });

    // Notify reporter
    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Report Resolved ✓',
      body:
          'Your report has been officially resolved. Thank you for helping improve our community!',
      type: 'success',
      data: {'reportId': reportId},
    );

    // Notify department
    if (departmentUserId != null) {
      await _notifications.createNotification(
        userId: departmentUserId,
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
    required String? departmentUserId,
    required String reporterUserId,
    required String remarks,
  }) async {
    final now = DateTime.now();
    final statusEntry = ReportStatus(
      status: AppConstants.statusRevisionRequired,
      timestamp: now,
      note: remarks,
      updatedBy: adminName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusRevisionRequired,
      'adminVerificationRemarks': remarks,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });

    // Notify department
    if (departmentUserId != null) {
      await _notifications.createNotification(
        userId: departmentUserId,
        title: 'Report Returned for Revision',
        body:
            'Admin has returned a report for further action. Remarks: $remarks',
        type: 'warning',
        data: {'reportId': reportId},
      );
    }
  }

  /// Get reports assigned to a specific department user
  Stream<List<ReportModel>> getDepartmentReports(String departmentUserId) {
    return _db
        .collection(AppConstants.reportsCollection)
        .where('assignedDepartmentUserId', isEqualTo: departmentUserId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ReportModel.fromFirestore).toList();
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  /// Get all department users
  Stream<List<UserModel>> getDepartmentUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleDepartment)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  /// Create a department user account (admin action)
  Future<void> createDepartmentUser({
    required String uid,
    required String fullName,
    required String email,
    required String department,
  }) async {
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: '',
      barangay: '',
      role: AppConstants.roleDepartment,
      department: department,
      approvalStatus: 'approved',
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toMap());
  }

  /// Analytics per department
  Future<Map<String, Map<String, int>>> getDepartmentAnalytics() async {
    final snap = await _db.collection(AppConstants.reportsCollection).get();
    final result = <String, Map<String, int>>{};

    for (final doc in snap.docs) {
      final dept = doc.data()['assignedDepartment'] as String?;
      if (dept == null) continue;
      result.putIfAbsent(
        dept,
        () => {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0},
      );
      result[dept]!['total'] = result[dept]!['total']! + 1;
      final status = doc.data()['currentStatus'] as String? ?? '';
      if (status == AppConstants.statusAssigned ||
          status == AppConstants.statusRevisionRequired) {
        result[dept]!['pending'] = result[dept]!['pending']! + 1;
      } else if (status == AppConstants.statusInProgress ||
          status == AppConstants.statusForVerification) {
        result[dept]!['inProgress'] = result[dept]!['inProgress']! + 1;
      } else if (status == AppConstants.statusResolved) {
        result[dept]!['resolved'] = result[dept]!['resolved']! + 1;
      }
    }

    return result;
  }
}
