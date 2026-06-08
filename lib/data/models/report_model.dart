import 'package:cloud_firestore/cloud_firestore.dart';

class ReportStatus {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;
  final String? adminRemarks; // Additional remarks for completion

  ReportStatus({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
    this.adminRemarks,
  });

  factory ReportStatus.fromMap(Map<String, dynamic> map) => ReportStatus(
    status: map['status'] ?? '',
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    note: map['note'],
    updatedBy: map['updatedBy'],
    adminRemarks: map['adminRemarks'],
  );

  Map<String, dynamic> toMap() => {
    'status': status,
    'timestamp': Timestamp.fromDate(timestamp),
    'note': note,
    'updatedBy': updatedBy,
    'adminRemarks': adminRemarks,
  };
}

class ReportModel {
  final String id;
  final String userId;
  final String userFullName;
  final String userBarangay;
  final String category;
  final String description;
  final String barangay;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> photoUrls;
  final String? afterPhotoUrl; // after photo for completion evidence
  final String? completionRemarks; // admin remarks when completing
  final DateTime? completedAt; // timestamp when completed
  final String currentStatus;
  final List<ReportStatus> statusHistory;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAnonymous;
  final List<String> followers; // Users tracking this report
  final int followerCount; // Number of followers/supporters
  final int priority; // Auto-calculated priority based on followers

  ReportModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userBarangay,
    required this.category,
    required this.description,
    required this.barangay,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.photoUrls,
    this.afterPhotoUrl,
    this.completionRemarks,
    this.completedAt,
    required this.currentStatus,
    required this.statusHistory,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.isAnonymous = false,
    this.followers = const [],
    this.followerCount = 0,
    this.priority = 0,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final followers = List<String>.from(data['followers'] ?? []);
    return ReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userFullName: data['userFullName'] ?? '',
      userBarangay: data['userBarangay'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      barangay: data['barangay'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      afterPhotoUrl: data['afterPhotoUrl'],
      completionRemarks: data['completionRemarks'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      currentStatus: data['currentStatus'] ?? 'Submitted',
      statusHistory: (data['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => ReportStatus.fromMap(e as Map<String, dynamic>))
          .toList(),
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      followers: followers,
      followerCount: data['followerCount'] ?? followers.length,
      priority: data['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userFullName': userFullName,
    'userBarangay': userBarangay,
    'category': category,
    'description': description,
    'barangay': barangay,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'photoUrls': photoUrls,
    'afterPhotoUrl': afterPhotoUrl,
    'completionRemarks': completionRemarks,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'currentStatus': currentStatus,
    'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
    'assignedTo': assignedTo,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isAnonymous': isAnonymous,
    'followers': followers,
    'followerCount': followerCount,
    'priority': priority,
  };

  ReportModel copyWith({
    String? currentStatus,
    List<ReportStatus>? statusHistory,
    String? afterPhotoUrl,
    String? assignedTo,
    DateTime? updatedAt,
  }) => ReportModel(
    id: id,
    userId: userId,
    userFullName: userFullName,
    userBarangay: userBarangay,
    category: category,
    description: description,
    barangay: barangay,
    latitude: latitude,
    longitude: longitude,
    address: address,
    photoUrls: photoUrls,
    afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
    currentStatus: currentStatus ?? this.currentStatus,
    statusHistory: statusHistory ?? this.statusHistory,
    assignedTo: assignedTo ?? this.assignedTo,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isAnonymous: isAnonymous,
  );
}
