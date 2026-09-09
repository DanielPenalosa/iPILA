import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _selectedBarangay;

  bool _editing = false;
  bool _saving = false;
  bool _changingPassword = false;

  XFile? _newPhotoWeb;
  File? _newPhoto;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(
      text: (user?.phone ?? '').replaceFirst('+63', ''),
    );
    _selectedBarangay = user?.barangay;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _newPhotoWeb = picked;
      if (!kIsWeb) _newPhoto = File(picked.path);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: '+63${_phoneCtrl.text.trim()}',
      barangay: _selectedBarangay ?? auth.user?.barangay ?? '',
      newPhoto: kIsWeb ? null : _newPhoto,
      newPhotoWeb: kIsWeb ? _newPhotoWeb : null,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) {
          _editing = false;
          _newPhoto = null;
          _newPhotoWeb = null;
        }
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Update failed'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    setState(() => _changingPassword = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(auth.user?.email ?? '');
    if (mounted) {
      setState(() => _changingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Password reset email sent to ${auth.user?.email}'
            : 'Failed to send reset email'),
        backgroundColor: ok ? AppTheme.successGreen : AppTheme.coral,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final initials = user.fullName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w600)),
            )
          else ...[
            TextButton(
              onPressed: _saving ? null : () => setState(() {
                _editing = false;
                _newPhoto = null;
                _newPhotoWeb = null;
                final u = context.read<AuthProvider>().user;
                _nameCtrl.text = u?.fullName ?? '';
                _phoneCtrl.text = (u?.phone ?? '').replaceFirst('+63', '');
                _selectedBarangay = u?.barangay;
              }),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _editing ? _pickPhoto : null,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.2),
                        backgroundImage: _avatarImage(user.photoUrl),
                        child: _avatarImage(user.photoUrl) == null
                            ? Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark))
                            : null,
                      ),
                    ),
                    if (_editing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.textDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    _RoleBadge(role: user.role),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal info ────────────────────────────────────────
              _SectionLabel('Personal Information'),
              const SizedBox(height: 10),
              _Field(
                label: 'Full Name',
                icon: Icons.person_outline,
                child: _editing
                    ? TextFormField(
                        controller: _nameCtrl,
                        decoration: _dec('Full name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      )
                    : _InfoTile(value: user.fullName),
              ),
              const SizedBox(height: 10),
              _Field(
                label: 'Email',
                icon: Icons.email_outlined,
                child: _InfoTile(value: user.email, muted: true),
              ),
              const SizedBox(height: 10),
              _Field(
                label: 'Phone',
                icon: Icons.phone_outlined,
                child: _editing
                    ? TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: _dec('9XXXXXXXXX').copyWith(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 4),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.phone_outlined),
                              SizedBox(width: 4),
                              Text('+63', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone is required';
                          if (v.trim().length != 10) return '10 digits required';
                          if (!v.startsWith('9')) return 'Must start with 9';
                          return null;
                        },
                      )
                    : _InfoTile(value: user.phone),
              ),
              const SizedBox(height: 10),
              _Field(
                label: 'Barangay',
                icon: Icons.location_on_outlined,
                child: _editing
                    ? DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        decoration: _dec('Select barangay'),
                        items: AppConstants.barangays
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBarangay = v),
                        validator: (v) => v == null ? 'Select a barangay' : null,
                      )
                    : _InfoTile(value: user.barangay),
              ),
              const SizedBox(height: 10),
              _Field(
                label: 'Member Since',
                icon: Icons.calendar_today_outlined,
                child: _InfoTile(value: DateFormat('MMMM d, yyyy').format(user.createdAt)),
              ),
              const SizedBox(height: 24),

              // ── Report stats ─────────────────────────────────────────
              _SectionLabel('Your Activity'),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: ReportService().getUserReports(user.uid),
                builder: (context, snap) {
                  final reports = snap.data ?? [];
                  final resolved = reports.where((r) => r.currentStatus == AppConstants.statusResolved).length;
                  final pending = reports.where((r) => r.currentStatus == AppConstants.statusPending).length;
                  return Row(
                    children: [
                      Expanded(child: _StatTile(value: '${reports.length}', label: 'Reports Filed', color: AppTheme.primaryYellow)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(value: '$resolved', label: 'Resolved', color: AppTheme.successGreen)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(value: '$pending', label: 'Pending', color: Colors.orange)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Security ─────────────────────────────────────────────
              _SectionLabel('Security'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.lock_reset_outlined,
                label: 'Change Password',
                subtitle: 'Send a reset link to ${user.email}',
                loading: _changingPassword,
                onTap: _sendPasswordReset,
              ),
              const SizedBox(height: 24),

              // ── Account ──────────────────────────────────────────────
              _SectionLabel('Account'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.logout_outlined,
                label: 'Sign Out',
                subtitle: 'You can sign back in anytime',
                color: AppTheme.coral,
                onTap: () async {
                  final confirm = await _confirmDialog(context, 'Sign Out', 'Are you sure you want to sign out?');
                  if (confirm == true && context.mounted) {
                    context.read<AuthProvider>().signOut();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String? photoUrl) {
    if (_newPhotoWeb != null && kIsWeb) return NetworkImage(_newPhotoWeb!.path);
    if (_newPhoto != null && !kIsWeb) return FileImage(_newPhoto!);
    if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    return null;
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2)),
  );

  Future<bool?> _confirmDialog(BuildContext ctx, String title, String msg) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(title, style: const TextStyle(color: AppTheme.coral))),
        ],
      ),
    );
  }
}

// ── Small UI components ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _Field({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 4),
      child,
    ],
  );
}

class _InfoTile extends StatelessWidget {
  final String value;
  final bool muted;
  const _InfoTile({required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Text(value, style: TextStyle(fontSize: 14, color: muted ? AppTheme.textMuted : AppTheme.textDark)),
  );
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool loading;
  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap, this.color, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textDark;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role == 'superadmin' ? 'Super Admin' : role[0].toUpperCase() + role.substring(1);
    final color = role == 'admin' || role == 'superadmin'
        ? const Color(0xFFDC2626)
        : role == 'department'
            ? const Color(0xFF6366F1)
            : role == 'barangay'
                ? Colors.teal
                : AppTheme.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
