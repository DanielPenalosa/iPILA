import 'package:cloud_firestore/cloud_firestore.dart';

class OrdinanceModel {
  final String id;
  final String title;
  final String number;
  final String category;
  final String description;
  final String content;
  final String? fileUrl;
  final DateTime dateEnacted;
  final DateTime createdAt;
  final bool isActive;
  final List<String> tags;

  OrdinanceModel({
    required this.id,
    required this.title,
    required this.number,
    required this.category,
    required this.description,
    required this.content,
    this.fileUrl,
    required this.dateEnacted,
    required this.createdAt,
    this.isActive = true,
    this.tags = const [],
  });

  factory OrdinanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrdinanceModel(
      id: doc.id,
      title: data['title'] ?? '',
      number: data['number'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      fileUrl: data['fileUrl'],
      dateEnacted: _parseDate(data['dateEnacted']),
      createdAt: _parseDate(data['createdAt']),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'number': number,
    'category': category,
    'description': description,
    'content': content,
    'fileUrl': fileUrl,
    'dateEnacted': Timestamp.fromDate(dateEnacted),
    'createdAt': Timestamp.fromDate(createdAt),
    'isActive': isActive,
    'tags': tags,
  };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static const List<String> categories = [
    'Traffic & Transportation',
    'Waste Management',
    'Public Safety',
    'Health & Sanitation',
    'Business & Commerce',
    'Environment',
    'Social Services',
    'General Administration',
  ];
}
