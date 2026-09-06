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
    // Mark account as deleted instead of removing document
    // This prevents the user from logging in
    // Note: The Firebase Auth account will still exist but won't be able to access the app
    await _db.collection('users').doc(uid).update({
      'isActive': false,
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'approvalStatus': 'deleted',
    });
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
