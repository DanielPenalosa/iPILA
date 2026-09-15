import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// One-time cleanup script to remove users that were marked as deleted
/// Run this once to clean up any accounts deleted with the old code
/// 
/// Usage: dart run lib/cleanup_deleted_users.dart
void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  print('🔍 Searching for deleted users...');

  // Find users marked as deleted
  final deletedUsers = await db
      .collection('users')
      .where('approvalStatus', isEqualTo: 'deleted')
      .get();

  print('Found ${deletedUsers.docs.length} users marked as deleted');

  if (deletedUsers.docs.isEmpty) {
    print('✅ No deleted users found. Database is clean!');
    return;
  }

  // Show what will be deleted
  print('\n📋 Users to be removed:');
  for (final doc in deletedUsers.docs) {
    final data = doc.data();
    print('  - ${data['fullName']} (${data['email']}) - ${data['role']}');
  }

  print('\n🗑️  Deleting ${deletedUsers.docs.length} user documents...');

  // Delete them permanently
  final batch = db.batch();
  for (final doc in deletedUsers.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();

  print('✅ Cleanup complete! Removed ${deletedUsers.docs.length} deleted users.');
  print('\n💡 Tip: Refresh your browser with Ctrl+Shift+R to see changes.');
}
