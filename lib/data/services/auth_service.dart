import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'cloudinary_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    return user;
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
}
