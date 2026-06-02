// iPILA Database Seed Script
// Run with: flutter run -d chrome -t lib/seed_database.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'iPILA Seed',
      debugShowCheckedModeBanner: false,
      home: SeedScreen(),
    );
  }
}

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final List<_LogEntry> _log = [];
  bool _running = false;
  bool _done = false;

  static const _adminEmail = 'admin@pila.gov.ph';
  static const _adminPassword = 'Admin@iPILA2024';
  static const _adminName = 'LGU Admin';
  static const _adminPhone = '09000000000';

  void _addLog(String msg, {bool isError = false, bool isSuccess = false}) {
    setState(
      () => _log.add(_LogEntry(msg, isError: isError, isSuccess: isSuccess)),
    );
  }

  Future<void> _runSeed() async {
    setState(() {
      _running = true;
      _log.clear();
      _done = false;
    });
    try {
      await _seedAdmin();
      await _seedFaqs();
      await _seedOrdinances();
      await _seedNotification();
      _addLog('');
      _addLog('All done! Database is ready.', isSuccess: true);
      setState(() => _done = true);
    } catch (e) {
      _addLog('Error: $e', isError: true);
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _seedAdmin() async {
    _addLog('Creating admin account...');
    try {
      UserCredential cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );
        _addLog('  Auth user created: ${cred.user!.uid}');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _addLog('  Auth user already exists, signing in...');
          cred = await _auth.signInWithEmailAndPassword(
            email: _adminEmail,
            password: _adminPassword,
          );
        } else {
          rethrow;
        }
      }
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'fullName': _adminName,
        'email': _adminEmail,
        'phone': _adminPhone,
        'barangay': 'Pila',
        'role': 'superadmin',
        'approvalStatus': 'approved',
        'isActive': true,
        'photoUrl': null,
        'idPhotoUrl': null,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      _addLog('  Admin document set (uid: $uid)', isSuccess: true);
    } catch (e) {
      _addLog('  Admin setup failed: $e', isError: true);
      rethrow;
    }
  }

  Future<void> _seedFaqs() async {
    _addLog('Seeding FAQs...');
    final faqs = [
      {
        'question': 'How do I report an issue?',
        'answer':
            'Tap the + button at the bottom of the home screen, fill in the category, add a photo, capture your GPS location, then tap Submit Report.',
        'order': 1,
      },
      {
        'question': 'How long does it take to resolve a report?',
        'answer':
            'The LGU aims to respond within 3–5 business days. You can track the live status of your report in the My Reports tab.',
        'order': 2,
      },
      {
        'question': 'Can I submit a report anonymously?',
        'answer':
            'Yes. When submitting a report, toggle the Submit Anonymously switch. Your name will not be visible to the public.',
        'order': 3,
      },
      {
        'question': 'How do I contact the Municipal Hall?',
        'answer':
            'You can reach the Municipality of Pila at (049) 559-0000 or visit the Municipal Hall at Pila, Laguna (8AM–5PM, Mon–Fri).',
        'order': 4,
      },
      {
        'question': 'What types of issues can I report?',
        'answer':
            'You can report Road Damage, Drainage/Flooding, Broken Streetlights, Garbage/Waste, Public Facility issues, Water Supply problems, Illegal Structures, and more.',
        'order': 5,
      },
      {
        'question': 'How do I track my report status?',
        'answer':
            'Go to the My Reports tab. Each report shows a live progress tracker: Submitted → Validated → Queued → In Progress → Completed.',
        'order': 6,
      },
    ];

    for (final faq in faqs) {
      final existing = await _db
          .collection('faqs')
          .where('order', isEqualTo: faq['order'])
          .get();
      if (existing.docs.isEmpty) {
        await _db.collection('faqs').add(faq);
        _addLog('  FAQ ${faq['order']} added', isSuccess: true);
      } else {
        _addLog('  FAQ ${faq['order']} already exists, skipped');
      }
    }
  }

  Future<void> _seedOrdinances() async {
    _addLog('Seeding Ordinances...');
    final ordinances = [
      {
        'title': 'Solid Waste Management Ordinance',
        'number': '2023-001',
        'category': 'Waste Management',
        'description':
            'An ordinance regulating solid waste collection and disposal in the Municipality of Pila.',
        'content':
            'Section 1. All residents are required to segregate biodegradable and non-biodegradable waste.\n\nSection 2. Garbage collection schedule shall be posted in each barangay hall.\n\nSection 3. Violations shall be subject to fines as prescribed by RA 9003.',
        'fileUrl': null,
        'dateEnacted': Timestamp.fromDate(DateTime(2023, 5, 1)),
        'createdAt': Timestamp.now(),
        'isActive': true,
        'tags': ['waste', 'environment', 'sanitation'],
      },
      {
        'title': 'Anti-Littering Ordinance',
        'number': '2022-005',
        'category': 'Environment',
        'description':
            'An ordinance prohibiting littering in public places within the Municipality of Pila.',
        'content':
            'Section 1. It is prohibited to throw, dump, or deposit garbage in any public place.\n\nSection 2. Violators shall be fined P500 for the first offense, P1,000 for the second, and P2,000 plus community service for the third offense.',
        'fileUrl': null,
        'dateEnacted': Timestamp.fromDate(DateTime(2022, 3, 15)),
        'createdAt': Timestamp.now(),
        'isActive': true,
        'tags': ['littering', 'environment', 'public'],
      },
      {
        'title': 'Road Safety and Traffic Management Ordinance',
        'number': '2023-003',
        'category': 'Traffic & Transportation',
        'description':
            'An ordinance establishing traffic rules and road safety measures in Pila, Laguna.',
        'content':
            'Section 1. All motorists must observe traffic signs and signals within the municipality.\n\nSection 2. Parking in designated no-parking zones is strictly prohibited.\n\nSection 3. Violations are subject to fines and impoundment as prescribed by law.',
        'fileUrl': null,
        'dateEnacted': Timestamp.fromDate(DateTime(2023, 8, 10)),
        'createdAt': Timestamp.now(),
        'isActive': true,
        'tags': ['traffic', 'road', 'safety'],
      },
      {
        'title': 'Public Health and Sanitation Ordinance',
        'number': '2021-002',
        'category': 'Health & Sanitation',
        'description':
            'An ordinance promoting public health and sanitation standards in the Municipality of Pila.',
        'content':
            'Section 1. All establishments must maintain clean and sanitary premises.\n\nSection 2. Regular health inspections shall be conducted by the Municipal Health Office.\n\nSection 3. Non-compliant establishments shall be subject to closure orders.',
        'fileUrl': null,
        'dateEnacted': Timestamp.fromDate(DateTime(2021, 6, 20)),
        'createdAt': Timestamp.now(),
        'isActive': true,
        'tags': ['health', 'sanitation', 'public'],
      },
    ];

    for (final ord in ordinances) {
      final existing = await _db
          .collection('ordinances')
          .where('number', isEqualTo: ord['number'])
          .get();
      if (existing.docs.isEmpty) {
        await _db.collection('ordinances').add(ord);
        _addLog('  Ordinance ${ord['number']} added', isSuccess: true);
      } else {
        _addLog('  Ordinance ${ord['number']} already exists, skipped');
      }
    }
  }

  Future<void> _seedNotification() async {
    _addLog('Seeding welcome notification...');
    final existing = await _db
        .collection('notifications')
        .where('title', isEqualTo: 'Welcome to iPILA')
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('notifications').add({
        'title': 'Welcome to iPILA',
        'body':
            'Thank you for using iPILA — the Integrated Public Information & Local Access system of the Municipality of Pila, Laguna.',
        'type': 'info',
        'targetAll': true,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
      _addLog('  Welcome notification added', isSuccess: true);
    } else {
      _addLog('  Notification already exists, skipped');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('iPILA Database Seeder'),
        backgroundColor: const Color(0xFF2F5EF7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will create:\n'
                    '• Admin account  (admin@pila.gov.ph / Admin@iPILA2024)\n'
                    '• 6 FAQ documents\n'
                    '• 4 Ordinance documents\n'
                    '• 1 Welcome notification\n\n'
                    'Safe to run multiple times — skips existing data.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _running ? null : _runSeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F5EF7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _running
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _done
                                  ? '✅ Done — Run Again'
                                  : 'Run Database Seed',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_log.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) {
                      final entry = _log[i];
                      return Text(
                        entry.msg,
                        style: TextStyle(
                          color: entry.isError
                              ? Colors.red[300]
                              : entry.isSuccess
                              ? Colors.green[300]
                              : Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogEntry {
  final String msg;
  final bool isError;
  final bool isSuccess;
  const _LogEntry(this.msg, {this.isError = false, this.isSuccess = false});
}
