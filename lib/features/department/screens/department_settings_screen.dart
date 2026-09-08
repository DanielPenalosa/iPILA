import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class DepartmentSettingsScreen extends StatefulWidget {
  const DepartmentSettingsScreen({super.key});

  @override
  State<DepartmentSettingsScreen> createState() =>
      _DepartmentSettingsScreenState();
}

class _DepartmentSettingsScreenState extends State<DepartmentSettingsScreen> {
  int _section = 0;

  static const _sections = [
    _Section('Profile', Icons.person_outline_rounded),
    _Section('Change Password', Icons.lock_outline_rounded),
    _Section('Notifications', Icons.notifications_outlined),
    _Section('About', Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings sidebar
        Container(
          width: 200,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...List.generate(_sections.length, (i) {
                final s = _sections[i];
                final active = _section == i;
                return _SectionTile(
                  label: s.label,
                  icon: s.icon,
                  active: active,
                  onTap: () => setState(() => _section = i),
                );
              }),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFF3F4F6)),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_section) {
      case 0:
        return const _ProfileSection();
      case 1:
        return const _ChangePasswordSection();
      case 2:
        return const _NotificationsSection();
      case 3:
        return const _AboutSection();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Section tile ──────────────────────────────────────────────────────────────

class _SectionTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SectionTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                : _hovered
                ? const Color(0xFFF9FAFB)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: widget.active
                    ? const Color(0xFF6366F1)
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.active
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: widget.active
                      ? const Color(0xFF6366F1)
                      : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Section ───────────────────────────────────────────────────────────

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Profile',
          subtitle: 'Your account information for this department portal.',
        ),
        const SizedBox(height: 24),

        // Avatar + department badge
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'D',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.department ?? 'Department',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        _Card(
          child: Column(
            children: [
              _Field(
                label: 'Full Name',
                controller: _nameCtrl,
                icon: Icons.person_outline,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _Field(
                label: 'Email',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                enabled: false,
                hint: 'Contact admin to change email',
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _Field(
                label: 'Phone',
                controller: _phoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ReadOnlyField(
                label: 'Department',
                value: user?.department ?? '—',
                icon: Icons.business_outlined,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ReadOnlyField(
                label: 'Role',
                value: 'Department Staff',
                icon: Icons.badge_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerLeft,
          child: _SaveButton(
            saving: _saving,
            onSave: () async {
              setState(() => _saving = true);
              try {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance
                      .collection(AppConstants.usersCollection)
                      .doc(uid)
                      .update({
                        'fullName': _nameCtrl.text.trim(),
                        'phone': _phoneCtrl.text.trim(),
                      });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Change Password Section ───────────────────────────────────────────────────

class _ChangePasswordSection extends StatefulWidget {
  const _ChangePasswordSection();

  @override
  State<_ChangePasswordSection> createState() => _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends State<_ChangePasswordSection> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Change Password',
          subtitle:
              'Update your login password. Use a strong, unique password.',
        ),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            children: [
              _PasswordField(
                label: 'Current Password',
                controller: _currentCtrl,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _PasswordField(
                label: 'New Password',
                controller: _newCtrl,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _PasswordField(
                label: 'Confirm New Password',
                controller: _confirmCtrl,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Password strength hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use at least 8 characters with a mix of letters, numbers, and symbols.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: _SaveButton(
            label: 'Update Password',
            saving: _saving,
            onSave: () async {
              if (_newCtrl.text != _confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              if (_newCtrl.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 8 characters'),
                  ),
                );
                return;
              }
              setState(() => _saving = true);
              try {
                final user = FirebaseAuth.instance.currentUser!;
                final cred = EmailAuthProvider.credential(
                  email: user.email!,
                  password: _currentCtrl.text,
                );
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(_newCtrl.text);
                _currentCtrl.clear();
                _newCtrl.clear();
                _confirmCtrl.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Failed to update password'),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Notifications Section ─────────────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  bool _newAssignment = true;
  bool _revisionRequest = true;
  bool _statusUpdate = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Notifications',
          subtitle: 'Choose what events trigger notifications for you.',
        ),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            children: [
              _Toggle(
                title: 'New Report Assigned',
                subtitle:
                    'Get notified when admin assigns a new report to your department.',
                value: _newAssignment,
                onChanged: (v) => setState(() => _newAssignment = v),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _Toggle(
                title: 'Revision Requested',
                subtitle:
                    'Get notified when admin returns a report for revision.',
                value: _revisionRequest,
                onChanged: (v) => setState(() => _revisionRequest = v),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _Toggle(
                title: 'Status Updates',
                subtitle:
                    'Get notified when the status of any assigned report changes.',
                value: _statusUpdate,
                onChanged: (v) => setState(() => _statusUpdate = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: _SaveButton(
            saving: false,
            onSave: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification preferences saved'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'About',
          subtitle: 'Information about the iPILA system.',
        ),
        const SizedBox(height: 24),
        _Card(
          child: Column(
            children: [
              _ReadOnlyField(
                label: 'App Name',
                value: 'iPILA',
                icon: Icons.apps_rounded,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ReadOnlyField(
                label: 'Full Name',
                value: 'Integrated Public Information & Local Access',
                icon: Icons.info_outline,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ReadOnlyField(
                label: 'Municipality',
                value: 'Municipality of Pila, Laguna',
                icon: Icons.location_city_outlined,
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _ReadOnlyField(
                label: 'Portal',
                value: 'Department Staff Portal',
                icon: Icons.badge_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Log out of the department portal.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Section {
  final String label;
  final IconData icon;
  const _Section(this.label, this.icon);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final String? hint;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 14),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 13,
                color: enabled
                    ? const Color(0xFF111111)
                    : const Color(0xFF9CA3AF),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 14),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111111)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Color(0xFFD1D5DB)),
          const SizedBox(width: 14),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final String label;
  const _SaveButton({
    required this.saving,
    required this.onSave,
    this.label = 'Save Changes',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: saving ? null : onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
  }
}
