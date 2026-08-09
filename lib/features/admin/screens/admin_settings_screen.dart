import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/utils/download_helper.dart' as download_helper;
import '../../../data/services/report_service.dart';
import 'admin_shell.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _selectedSection = 0;

  static const _sections = [
    'Issue Categories',
    'Barangays',
    'Notifications',
    'Account',
    'System',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: '/admin/settings',
      child: Column(
        children: [
          const AdminPageHeader(title: 'Settings'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings sidebar
                Container(
                  width: 200,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      selected: _selectedSection == i,
                      selectedTileColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.08,
                      ),
                      selectedColor: AppTheme.primaryBlue,
                      title: Text(
                        _sections[i],
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => setState(() => _selectedSection = i),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildSection(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_selectedSection) {
      case 0:
        return const _CategoriesSection();
      case 1:
        return const _BarangaysSection();
      case 2:
        return const _NotificationsSection();
      case 3:
        return const _AccountSection();
      case 4:
        return const _SystemSection();
      default:
        return const SizedBox();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection();

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  final _ctrl = TextEditingController();
  final List<String> _categories = List.from(AppConstants.issueCategories);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Issue Categories',
      subtitle:
          'Manage the categories residents can select when submitting reports.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Add new category...',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AdminHoverButton(
                label: 'Add',
                onTap: () {
                  if (_ctrl.text.trim().isNotEmpty) {
                    setState(() {
                      _categories.add(_ctrl.text.trim());
                      _ctrl.clear();
                    });
                  }
                },
                color: AppTheme.primaryBlue,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (c) => Chip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _categories.remove(c)),
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.08,
                    ),
                    side: BorderSide(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarangaysSection extends StatelessWidget {
  const _BarangaysSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Barangays',
      subtitle: 'Barangays of the Municipality of Pila, Laguna.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AppConstants.barangays
            .map(
              (b) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(b, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  bool _newReports = true;
  bool _overdueAlerts = true;
  bool _statusUpdates = false;
  bool _weeklyDigest = true;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notification Settings',
      subtitle: 'Configure which events trigger admin notifications.',
      child: Column(
        children: [
          _Toggle(
            label: 'New report submitted',
            sub: 'Notify when a citizen submits a new report',
            value: _newReports,
            onChanged: (v) => setState(() => _newReports = v),
          ),
          _Toggle(
            label: 'Overdue alerts',
            sub: 'Notify when a report passes its resolution deadline',
            value: _overdueAlerts,
            onChanged: (v) => setState(() => _overdueAlerts = v),
          ),
          _Toggle(
            label: 'Status updates',
            sub: 'Notify when report status changes',
            value: _statusUpdates,
            onChanged: (v) => setState(() => _statusUpdates = v),
          ),
          _Toggle(
            label: 'Weekly digest',
            sub: 'Receive a weekly summary of all activity',
            value: _weeklyDigest,
            onChanged: (v) => setState(() => _weeklyDigest = v),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminHoverButton(
              label: 'Save Preferences',
              onTap: () {},
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryYellow.withValues(alpha: 0.5),
            activeColor: AppTheme.primaryYellow,
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatefulWidget {
  const _AccountSection();

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Import firebase_auth to get current user and re-authenticate
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Change to new password
      await user.updatePassword(_newPasswordCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Password changed successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Clear form
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Error changing password';
        if (e.code == 'wrong-password') {
          message = 'Current password is incorrect';
        } else if (e.code == 'weak-password') {
          message = 'New password is too weak';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Change Password',
      subtitle: 'Update your admin account password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Password
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current Password',
                hintText: 'Enter your current password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'Current password is required'
                  : null,
            ),
            const SizedBox(height: 12),

            // New Password
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password (min. 6 characters)',
                prefixIcon: const Icon(Icons.lock_reset, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'New password is required';
                }
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                hintText: 'Re-enter new password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (v != _newPasswordCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Change Password Button
            if (_isLoading)
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Changing Password...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              )
            else
              AdminHoverButton(
                label: 'Change Password',
                onTap: _changePassword,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

class _SystemSection extends StatefulWidget {
  const _SystemSection();

  @override
  State<_SystemSection> createState() => _SystemSectionState();
}

class _SystemSectionState extends State<_SystemSection> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Appearance',
          subtitle: 'Customize the look of the admin portal.',
          child: _Toggle(
            label: 'Dark Mode',
            sub: 'Switch to dark theme (coming soon)',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Data Management',
          subtitle: 'Manage system data and backups.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DangerBtn(
                label: 'Update FAQs',
                icon: Icons.help_outline,
                color: AppTheme.primaryBlue,
                onTap: () => _updateFaqs(context),
              ),
              const SizedBox(height: 8),
              _DangerBtn(
                label: 'Export All Reports',
                icon: Icons.download_outlined,
                color: AppTheme.primaryYellow,
                onTap: () => _exportAllReports(context),
              ),
              const SizedBox(height: 8),
              _DangerBtn(
                label: 'Clear Completed Reports',
                icon: Icons.delete_sweep_outlined,
                color: AppTheme.primaryOrange,
                onTap: () => _showConfirm(
                  context,
                  'Archive all completed reports? This will permanently delete them from the database.',
                  () => _clearCompletedReports(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'About iPILA',
          subtitle: 'System information.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'System', value: 'iPILA v1.0.0'),
              _InfoRow(label: 'Municipality', value: 'Pila, Laguna'),
              _InfoRow(label: 'Province', value: 'Laguna'),
              _InfoRow(label: 'Database', value: 'Firebase Firestore'),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirm(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          AdminHoverButton(
            label: 'Cancel',
            onTap: () => Navigator.pop(context),
            outlined: true,
            small: true,
          ),
          const SizedBox(width: 8),
          AdminHoverButton(
            label: 'Confirm',
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
            color: AppTheme.primaryYellow,
            small: true,
          ),
        ],
      ),
    );
  }

  Future<void> _updateFaqs(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = FirebaseFirestore.instance;

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Updating FAQs...'),
            ],
          ),
          duration: Duration(hours: 1),
        ),
      );

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
              'No. All reports require user authentication to ensure accountability and enable effective follow-up communication. This helps the LGU verify report authenticity, prevent spam or duplicate submissions, and maintain direct contact with you for updates, clarifications, or resolution confirmation.',
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
        {
          'question': 'Can I edit or delete my report after submission?',
          'answer':
              'No. Once submitted, reports cannot be edited or deleted to maintain data integrity. If you need to update information, contact the Municipal Hall directly or add a comment in the report details.',
          'order': 7,
        },
        {
          'question': 'What is the Community Reports section?',
          'answer':
              'Community Reports lets you see all public reports submitted by other residents in your area. You can follow-up on reports to show support and track progress on issues affecting your community.',
          'order': 8,
        },
        {
          'question': 'How do I view municipal ordinances?',
          'answer':
              'Tap the Laws tab at the bottom navigation. You can browse all municipal ordinances, search by keyword or category, and view full ordinance details including enforcement dates and penalties.',
          'order': 9,
        },
        {
          'question': 'What does it mean to follow-up on a report?',
          'answer':
              'Following-up on a report shows your support for that issue and helps prioritize community concerns. You will also receive notifications when the report status changes.',
          'order': 10,
        },
        {
          'question': 'Will I receive notifications about my reports?',
          'answer':
              'Yes. You will receive push notifications when your report status changes (validated, queued, in progress, completed) or when administrators add comments or updates.',
          'order': 11,
        },
        {
          'question': 'Is my personal information safe?',
          'answer':
              'Yes. iPILA uses Firebase Authentication and Firestore security rules to protect your data. Your personal information is only visible to LGU administrators and is never shared publicly.',
          'order': 12,
        },
        {
          'question': 'Can I attach photos to my report?',
          'answer':
              'Yes. You can attach up to 3 photos when submitting a report. Clear photos help administrators assess the issue and prioritize response. Make sure images are relevant and show the problem clearly.',
          'order': 13,
        },
        {
          'question': 'What if my report location is incorrect?',
          'answer':
              'Make sure location services are enabled on your device. The app automatically captures your GPS coordinates when you submit a report. If the pin is slightly off, administrators can still identify the general area.',
          'order': 14,
        },
      ];

      int updated = 0;
      int added = 0;

      for (final faq in faqs) {
        final existing = await db
            .collection('faqs')
            .where('order', isEqualTo: faq['order'])
            .get();

        if (existing.docs.isEmpty) {
          await db.collection('faqs').add(faq);
          added++;
        } else {
          await existing.docs.first.reference.update(faq);
          updated++;
        }
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Updated $updated FAQs, added $added new FAQs'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating FAQs: $e'),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _exportAllReports(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Check if running on web
    if (!kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Export feature is only available on web'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
      return;
    }

    try {
      // Show loading in SnackBar
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Exporting reports...'),
            ],
          ),
          duration: Duration(hours: 1),
        ),
      );

      // Fetch all reports
      final reports = await ReportService().getAllReports().first;

      // Create CSV content
      final csvLines = <String>[];

      // Header
      csvLines.add(
        'ID,Category,Description,Barangay,Address,Latitude,Longitude,'
        'Status,Reporter,Anonymous,Created,Updated,Followers',
      );

      // Data rows
      for (final report in reports) {
        csvLines.add(
          '"${report.id}",'
          '"${_escapeCsv(report.category)}",'
          '"${_escapeCsv(report.description)}",'
          '"${_escapeCsv(report.barangay)}",'
          '"${_escapeCsv(report.address)}",'
          '${report.latitude},'
          '${report.longitude},'
          '"${report.currentStatus}",'
          '"${report.isAnonymous ? "Anonymous" : _escapeCsv(report.userFullName)}",'
          '${report.isAnonymous},'
          '"${report.createdAt.toIso8601String()}",'
          '"${report.updatedAt.toIso8601String()}",'
          '${report.followerCount}',
        );
      }

      final csvContent = csvLines.join('\n');
      final bytes = utf8.encode(csvContent);

      // Download file using helper
      final filename =
          'ipila_reports_${DateTime.now().millisecondsSinceEpoch}.csv';
      download_helper.downloadFile(filename, bytes);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Exported ${reports.length} reports to CSV'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error exporting reports: $e'),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }

  Future<void> _clearCompletedReports(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Show loading in SnackBar (no dialog!)
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Clearing completed reports...'),
            ],
          ),
          duration: Duration(hours: 1), // Long duration, will hide manually
        ),
      );

      // Get all completed reports
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('currentStatus', isEqualTo: AppConstants.statusCompleted)
          .get();

      // Delete in batches (Firestore limit is 500 per batch)
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        count++;
      }

      await batch.commit();

      // Hide loading, show success
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Cleared $count completed reports'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading, show error
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error clearing reports: $e'),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _DangerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DangerBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
