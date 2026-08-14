import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class PilaBotWidget extends StatefulWidget {
  const PilaBotWidget({super.key});

  @override
  State<PilaBotWidget> createState() => _PilaBotWidgetState();
}

class _PilaBotWidgetState extends State<PilaBotWidget> {
  bool _open = false;
  bool _typing = false;
  bool _showProfile = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      text: "Hello! 👋 I'm PilaBot, your friendly iPILA assistant! I'm here 24/7 to help you with reports, ordinances, and anything about our municipality. What can I assist you with today?",
      isBot: true,
      time: DateTime.now(),
    ),
  ];

  static const _suggestions = [
    '📝 How to report?',
    '📍 Track my report',
    '📜 Find an ordinance',
    '📞 Contact Munisipyo',
    '❓ View all FAQs',
    '🏛️ Office hours',
  ];

  static const _replies = {
    '📝 How to report?':
        'Easy! Just tap the ➕ button at the bottom of the home screen. Select your issue category, snap a photo, add your location, describe the problem, and hit Submit. I\'ll make sure it gets to the right department! 💪',
    '📍 Track my report':
        'Want to check your report status? Head to the Reports tab 📋 to see all your submissions with live updates. You\'ll see if it\'s pending, in progress, or resolved! ✅',
    '📜 Find an ordinance':
        'Looking for municipal laws? Tap the Laws tab 📚 at the bottom to browse and search all ordinances of Pila. Knowledge is power! 💡',
    '📞 Contact Munisipyo':
        'You can reach the Municipality of Pila at:\n📱 (049) 559-0000\n📍 Municipal Hall, Pila, Laguna\n⏰ Mon-Fri, 8:00 AM - 5:00 PM\n\nNeed help? We\'re here for you!',
    '🏛️ Office hours':
        'Our Municipal Hall is open:\n⏰ Monday to Friday\n🕐 8:00 AM - 5:00 PM\n\nLunch break: 12:00 PM - 1:00 PM\n\n📅 Closed on weekends and holidays',
  };

  void _send([String? preset]) {
    final text = preset ?? _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Special handling for FAQ navigation
    if (text == '❓ View all FAQs') {
      setState(() => _open = false);
      context.push('/faq');
      return;
    }

    setState(() {
      _messages.add(_ChatMsg(text: text, isBot: false, time: DateTime.now()));
      _msgCtrl.clear();
      _typing = true;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate typing delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final reply = _replies[text] ??
          "Hmm, I'm not sure about that one yet. 🤔 But don't worry! You can contact the Municipal Hall at (049) 559-0000 and they'll be happy to help you out! 😊";

      setState(() {
        _typing = false;
        _messages.add(_ChatMsg(text: reply, isBot: true, time: DateTime.now()));
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return GestureDetector(
        onTap: () => setState(() => _open = true),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Pulse ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (_, v, __) => Container(
                width: 56 * v,
                height: 56 * v,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15 * (2 - v)),
                  shape: BoxShape.circle,
                ),
              ),
              onEnd: () => setState(() {}),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x402F5EF7),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 320,
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showProfile = !_showProfile),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showProfile = !_showProfile),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PilaBot 🤖',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Always here to help!',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _open = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Profile Card (collapsible)
          if (_showProfile)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PilaBot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Text(
                    'Your AI Municipal Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _profileRow(Icons.verified, 'Official iPILA Bot'),
                  _profileRow(Icons.schedule, 'Available 24/7'),
                  _profileRow(Icons.speed, 'Instant responses'),
                  _profileRow(Icons.location_city, 'Municipality of Pila'),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 Tap my avatar anytime to view this profile',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Suggestions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions
                  .map(
                    (s) => GestureDetector(
                      onTap: () => _send(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return _BubbleRow(msg: msg);
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isBot;
  final DateTime time;
  _ChatMsg({required this.text, required this.isBot, required this.time});
}

class _BubbleRow extends StatelessWidget {
  final _ChatMsg msg;
  const _BubbleRow({required this.msg});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(msg.time);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: msg.isBot
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (msg.isBot)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = i * 0.2;
                    final value = (_controller.value - delay) % 1.0;
                    final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2)
                        .clamp(0.3, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _profileRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textDark,
          ),
        ),
      ],
    ),
  );
}
