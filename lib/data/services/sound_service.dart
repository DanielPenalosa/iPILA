import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isEnabled = true;
  static bool _isLooping = false;

  /// Enable or disable sound notifications
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Play notification sound once
  static Future<void> playNotificationSound() async {
    if (!_isEnabled) return;
    
    try {
      await _player.stop();
      if (kIsWeb) {
        await _player.play(AssetSource('sounds/notification.mp3'));
      } else {
        await _player.play(AssetSource('sounds/notification.mp3'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sound playback error: $e');
      }
    }
  }

  /// Play notification sound in loop until stopped
  static Future<void> playNotificationLoop() async {
    if (!_isEnabled || _isLooping) return;
    
    try {
      _isLooping = true;
      await _player.setReleaseMode(ReleaseMode.loop);
      if (kIsWeb) {
        await _player.play(AssetSource('sounds/notification.mp3'));
      } else {
        await _player.play(AssetSource('sounds/notification.mp3'));
      }
    } catch (e) {
      _isLooping = false;
      if (kDebugMode) {
        print('Sound loop error: $e');
      }
    }
  }

  /// Stop the looping notification sound
  static Future<void> stopNotificationLoop() async {
    try {
      _isLooping = false;
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      if (kDebugMode) {
        print('Sound stop error: $e');
      }
    }
  }

  /// Check if sound is currently looping
  static bool get isLooping => _isLooping;

  /// Dispose the audio player
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
