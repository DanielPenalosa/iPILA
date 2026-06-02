import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } else {
      // If we're already handling sign-in manually (status == loading),
      // skip — signIn() will set the final status to avoid race conditions.
      if (_status == AuthStatus.loading) return;
      _status = AuthStatus.loading;
      notifyListeners();
      _user = await _authService.getUserModel(firebaseUser.uid);
      debugPrint(
        '=== AUTH DEBUG === Role: ${_user?.role} Approval: ${_user?.approvalStatus}',
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      // Sign in first, then fetch user model to check approval
      await _authService.signInCredentialOnly(email: email, password: password);
      final currentUid = _authService.currentUser?.uid;
      if (currentUid != null) {
        final tempUser = await _authService.getUserModel(currentUid);
        if (tempUser != null && !tempUser.isAdmin) {
          if (tempUser.isPending) {
            await _authService.signOut();
            _errorMessage =
                'Your account is pending admin approval. Please wait.';
            _status = AuthStatus.error;
            notifyListeners();
            return false;
          }
          if (tempUser.isRejected) {
            await _authService.signOut();
            _errorMessage =
                'Your registration was rejected. Please contact the LGU office.';
            _status = AuthStatus.error;
            notifyListeners();
            return false;
          }
          if (!tempUser.isActive) {
            await _authService.signOut();
            _errorMessage =
                'Your account has been suspended. Please contact the LGU office.';
            _status = AuthStatus.error;
            notifyListeners();
            return false;
          }
        }
        // Approved — set user and status directly
        _user = tempUser;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String barangay,
    File? idPhoto,
    XFile? idPhotoWeb,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        barangay: barangay,
        idPhoto: idPhoto,
        idPhotoWeb: idPhotoWeb,
      );
      // Don't authenticate — account is pending approval
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Waits until status is no longer loading/initial
  Future<void> waitForUser() async {
    if (_status != AuthStatus.loading && _status != AuthStatus.initial) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return _status == AuthStatus.loading || _status == AuthStatus.initial;
    });
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled. Enable it in Firebase Console → Authentication.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Error: $code. Please try again.';
    }
  }
}
