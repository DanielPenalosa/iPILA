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
