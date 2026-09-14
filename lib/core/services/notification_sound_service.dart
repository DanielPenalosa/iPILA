import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('playNotificationSound')
external void _playNotificationSoundJs();

/// Plays a short chime sound on web via Web Audio API.
/// On mobile this is a no-op for now (no audio file needed for web).
class NotificationSoundService {
  static final NotificationSoundService instance = NotificationSoundService._();
  NotificationSoundService._();

  bool enabled = true;

  void play() {
    if (!enabled) return;
    if (kIsWeb) {
      try {
        _playNotificationSoundJs();
      } catch (_) {}
    }
  }
}
