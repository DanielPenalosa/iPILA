import 'package:cloud_firestore/cloud_firestore.dart';

class ReportStatus {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;
  final String? adminRemarks;
  final String? department; // which department performed this action

  ReportStatus({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
    this.adminRemarks,
    this.department,
  });

  factory ReportStatus.fromMap(Map<String, dynamic> map) => ReportStatus(
    status: map['status'] ?? '',
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    note: map['note'],
    updatedBy: map['updatedBy'],
    adminRemarks: map['adminRemarks'],
    department: map['department'],
  );

  Map<String, dynamic> toMap() => {
    'status': status,
    'timestamp': Timestamp.fromDate(timestamp),
    'note': note,
    'updatedBy': updatedBy,
    'adminRemarks': adminRemarks,
    'department': department,
  };
}

class ProgressUpdate {
  final String id;
  final String updatedBy;
  final String department;
  final String status;
  final String? remarks;
  final List<String> photoUrls;
  final DateTime timestamp;

  ProgressUpdate({
    required this.id,
    required this.updatedBy,
    required this.department,
    required this.status,
    this.remarks,
    this.photoUrls = const [],
    required this.timestamp,
  });

  factory ProgressUpdate.fromMap(Map<String, dynamic> map) => ProgressUpdate(
    id: map['id'] ?? '',
    updatedBy: map['updatedBy'] ?? '',
    department: map['department'] ?? '',
    status: map['status'] ?? '',
    remarks: map['remarks'],
    photoUrls: List<String>.from(map['photoUrls'] ?? []),
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'updatedBy': updatedBy,
    'department': department,
    'status': status,
    'remarks': remarks,
    'photoUrls': photoUrls,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class ReportFeedback {
  final String id;
  final String userId;
  final String userFullName;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;

  ReportFeedback({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReportFeedback.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportFeedback(
      id: doc.id,
      userId: d['userId'] ?? '',
      userFullName: d['userFullName'] ?? '',
      rating: (d['rating'] ?? 0) as int,
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userFullName': userFullName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
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
  final String?
  afterPhotoUrl; // after photo for completion evidence — only set after admin approves
  final String?
  pendingAfterPhotoUrl; // dept submitted completion photo, pending admin review
  final String? completionRemarks; // admin remarks when completing
  final DateTime? completedAt; // timestamp when completed
  final String currentStatus;
  final List<ReportStatus> statusHistory;
  final String? assignedTo;
  final String? assignedDepartment; // department name
  final String? assignedDepartmentUserId; // dept user uid
  final String? adminVerificationRemarks; // when returning for revision
  final List<ProgressUpdate> progressUpdates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAnonymous;
  final List<String> followers; // Users tracking this report
  final int followerCount; // Number of followers/supporters
  final int priority; // Auto-calculated priority based on followers
  final String? urgencyLevel; // Manual urgency: 'High', 'Medium', 'Low'

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
    this.pendingAfterPhotoUrl,
    this.completionRemarks,
    this.completedAt,
    required this.currentStatus,
    required this.statusHistory,
    this.assignedTo,
    this.assignedDepartment,
    this.assignedDepartmentUserId,
    this.adminVerificationRemarks,
    this.progressUpdates = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isAnonymous = false,
    this.followers = const [],
    this.followerCount = 0,
    this.priority = 0,
    this.urgencyLevel,
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
      pendingAfterPhotoUrl: data['pendingAfterPhotoUrl'],
      completionRemarks: data['completionRemarks'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      currentStatus: data['currentStatus'] ?? 'Submitted',
      statusHistory: (data['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => ReportStatus.fromMap(e as Map<String, dynamic>))
          .toList(),
      assignedTo: data['assignedTo'],
      assignedDepartment: data['assignedDepartment'],
      assignedDepartmentUserId: data['assignedDepartmentUserId'],
      adminVerificationRemarks: data['adminVerificationRemarks'],
      progressUpdates: (data['progressUpdates'] as List<dynamic>? ?? [])
          .map((e) => ProgressUpdate.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      followers: followers,
      followerCount: data['followerCount'] ?? followers.length,
      priority: data['priority'] ?? 0,
      urgencyLevel: data['urgencyLevel'],
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
    'pendingAfterPhotoUrl': pendingAfterPhotoUrl,
    'completionRemarks': completionRemarks,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'currentStatus': currentStatus,
    'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
    'assignedTo': assignedTo,
    'assignedDepartment': assignedDepartment,
    'assignedDepartmentUserId': assignedDepartmentUserId,
    'adminVerificationRemarks': adminVerificationRemarks,
    'progressUpdates': progressUpdates.map((p) => p.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isAnonymous': isAnonymous,
    'followers': followers,
    'followerCount': followerCount,
    'priority': priority,
    'urgencyLevel': urgencyLevel,
  };

  ReportModel copyWith({
    String? currentStatus,
    List<ReportStatus>? statusHistory,
    String? afterPhotoUrl,
    String? pendingAfterPhotoUrl,
    String? assignedTo,
    String? assignedDepartment,
    String? assignedDepartmentUserId,
    String? adminVerificationRemarks,
    List<ProgressUpdate>? progressUpdates,
    DateTime? updatedAt,
    String? urgencyLevel,
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
    pendingAfterPhotoUrl: pendingAfterPhotoUrl ?? this.pendingAfterPhotoUrl,
    currentStatus: currentStatus ?? this.currentStatus,
    statusHistory: statusHistory ?? this.statusHistory,
    assignedTo: assignedTo ?? this.assignedTo,
    assignedDepartment: assignedDepartment ?? this.assignedDepartment,
    assignedDepartmentUserId:
        assignedDepartmentUserId ?? this.assignedDepartmentUserId,
    adminVerificationRemarks:
        adminVerificationRemarks ?? this.adminVerificationRemarks,
    progressUpdates: progressUpdates ?? this.progressUpdates,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isAnonymous: isAnonymous,
    urgencyLevel: urgencyLevel ?? this.urgencyLevel,
  );
}
