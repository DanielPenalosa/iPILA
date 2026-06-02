import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String barangay;
  final String role; // resident, admin, superadmin
  final String? photoUrl;
  final String? idPhotoUrl;
  final String approvalStatus; // pending, approved, rejected
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.barangay,
    required this.role,
    this.photoUrl,
    this.idPhotoUrl,
    this.approvalStatus = 'pending',
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      barangay: data['barangay'] ?? '',
      role: data['role'] ?? 'resident',
      photoUrl: data['photoUrl'],
      idPhotoUrl: data['idPhotoUrl'],
      approvalStatus: data['approvalStatus'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'barangay': barangay,
    'role': role,
    'photoUrl': photoUrl,
    'idPhotoUrl': idPhotoUrl,
    'approvalStatus': approvalStatus,
    'createdAt': Timestamp.fromDate(createdAt),
    'isActive': isActive,
  };

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';
}
