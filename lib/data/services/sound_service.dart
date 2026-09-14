import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isEnabled = true;

  /// Enable or disable sound notifications
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Play notification sound
  static Future<void> playNotificationSound() async {
    if (!_isEnabled) return;
    
    try {
      if (kIsWeb) {
        // For web, use asset path
        await _player.play(AssetSource('sounds/notification.mp3'));
      } else {
        // For mobile
        await _player.play(AssetSource('sounds/notification.mp3'));
      }
    } catch (e) {
      // Silent fail - don't block notification flow
      if (kDebugMode) {
        print('Sound playback error: $e');
      }
    }
  }

  /// Dispose the audio player
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
