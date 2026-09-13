import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// EmailJS credentials — replace with your own from emailjs.com
// ─────────────────────────────────────────────────────────────────────────────
const _kEmailJsServiceId  = 'YOUR_SERVICE_ID';
const _kEmailJsTemplateId = 'YOUR_TEMPLATE_ID';
const _kEmailJsPublicKey  = 'YOUR_PUBLIC_KEY';

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

Future<bool> _sendOtpEmail(String email, String otp) async {
  try {
    final res = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _kEmailJsServiceId,
        'template_id': _kEmailJsTemplateId,
        'user_id': _kEmailJsPublicKey,
        'template_params': {
          'to_email': email,
          'otp_code': otp,
          'app_name': 'iPILA',
        },
      }),
    );
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<bool> _emailExistsInFirestore(String email) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email.toLowerCase())
      .limit(1)
      .get();
  return snap.docs.isNotEmpty;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Enter a password';
  if (v.length < 8) return 'At least 8 characters required';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain an uppercase letter';
  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
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
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFoci  = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 0;

  // Step 3
  final _pwFormKey     = GlobalKey<FormState>();
  final _pwCtrl        = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _obscurePw      = true;
  bool _obscureConfirm = true;

  String get _email => _emailCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFoci) f.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: send OTP ────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final exists = await _emailExistsInFirestore(_email);
    if (!exists) {
      if (mounted) setState(() { _loading = false; _error = 'No account found for this email.'; });
      return;
    }

    final otp = _generateOtp();
    await _saveOtp(_email, otp);
    final sent = await _sendOtpEmail(_email, otp);

    if (!mounted) return;
    if (sent) {
      setState(() { _loading = false; _step = _Step.otp; _resendCountdown = 60; });
      _startCountdown();
    } else {
      setState(() { _loading = false; _error = 'Failed to send OTP. Check your EmailJS setup.'; });
    }
  }

  void _startCountdown() async {
    while (_resendCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
    }
  }

  // ── Step 2: verify OTP ──────────────────────────────────────────────────────

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

  // ── Step 3: set new password ────────────────────────────────────────────────

  Future<void> _setPassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      // Sign in silently to update password
      final methods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(_email);

      if (methods.isEmpty) throw Exception('No account found.');

      // Use Firebase password reset (email link approach)
      // Since we verified OTP we know they own this email.
      // We'll use Admin-style: re-auth isn't possible without current password,
      // so we use sendPasswordResetEmail as the actual password change mechanism
      // AND delete the OTP so it can't be reused.
      await _deleteOtp(_email);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);

      if (mounted) setState(() { _loading = false; _step = _Step.done; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _step == _Step.done
            ? const SizedBox.shrink()
            : BackButton(
                color: Colors.black87,
                onPressed: () {
                  if (_step == _Step.email) {
                    context.pop();
                  } else if (_step == _Step.otp) {
                    setState(() { _step = _Step.email; _error = null; });
                  } else if (_step == _Step.newPassword) {
                    setState(() { _step = _Step.otp; _error = null; });
                  }
                },
              ),
        title: Text(
          _step == _Step.email
              ? 'Forgot Password'
              : _step == _Step.otp
                  ? 'Verify OTP'
                  : _step == _Step.newPassword
                      ? 'New Password'
                      : 'Done',
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SingleChildScrollView(
            key: ValueKey(_step),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: switch (_step) {
              _Step.email      => _EmailStep(
                  formKey: _emailFormKey,
                  ctrl:    _emailCtrl,
                  loading: _loading,
                  error:   _error,
                  onSubmit: _sendOtp,
                ),
              _Step.otp        => _OtpStep(
                  email:       _email,
                  ctrls:       _otpCtrls,
                  foci:        _otpFoci,
                  loading:     _loading,
                  error:       _error,
                  countdown:   _resendCountdown,
                  onVerify:    _verifyOtpStep,
                  onResend: () async {
                    final otp = _generateOtp();
                    await _saveOtp(_email, otp);
                    await _sendOtpEmail(_email, otp);
                    for (final c in _otpCtrls) c.clear();
                    if (mounted) {
                      setState(() { _resendCountdown = 60; _error = null; });
                      _startCountdown();
                    }
                  },
                ),
              _Step.newPassword => _NewPasswordStep(
                  formKey:        _pwFormKey,
                  pwCtrl:         _pwCtrl,
                  confirmCtrl:    _pwConfirmCtrl,
                  obscurePw:      _obscurePw,
                  obscureConfirm: _obscureConfirm,
                  loading:        _loading,
                  error:          _error,
                  onTogglePw:      () => setState(() => _obscurePw = !_obscurePw),
                  onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmit:       _setPassword,
                ),
              _Step.done       => _DoneStep(email: _email),
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _EmailStep({
    required this.formKey,
    required this.ctrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 56, color: Color(0xFF6366F1)),
          const SizedBox(height: 20),
          const Text('Reset your password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          const SizedBox(height: 10),
          const Text(
            "Enter your registered email address. We'll send a 6-digit OTP to verify it's you.",
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          if (error != null) _ErrorRow(error!),
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Send OTP', loading: loading, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  final String email;
  final List<TextEditingController> ctrls;
  final List<FocusNode> foci;
  final bool loading;
  final String? error;
  final int countdown;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpStep({
    required this.email,
    required this.ctrls,
    required this.foci,
    required this.loading,
    required this.error,
    required this.countdown,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: Color(0xFF6366F1)),
        const SizedBox(height: 20),
        const Text('Enter OTP',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
        const SizedBox(height: 10),
        Text(
          'A 6-digit code was sent to $email.\nEnter it below. Code expires in 10 minutes.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
        ),
        const SizedBox(height: 32),
        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextFormField(
                controller: ctrls[i],
                focusNode: foci[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    foci[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    foci[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        if (error != null) _ErrorRow(error!),
        const SizedBox(height: 28),
        _PrimaryButton(label: 'Verify OTP', loading: loading, onPressed: onVerify),
        const SizedBox(height: 16),
        Center(
          child: countdown > 0
              ? Text('Resend OTP in ${countdown}s',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))
              : TextButton(
                  onPressed: onResend,
                  child: const Text('Resend OTP',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1))),
                ),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController pwCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePw;
  final bool obscureConfirm;
  final bool loading;
  final String? error;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const _NewPasswordStep({
    required this.formKey,
    required this.pwCtrl,
    required this.confirmCtrl,
    required this.obscurePw,
    required this.obscureConfirm,
    required this.loading,
    required this.error,
    required this.onTogglePw,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 56, color: Color(0xFF6366F1)),
          const SizedBox(height: 20),
          const Text('Set New Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
          const SizedBox(height: 10),
          const Text(
            'Choose a strong password for your account.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Text(
              '• At least 8 characters\n• At least one uppercase letter\n• At least one number',
              style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: pwCtrl,
            obscureText: obscurePw,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: onTogglePw,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: confirmCtrl,
            obscureText: obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: onToggleConfirm,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (v) => v == pwCtrl.text ? null : 'Passwords do not match',
          ),
          if (error != null) _ErrorRow(error!),
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Reset Password', loading: loading, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  final String email;
  const _DoneStep({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_outline_rounded, size: 80, color: Color(0xFF10B981)),
        const SizedBox(height: 24),
        const Text('Password Reset Sent',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'A password reset link has also been sent to $email.\n\n'
          'Click the link in the email to confirm your new password.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.7),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back to Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
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
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
