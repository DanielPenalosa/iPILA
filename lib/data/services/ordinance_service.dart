import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ordinance_model.dart';
import '../../core/constants/app_constants.dart';

class OrdinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<OrdinanceModel>> getOrdinances({
    String? category,
    String? searchQuery,
    bool activeOnly = true,
  }) {
    // Use simple query without orderBy to avoid composite index requirements
    Query query = _db.collection(AppConstants.ordinancesCollection);

    if (activeOnly && (category == null || category.isEmpty)) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snap) {
      var list = snap.docs.map(OrdinanceModel.fromFirestore).toList();

      // Apply filters client-side
      if (activeOnly) list = list.where((o) => o.isActive).toList();
      if (category != null && category.isNotEmpty) {
        list = list.where((o) => o.category == category).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        list = list
            .where(
              (o) =>
                  o.title.toLowerCase().contains(q) ||
                  o.number.toLowerCase().contains(q) ||
                  o.description.toLowerCase().contains(q) ||
                  o.tags.any((t) => t.toLowerCase().contains(q)),
            )
            .toList();
      }

      // Sort client-side
      list.sort((a, b) => b.dateEnacted.compareTo(a.dateEnacted));
      return list;
    });
  }

  Future<void> addOrdinance(OrdinanceModel ordinance) async {
    await _db
        .collection(AppConstants.ordinancesCollection)
        .doc(ordinance.id)
        .set(ordinance.toMap());
  }

  Future<void> updateOrdinance(String id, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.ordinancesCollection)
        .doc(id)
        .update(data);
  }

  // FAQs
  Stream<List<Map<String, dynamic>>> getFaqs() {
    return _db.collection(AppConstants.faqsCollection).snapshots().map((snap) {
      final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      list.sort(
        (a, b) =>
            ((a['order'] ?? 0) as int).compareTo((b['order'] ?? 0) as int),
      );
      return list;
    });
  }
}
