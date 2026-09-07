import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive': true,
      'approvalStatus': 'approved',
    });
  }

  Future<void> rejectUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> suspendUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': false});
  }

  Future<void> reactivateUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': true});
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isActive': false,
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'approvalStatus': 'deleted',
    });
  }

  // ── Bulk actions ─────────────────────────────────────────────────────────

  Future<void> bulkApproveUsers(List<String> uids) async {
    final batch = _db.batch();
    for (final uid in uids) {
      batch.update(_db.collection('users').doc(uid), {
        'isActive': true,
        'approvalStatus': 'approved',
      });
    }
    await batch.commit();
  }

  Future<void> bulkRejectUsers(List<String> uids) async {
    final batch = _db.batch();
    for (final uid in uids) {
      batch.delete(_db.collection('users').doc(uid));
    }
    await batch.commit();
  }

  Future<void> bulkSuspendUsers(List<String> uids) async {
    final batch = _db.batch();
    for (final uid in uids) {
      batch.update(_db.collection('users').doc(uid), {'isActive': false});
    }
    await batch.commit();
  }

  Future<void> bulkReactivateUsers(List<String> uids) async {
    final batch = _db.batch();
    for (final uid in uids) {
      batch.update(_db.collection('users').doc(uid), {'isActive': true});
    }
    await batch.commit();
  }

  Future<void> bulkDeleteUsers(List<String> uids) async {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    for (final uid in uids) {
      batch.update(_db.collection('users').doc(uid), {
        'isActive': false,
        'isDeleted': true,
        'deletedAt': now,
        'approvalStatus': 'deleted',
      });
    }
    await batch.commit();
  }

  void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
