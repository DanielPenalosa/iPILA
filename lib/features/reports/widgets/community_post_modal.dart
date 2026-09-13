import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — call this to open the modal
// ─────────────────────────────────────────────────────────────────────────────

void showCommunityPostModal(
  BuildContext context,
  ReportModel report, {
  bool isAdmin = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommunityPostModal(report: report, isAdmin: isAdmin),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal widget
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPostModal extends StatefulWidget {
  final ReportModel report;
  final bool isAdmin;

  const CommunityPostModal({
    super.key,
    required this.report,
    required this.isAdmin,
  });

  @override
  State<CommunityPostModal> createState() => _CommunityPostModalState();
}

class _CommunityPostModalState extends State<CommunityPostModal> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = ReportService();
  int _photoIndex = 0;
  bool _submittingComment = false;
  bool _togglingHeart = false;

  // keys for scroll-to
  final _ratingKey = GlobalKey();
  final _commentsKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _urgencyColor(String? u) {
    if (u == 'Critical') return const Color(0xFFDC2626);
    if (u == 'Moderate') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    final report = widget.report;
    final screenH = MediaQuery.of(context).size.height;

    return StreamBuilder<ReportModel?>(
      stream: _service.getReport(report.id),
      builder: (context, snap) {
        final live = snap.data ?? report;
        final liveHearted = live.hearts.contains(uid);

        return Container(
          height: screenH * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── drag handle ────────────────────────────────────────────
              _DragHandle(),

              // ── scrollable body ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── before / after side by side ────────────────────
                      _BeforeAfterCarousel(
                        beforeUrls: live.photoUrls,
                        afterUrl: live.afterPhotoUrl,
                        index: _photoIndex,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── action row ─────────────────────────────────
                            Row(
                              children: [
                                // heart
                                if (!widget.isAdmin) ...[
                                  _ActionIcon(
                                    icon: liveHearted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: liveHearted
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF374151),
                                    loading: _togglingHeart,
                                    onTap: () async {
                                      if (uid.isEmpty) return;
                                      setState(() => _togglingHeart = true);
                                      await _service.toggleHeart(
                                          live.id, uid);
                                      if (mounted) {
                                        setState(
                                            () => _togglingHeart = false);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                // comment icon
                                if (!widget.isAdmin)
                                  _ActionIcon(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    color: const Color(0xFF374151),
                                    onTap: () => _scrollTo(_commentsKey),
                                  ),
                                const Spacer(),
                                if (!widget.isAdmin && uid.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _scrollTo(_ratingKey),
                                    child: _StarRatingButton(
                                      reportId: live.id,
                                      uid: uid,
                                      service: _service,
                                      auth: auth,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ── heart & follower count ──────────────────────
                            Row(
                              children: [
                                if (live.heartCount > 0) ...[
                                  Text(
                                    '${live.heartCount} ${live.heartCount == 1 ? 'like' : 'likes'}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111111)),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (live.followerCount > 0)
                                  Text(
                                    '${live.followerCount} following up',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── reporter & category ─────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Avatar(name: live.isAnonymous
                                    ? '?'
                                    : live.userFullName),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            live.isAnonymous
                                                ? 'Anonymous'
                                                : live.userFullName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111111)),
                                          ),
                                          const SizedBox(width: 6),
                                          _CategoryChip(
                                              label: live.category),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeago.format(live.createdAt),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── description ─────────────────────────────────
                            Text(
                              live.description,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                  height: 1.5),
                            ),
                            const SizedBox(height: 14),

                            // ── info chips ──────────────────────────────────
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.location_on_outlined,
                                  label: 'Brgy. ${live.barangay}',
                                  color: const Color(0xFF6366F1),
                                ),
                                _StatusChip(status: live.currentStatus),
                                if (live.urgencyLevel != null)
                                  _InfoChip(
                                    icon: live.urgencyLevel == 'Critical'
                                        ? Icons.arrow_upward_rounded
                                        : live.urgencyLevel == 'Minor'
                                            ? Icons.arrow_downward_rounded
                                            : Icons.remove_rounded,
                                    label: live.urgencyLevel!,
                                    color: _urgencyColor(live.urgencyLevel),
                                  ),
                                if (live.assignedDepartment != null)
                                  _InfoChip(
                                    icon: Icons.business_outlined,
                                    label: live.assignedDepartment!,
                                    color: Colors.purple,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── timeline: reported → resolved ───────────────
                            _ReportTimeline(report: live),
                            const SizedBox(height: 16),

                            // ── before/after ────────────────────────────────
                            if (live.afterPhotoUrl != null &&
                                live.photoUrls.isNotEmpty) ...[
                              _SectionHeader(label: 'Before & After'),
                              const SizedBox(height: 10),
                              _BeforeAfterRow(
                                beforeUrl: live.photoUrls.first,
                                afterUrl: live.afterPhotoUrl!,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── rating ───────────────────────────────────────
                            SizedBox(
                              key: _ratingKey,
                              child: _RatingSection(
                                reportId: live.id,
                                uid: uid,
                                isAdmin: widget.isAdmin,
                                service: _service,
                                auth: auth,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── comments ────────────────────────────────────
                            SizedBox(
                              key: _commentsKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionHeader(label: 'Comments'),
                                  const SizedBox(height: 10),
                                  _CommentsSection(
                                      reportId: live.id, service: _service),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── comment input (citizen only) ───────────────────────────
              if (!widget.isAdmin)
                _CommentInput(
                  controller: _commentCtrl,
                  submitting: _submittingComment,
                  onSubmit: () async {
                    final text = _commentCtrl.text.trim();
                    if (text.isEmpty || uid.isEmpty) return;
                    setState(() => _submittingComment = true);
                    await _service.addComment(
                      reportId: live.id,
                      userId: uid,
                      userFullName:
                          auth.user?.fullName ?? 'Citizen',
                      text: text,
                    );
                    _commentCtrl.clear();
                    if (mounted) {
                      setState(() => _submittingComment = false);
                    }
                    // scroll to bottom
                    await Future.delayed(
                        const Duration(milliseconds: 200));
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl.animateTo(
                        _scrollCtrl.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// Shows before and after side by side — no swiping needed
class _BeforeAfterCarousel extends StatelessWidget {
  final List<String> beforeUrls;
  final String? afterUrl;
  final int index;
  final ValueChanged<int> onPageChanged;

  const _BeforeAfterCarousel({
    required this.beforeUrls,
    required this.afterUrl,
    required this.index,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (afterUrl != null && beforeUrls.isNotEmpty) {
      // Side-by-side before/after
      return SizedBox(
        height: 260,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    beforeUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image_outlined,
                          color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BEFORE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    afterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image_outlined,
                          color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('AFTER',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No after photo — show original photos as paged carousel
    if (beforeUrls.isEmpty) {
      return Container(
        height: 260,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_not_supported_outlined,
            size: 48, color: Color(0xFFD1D5DB)),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            onPageChanged: onPageChanged,
            itemCount: beforeUrls.length,
            itemBuilder: (_, i) => Image.network(
              beforeUrls[i],
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.broken_image_outlined,
                    size: 48, color: Color(0xFFD1D5DB)),
              ),
            ),
          ),
        ),
        if (beforeUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                beforeUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 26, color: color),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
          letterSpacing: 0.1),
    );
  }
}

class _BeforeAfterRow extends StatelessWidget {
  final String beforeUrl;
  final String afterUrl;

  const _BeforeAfterRow(
      {required this.beforeUrl, required this.afterUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PhotoLabel(url: beforeUrl, label: 'BEFORE')),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              color: Color(0xFF10B981), size: 22),
        ),
        Expanded(child: _PhotoLabel(url: afterUrl, label: 'AFTER', isAfter: true)),
      ],
    );
  }
}

class _PhotoLabel extends StatelessWidget {
  final String url;
  final String label;
  final bool isAfter;

  const _PhotoLabel(
      {required this.url, required this.label, this.isAfter = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isAfter
                ? const Color(0xFF10B981)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isAfter ? Colors.white : Colors.grey[600])),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final String reportId;
  final ReportService service;

  const _CommentsSection(
      {required this.reportId, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getComments(reportId),
      builder: (context, snap) {
        final comments = snap.data ?? [];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No comments yet. Be the first to comment.',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
          );
        }
        return Column(
          children: comments.map((c) => _CommentTile(data: c)).toList(),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CommentTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['userFullName'] as String? ?? 'Citizen';
    final text = data['text'] as String? ?? '';
    final ts = data['createdAt'];
    DateTime? date;
    if (ts != null) {
      try {
        date = (ts as dynamic).toDate() as DateTime;
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                AppTheme.primaryBlue.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$name ',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111)),
                      ),
                      TextSpan(
                        text: text,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      timeago.format(date),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF)),
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

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  const _CommentInput({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFD1D5DB)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                      color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: submitting ? null : onSubmit,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: submitting
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded,
                      size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating section
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSection extends StatefulWidget {
  final String reportId;
  final String uid;
  final bool isAdmin;
  final ReportService service;
  final AuthProvider auth;

  const _RatingSection({
    required this.reportId,
    required this.uid,
    required this.isAdmin,
    required this.service,
    required this.auth,
  });

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  int _selected = 0;   // citizen's pending pick (0 = none yet)
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportFeedback>>(
      stream: widget.service.getFeedback(widget.reportId),
      builder: (context, snap) {
        final feedbacks = snap.data ?? [];
        final total = feedbacks.length;
        final avg = total == 0
            ? 0.0
            : feedbacks.map((f) => f.rating).reduce((a, b) => a + b) / total;

        // find logged-in citizen's existing rating
        final mine = feedbacks.where((f) => f.userId == widget.uid).firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header + average ─────────────────────────────────────────
            Row(
              children: [
                const _SectionHeader(label: 'Ratings'),
                const Spacer(),
                if (total > 0) ...[
                  Icon(Icons.star_rounded, size: 15, color: Colors.amber[600]),
                  const SizedBox(width: 3),
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111)),
                  ),
                  Text(
                    '  ($total)',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // ── citizen rate widget ──────────────────────────────────────
            if (!widget.isAdmin && widget.uid.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: mine != null
                    // already rated — show it
                    ? Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < mine.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22,
                            color: Colors.amber[600],
                          )),
                          const SizedBox(width: 10),
                          const Text('Your rating',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      )
                    // not yet rated — show interactive stars
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate the resolution',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111111)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (i) {
                              final star = i + 1;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selected = star),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    star <= _selected
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 32,
                                    color: Colors.amber[600],
                                  ),
                                ),
                              );
                            }),
                          ),
                          if (_selected > 0) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () async {
                                        setState(() => _submitting = true);
                                        await widget.service.submitFeedback(
                                          reportId: widget.reportId,
                                          userId: widget.uid,
                                          userFullName:
                                              widget.auth.user?.fullName ??
                                                  'Citizen',
                                          rating: _selected,
                                          comment: '',
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _submitting = false;
                                            _selected = 0;
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Submit Rating',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
            ],

            // ── list of ratings ──────────────────────────────────────────
            if (feedbacks.isEmpty)
              const Text('No ratings yet.',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
            else
              ...feedbacks.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: Text(
                            f.userFullName.isNotEmpty
                                ? f.userFullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(f.userFullName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111111))),
                                  const SizedBox(width: 8),
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < f.rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 13,
                                      color: Colors.amber[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (f.comment.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(f.comment,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF374151))),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }
}

// ── Timeline: reported → resolved ────────────────────────────────────────────

class _ReportTimeline extends StatelessWidget {
  final ReportModel report;
  const _ReportTimeline({required this.report});

  @override
  Widget build(BuildContext context) {
    final resolvedEntry = report.statusHistory
        .where((h) => h.status == 'Resolved')
        .firstOrNull;

    // auto message based on category — never uses admin remarks
    final resolveMsg = resolvedEntry != null
        ? 'The ${report.category.toLowerCase()} issue in Brgy. ${report.barangay} has been successfully resolved.'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: 'Timeline'),
        const SizedBox(height: 10),
        _TimelineDot(
          label: 'Reported',
          date: report.createdAt,
          message: null,
          color: const Color(0xFF6366F1),
          isFirst: true,
        ),
        _TimelineDot(
          label: 'Resolved',
          date: resolvedEntry?.timestamp,
          message: resolveMsg,
          color: const Color(0xFF10B981),
          isFirst: false,
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? message;
  final Color color;
  final bool isFirst;

  const _TimelineDot({
    required this.label,
    required this.date,
    required this.message,
    required this.color,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              if (!isFirst)
                Container(width: 2, height: 20, color: const Color(0xFFE5E7EB)),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: date != null ? color : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: date != null ? color : Colors.grey[400]!,
                ),
              ),
              if (date != null)
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(date!),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              if (message != null) ...[
                const SizedBox(height: 3),
                Text(
                  message!,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Star rating icon button → opens rating bottom sheet ──────────────────────

class _StarRatingButton extends StatelessWidget {
  final String reportId;
  final String uid;
  final ReportService service;
  final AuthProvider auth;

  const _StarRatingButton({
    required this.reportId,
    required this.uid,
    required this.service,
    required this.auth,
  });

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(
        reportId: reportId,
        uid: uid,
        service: service,
        auth: auth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportFeedback>>(
      stream: service.getFeedback(reportId),
      builder: (context, snap) {
        final feedbacks = snap.data ?? [];
        final mine = feedbacks.where((f) => f.userId == uid).firstOrNull;
        final total = feedbacks.length;
        final avg = total == 0
            ? 0.0
            : feedbacks.map((f) => f.rating).reduce((a, b) => a + b) / total;

        return GestureDetector(
          onTap: () => _open(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mine != null ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 26,
                color: mine != null
                    ? Colors.amber[600]!
                    : const Color(0xFF374151),
              ),
              if (total > 0) ...[
                const SizedBox(width: 4),
                Text(
                  avg.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Rating bottom sheet ───────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final String reportId;
  final String uid;
  final ReportService service;
  final AuthProvider auth;

  const _RatingSheet({
    required this.reportId,
    required this.uid,
    required this.service,
    required this.auth,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _selected = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: StreamBuilder<List<ReportFeedback>>(
        stream: widget.service.getFeedback(widget.reportId),
        builder: (context, snap) {
          final feedbacks = snap.data ?? [];
          final mine =
              feedbacks.where((f) => f.userId == widget.uid).firstOrNull;
          final total = feedbacks.length;
          final avg = total == 0
              ? 0.0
              : feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
                  total;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text('Ratings',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (total > 0) ...[
                      Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 3),
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('  ($total)',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF))),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (mine != null)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < mine.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 28,
                          color: Colors.amber[600],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Your rating',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280))),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rate the resolution',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111))),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return GestureDetector(
                            onTap: () => setState(() => _selected = star),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                star <= _selected
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 36,
                                color: Colors.amber[600],
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_selected > 0) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    setState(() => _submitting = true);
                                    await widget.service.submitFeedback(
                                      reportId: widget.reportId,
                                      userId: widget.uid,
                                      userFullName:
                                          widget.auth.user?.fullName ??
                                              'Citizen',
                                      rating: _selected,
                                      comment: '',
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _submitting = false;
                                        _selected = 0;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Text('Submit Rating',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                if (feedbacks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...feedbacks.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppTheme.primaryBlue.withValues(alpha: 0.12),
                              child: Text(
                                f.userFullName.isNotEmpty
                                    ? f.userFullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(f.userFullName,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111111))),
                                    const SizedBox(width: 8),
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < f.rating
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 13,
                                        color: Colors.amber[600],
                                      ),
                                    ),
                                  ]),
                                  if (f.comment.isNotEmpty)
                                    Text(f.comment,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF374151))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
