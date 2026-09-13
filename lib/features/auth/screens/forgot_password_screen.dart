import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text.trim());
    if (mounted) {
      setState(() {
        _loading = false;
        if (ok) {
          _sent = true;
        } else {
          _error = 'Something went wrong. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: _sent
              ? _SuccessBody(email: _emailCtrl.text.trim())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_reset_rounded,
                          size: 56, color: Color(0xFF6366F1)),
                      const SizedBox(height: 20),
                      const Text(
                        'Reset your password',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter the email address you used when signing up. '
                        "We'll send you a link to reset your password.",
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text(
                                  'Send Reset Link',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final String email;
  const _SuccessBody({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_read_outlined,
            size: 80, color: Color(0xFF10B981)),
        const SizedBox(height: 24),
        const Text(
          'Check your inbox',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to:\n\n$email\n\n'
          'Click the link in the email to create a new password.',
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF6B7280), height: 1.7),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your new password must be at least 8 characters '
                  'and contain an uppercase letter and a number.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF9A3412), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Back to Login',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
