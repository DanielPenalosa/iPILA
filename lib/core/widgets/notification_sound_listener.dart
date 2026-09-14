import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/notification_sound_service.dart';

/// Drop this widget anywhere in the tree for a logged-in user.
/// It listens to their unread notifications and plays a chime
/// whenever the count increases (i.e. a new notification arrives).
class NotificationSoundListener extends StatefulWidget {
  final String userId;
  final Widget child;

  const NotificationSoundListener({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<NotificationSoundListener> createState() =>
      _NotificationSoundListenerState();
}

class _NotificationSoundListenerState
    extends State<NotificationSoundListener> {
  int _prevCount = -1; // -1 means not yet initialised

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return widget.child;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: widget.userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasData) {
          final count = snap.data!.docs.length;
          if (_prevCount == -1) {
            // First load — just record baseline, no sound
            _prevCount = count;
          } else if (count > _prevCount) {
            // New notification(s) arrived — play chime
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationSoundService.instance.play();
            });
            _prevCount = count;
          } else {
            _prevCount = count;
          }
        }
        return widget.child;
      },
    );
  }
}
