import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

class BarangayService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _notifications = NotificationService();

  /// Get all reports in the barangay user's assigned barangay
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
    required String reporterUserId,
  }) async {
    final now = DateTime.now();

    final progressUpdate = ProgressUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      updatedBy: updatedByName,
      department: barangayName,
      status: status,
      remarks: remarks,
      photoUrls: [],
      timestamp: now,
    );

    final statusEntry = ReportStatus(
      status: status,
      timestamp: now,
      note: remarks,
      updatedBy: updatedByName,
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
      body: 'Brgy. $barangayName updated your report status to: $status',
      type: 'progress',
      data: {'reportId': reportId},
    );
  }

  /// Barangay submits as done
  Future<void> submitForVerification({
    required String reportId,
    required String barangayName,
    required String updatedByName,
    required String reporterUserId,
    String? remarks,
  }) async {
    final now = DateTime.now();

    final progressUpdate = ProgressUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      updatedBy: updatedByName,
      department: barangayName,
      status: AppConstants.statusDone,
      remarks: remarks,
      photoUrls: [],
      timestamp: now,
    );

    final statusEntry = ReportStatus(
      status: AppConstants.statusDone,
      timestamp: now,
      note: remarks ?? 'Marked as done, awaiting admin verification',
      updatedBy: updatedByName,
    );

    await _db.collection(AppConstants.reportsCollection).doc(reportId).update({
      'currentStatus': AppConstants.statusDone,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
      'progressUpdates': FieldValue.arrayUnion([progressUpdate.toMap()]),
    });

    await _notifications.createNotification(
      userId: reporterUserId,
      title: 'Work Completed',
      body:
          'Brgy. $barangayName has finished work on your report. Awaiting admin review.',
      type: 'info',
      data: {'reportId': reportId},
    );
  }
}
