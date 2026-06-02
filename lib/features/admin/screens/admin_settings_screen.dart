import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_ui.dart';
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
            activeColor: AppTheme.primaryBlue,
          ),
        ],
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
                label: 'Export All Reports',
                icon: Icons.download_outlined,
                color: AppTheme.primaryBlue,
                onTap: () => _showConfirm(
                  context,
                  'Export all report data to CSV?',
                  () {},
                ),
              ),
              const SizedBox(height: 8),
              _DangerBtn(
                label: 'Clear Completed Reports',
                icon: Icons.delete_sweep_outlined,
                color: Colors.orange,
                onTap: () => _showConfirm(
                  context,
                  'Archive all completed reports? This cannot be undone.',
                  () {},
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
            color: AppTheme.primaryBlue,
            small: true,
          ),
        ],
      ),
    );
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
