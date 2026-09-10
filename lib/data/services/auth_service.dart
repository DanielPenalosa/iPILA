import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'cloudinary_service.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _notifications = NotificationService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  Stream<UserModel?> userModelStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String barangay,
    File? idPhoto,
    XFile? idPhotoWeb,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(fullName);

    // Upload ID photo to Cloudinary
    String? idPhotoUrl;
    try {
      if (kIsWeb && idPhotoWeb != null) {
        idPhotoUrl = await CloudinaryService.uploadImageWeb(
          idPhotoWeb,
          folder: 'ipila/id_photos',
        );
      } else if (idPhoto != null) {
        idPhotoUrl = await CloudinaryService.uploadImage(
          idPhoto,
          folder: 'ipila/id_photos',
        );
      }
      debugPrint('ID photo URL: $idPhotoUrl');
    } catch (e) {
      debugPrint('ID photo upload failed: $e');
    }

    final user = UserModel(
      uid: credential.user!.uid,
      fullName: fullName,
      email: email,
      phone: phone,
      barangay: barangay,
      role: AppConstants.roleResident,
      idPhotoUrl: idPhotoUrl,
      approvalStatus: 'pending',
      createdAt: DateTime.now(),
      isActive: false,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .set(user.toMap());

    // Sign out immediately — they must wait for approval
    await _auth.signOut();

    // Notify all admins about the new registration
    await _notifyAdminsOfRegistration(
      fullName: fullName,
      email: email,
      barangay: barangay,
      userId: credential.user!.uid,
    );

    return user;
  }

  /// Notify all admins/superadmins that a new user registered
  Future<void> _notifyAdminsOfRegistration({
    required String fullName,
    required String email,
    required String barangay,
    required String userId,
  }) async {
    try {
      final adminsSnap = await _db
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['admin', 'superadmin'])
          .get();

      for (final adminDoc in adminsSnap.docs) {
        await _notifications.createNotification(
          userId: adminDoc.id,
          title: '👤 New Registration: $fullName',
          body:
              '$fullName ($email) from Brgy. $barangay submitted a registration request and is waiting for approval.',
          type: 'new_user_registration',
          data: {'registrantUserId': userId, 'type': 'new_user_registration'},
        );
      }
    } catch (e) {
      debugPrint('Error notifying admins of registration: $e');
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getUserModel(credential.user!.uid);
  }

  Future<void> signInCredentialOnly({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String barangay,
    File? newPhoto,
    XFile? newPhotoWeb,
  }) async {
    String? photoUrl;
    try {
      if (kIsWeb && newPhotoWeb != null) {
        photoUrl = await CloudinaryService.uploadImageWeb(
          newPhotoWeb,
          folder: 'ipila/profile_photos',
        );
      } else if (newPhoto != null) {
        photoUrl = await CloudinaryService.uploadImage(
          newPhoto,
          folder: 'ipila/profile_photos',
        );
      }
    } catch (e) {
      debugPrint('Profile photo upload failed: $e');
    }

    final updates = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'barangay': barangay,
    };
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
    await _auth.currentUser?.updateDisplayName(fullName);
  }
}
