import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';

// ── Firebase Web API key ──────────────────────────────────────────────────────
const _kFirebaseApiKey = 'AIzaSyBGVfY9YBPiQ5KkAsSU_PKPCp3SJNCXbfw';

import '../../../core/config/secrets.dart';

// ── Gmail OAuth credentials loaded from secrets.dart (git-ignored) ───────────
const _kGmailClientId     = kGmailClientId;
const _kGmailClientSecret = kGmailClientSecret;
const _kGmailRefreshToken = kGmailRefreshToken;
const _kGmailSenderEmail  = kGmailSenderEmail;

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _generateOtp() =>
    (100000 + Random.secure().nextInt(900000)).toString();

Future<void> _saveOtp(String email, String otp) async {
  await FirebaseFirestore.instance
      .collection('otp_codes')
      .doc(email.toLowerCase())
      .set({
    'otp': otp,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresAt': Timestamp.fromDate(
        DateTime.now().toUtc().add(const Duration(minutes: 10))),
  });
}

Future<bool> _verifyOtp(String email, String otp) async {
  final doc = await FirebaseFirestore.instance
      .collection('otp_codes')
      .doc(email.toLowerCase())
      .get();
  if (!doc.exists) return false;
  final data = doc.data()!;
  final storedOtp = data['otp'] as String?;
  final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
  if (storedOtp == null || expiresAt == null) return false;
  if (DateTime.now().toUtc().isAfter(expiresAt)) return false;
  return storedOtp == otp.trim();
}

Future<void> _deleteOtp(String email) async {
  await FirebaseFirestore.instance
      .collection('otp_codes')
      .doc(email.toLowerCase())
      .delete();
}

Future<bool> _sendOtpEmail(String toEmail, String otp) async {
  try {
    // Step 1 — exchange refresh token for access token
    final tokenRes = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id':     _kGmailClientId,
        'client_secret': _kGmailClientSecret,
        'refresh_token': _kGmailRefreshToken,
        'grant_type':    'refresh_token',
      },
    );

    if (tokenRes.statusCode != 200) {
      debugPrint('Gmail token error: ${tokenRes.body}');
      return false;
    }

    final accessToken =
        (jsonDecode(tokenRes.body) as Map<String, dynamic>)['access_token'] as String?;
    if (accessToken == null) {
      debugPrint('Gmail: access_token missing in response');
      return false;
    }

    // Step 2 — build RFC 2822 email and base64url-encode it
    final emailBody = '''
<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px;">
  <h2 style="color:#111;font-size:20px;margin-bottom:4px;">iPILA Password Reset</h2>
  <p style="color:#888;font-size:13px;margin-top:0;">Municipality of Pila, Laguna</p>
  <p style="color:#444;font-size:15px;">Your one-time verification code is:</p>
  <div style="background:#FFF7E0;border:2px solid #F2B705;border-radius:12px;
              padding:28px;text-align:center;margin:20px 0;">
    <span style="font-size:42px;font-weight:900;letter-spacing:14px;color:#111;">$otp</span>
  </div>
  <p style="color:#888;font-size:13px;">
    This code expires in <b>10 minutes</b>.<br>
    Do not share this code with anyone.
  </p>
  <hr style="border:none;border-top:1px solid #eee;margin:20px 0;">
  <p style="color:#bbb;font-size:11px;text-align:center;">
    iPILA — Integrated Public Information &amp; Local Access
  </p>
</div>''';

    final rawMessage = [
      'From: iPILA <$_kGmailSenderEmail>',
      'To: $toEmail',
      'Subject: Your iPILA Password Reset Code',
      'MIME-Version: 1.0',
      'Content-Type: text/html; charset=UTF-8',
      '',
      emailBody,
    ].join('\r\n');

    // base64url encoding (no padding) as required by Gmail API
    final encoded = base64Url.encode(utf8.encode(rawMessage))
        .replaceAll('=', '');

    // Step 3 — send via Gmail API
    final sendRes = await http.post(
      Uri.parse(
          'https://gmail.googleapis.com/gmail/v1/users/me/messages/send'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'raw': encoded}),
    );

    debugPrint('Gmail send status: ${sendRes.statusCode}');
    debugPrint('Gmail send body: ${sendRes.body}');
    return sendRes.statusCode == 200 || sendRes.statusCode == 200;
  } catch (e) {
    debugPrint('Gmail send error: $e');
    return false;
  }
}

/// After OTP is verified, reset password using Firebase Auth REST API.
/// Uses sendOobCode to get the reset code, then confirmPasswordReset with it.
Future<String?> _resetPasswordInApp(String email, String newPassword) async {
  try {
    // Request a password reset oobCode from Firebase
    final codeRes = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_kFirebaseApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestType': 'PASSWORD_RESET',
        'email': email,
      }),
    );

    debugPrint('Firebase oobCode status: ${codeRes.statusCode}');
    debugPrint('Firebase oobCode body: ${codeRes.body}');

    if (codeRes.statusCode != 200) {
      final err = jsonDecode(codeRes.body);
      return err['error']?['message'] ?? 'Failed to initiate reset.';
    }

    final codeBody = jsonDecode(codeRes.body);
    final oobCode = codeBody['oobCode'] as String?;

    if (oobCode != null) {
      // oobCode returned — directly confirm the password reset
      final resetRes = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=$_kFirebaseApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oobCode': oobCode,
          'newPassword': newPassword,
        }),
      );

      debugPrint('Reset status: ${resetRes.statusCode} — ${resetRes.body}');

      if (resetRes.statusCode == 200) return null; // success
      final resetErr = jsonDecode(resetRes.body);
      return resetErr['error']?['message'] ?? 'Password reset failed.';
    }

    // oobCode not in response (production Firebase behaviour) —
    // Firebase sent the reset email. We can't change the password
    // in-app without Admin SDK. Return a special marker.
    return 'email_link_sent';
  } catch (e) {
    debugPrint('Reset error: $e');
    return 'Network error. Please try again.';
  }
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Enter a password';
  if (v.length < 8) return 'At least 8 characters required';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain an uppercase letter';
  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen — 3 steps: Email → OTP → New Password
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { email, otp, newPassword, done }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;

  // Step 1
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();

  // Step 2
  final _otpCtrls     = List.generate(6, (_) => TextEditingController());
  final _otpFoci      = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 0;

  // Step 3
  final _pwFormKey     = GlobalKey<FormState>();
  final _pwCtrl        = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscurePw      = true;
  bool _obscureConfirm = true;

  String get _email => _emailCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFoci) f.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1 ──────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final otp = _generateOtp();
    await _saveOtp(_email, otp);
    final sent = await _sendOtpEmail(_email, otp);

    if (!mounted) return;
    if (sent) {
      setState(() { _loading = false; _step = _Step.otp; _resendCountdown = 60; });
      _startCountdown();
    } else {
      // EmailJS not set up yet — go to OTP step anyway for testing
      setState(() { _loading = false; _step = _Step.otp; _resendCountdown = 60; });
      _startCountdown();
    }
  }

  void _startCountdown() async {
    while (_resendCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
    }
  }

  // ── Step 2 ──────────────────────────────────────────────────────────────────

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  Future<void> _verifyOtpStep() async {
    if (_otpValue.length < 6) {
      setState(() => _error = 'Enter all 6 digits.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final valid = await _verifyOtp(_email, _otpValue);
    if (!mounted) return;
    if (valid) {
      setState(() { _loading = false; _step = _Step.newPassword; });
    } else {
      setState(() { _loading = false; _error = 'Invalid or expired OTP. Try again.'; });
    }
  }

  // ── Step 3 ──────────────────────────────────────────────────────────────────

  Future<void> _resetPassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await _resetPasswordInApp(_email, _pwCtrl.text);
    await _deleteOtp(_email);

    if (!mounted) return;
    if (result == null) {
      // Password changed successfully in-app
      setState(() { _loading = false; _step = _Step.done; });
    } else if (result == 'email_link_sent') {
      // Firebase didn't return oobCode — password reset email was sent instead
      setState(() {
        _loading = false;
        _error = 'Firebase sent a reset link to $_email.\n'
            'Please click the link in that email to set your new password, '
            'then come back and log in.';
      });
    } else {
      setState(() { _loading = false; _error = result; });
    }
  }

  // ── Back navigation ─────────────────────────────────────────────────────────

  void _goBack() {
    if (_step == _Step.email) {
      context.pop();
    } else if (_step == _Step.otp) {
      setState(() { _step = _Step.email; _error = null; });
    } else if (_step == _Step.newPassword) {
      setState(() { _step = _Step.otp; _error = null; });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == _Step.done
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textDark, size: 20),
                onPressed: _goBack,
              ),
        title: Text(
          switch (_step) {
            _Step.email       => 'Forgot Password',
            _Step.otp         => 'Verify OTP',
            _Step.newPassword => 'New Password',
            _Step.done        => '',
          },
          style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        // Step indicator
        bottom: _step != _Step.done
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: switch (_step) {
                    _Step.email       => 0.33,
                    _Step.otp         => 0.66,
                    _Step.newPassword => 1.0,
                    _Step.done        => 1.0,
                  },
                  backgroundColor: AppTheme.lightGray,
                  color: AppTheme.primaryYellow,
                  minHeight: 4,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: SingleChildScrollView(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: switch (_step) {
              _Step.email       => _buildEmailStep(),
              _Step.otp         => _buildOtpStep(),
              _Step.newPassword => _buildNewPasswordStep(),
              _Step.done        => _buildDoneStep(),
            },
          ),
        ),
      ),
    );
  }

  // ── Step widgets ─────────────────────────────────────────────────────────────

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Reset your password',
            subtitle: 'Enter your registered email address and we\'ll send a 6-digit OTP to verify it\'s you.',
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendOtp(),
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 28),
          _ActionButton(label: 'Send OTP', loading: _loading, onPressed: _sendOtp),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          icon: Icons.shield_outlined,
          title: 'Enter OTP',
          subtitle: 'A 6-digit code was sent to $_email. It expires in 10 minutes.',
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => SizedBox(
            width: 46,
            height: 56,
            child: TextField(
              controller: _otpCtrls[i],
              focusNode: _otpFoci[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryYellow, width: 2)),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _otpFoci[i + 1].requestFocus();
                if (v.isEmpty && i > 0) _otpFoci[i - 1].requestFocus();
              },
            ),
          )),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 28),
        _ActionButton(label: 'Verify', loading: _loading, onPressed: _verifyOtpStep),
        const SizedBox(height: 16),
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Resend OTP in ${_resendCountdown}s',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted),
                )
              : TextButton(
                  onPressed: () async {
                    final otp = _generateOtp();
                    await _saveOtp(_email, otp);
                    await _sendOtpEmail(_email, otp);
                    for (final c in _otpCtrls) c.clear();
                    _otpFoci[0].requestFocus();
                    if (mounted) setState(() { _resendCountdown = 60; _error = null; });
                    _startCountdown();
                  },
                  child: const Text('Resend OTP',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange)),
                ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Form(
      key: _pwFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.lock_outline_rounded,
            title: 'Set new password',
            subtitle: 'Create a strong password for your account.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleRow(text: 'At least 8 characters'),
                SizedBox(height: 4),
                _RuleRow(text: 'At least one uppercase letter'),
                SizedBox(height: 4),
                _RuleRow(text: 'At least one number'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _pwCtrl,
            obscureText: _obscurePw,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePw
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) =>
                v == _pwCtrl.text ? null : 'Passwords do not match',
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 28),
          _ActionButton(
              label: 'Reset Password',
              loading: _loading,
              onPressed: _resetPassword),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              size: 52, color: AppTheme.primaryYellow),
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Updated!',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Your password has been reset successfully.\nYou can now log in with your new password.',
          style: TextStyle(
              fontSize: 14, color: AppTheme.textMuted, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 28, color: AppTheme.primaryYellow),
        ),
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textMuted, height: 1.5)),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String text;
  const _RuleRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 14, color: AppTheme.primaryOrange),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 15, color: AppTheme.coral),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.coral)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryYellow,
          foregroundColor: AppTheme.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppTheme.black))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
