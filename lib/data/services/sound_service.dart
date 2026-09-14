import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static AudioPlayer? _player;
  static bool _isEnabled = true;
  static bool _isLooping = false;

  // Initialize player lazily
  static AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Enable or disable sound notifications
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Play notification sound once
  static Future<void> playNotificationSound() async {
    if (!_isEnabled) return;
    
    try {
      await player.stop();
      await player.play(AssetSource('sounds/notification.mp3'));
      debugPrint('🔊 Played notification sound (single)');
    } catch (e) {
      debugPrint('🔊 Sound playback error: $e');
      if (kDebugMode) {
        print('Sound playback error: $e');
      }
    }
  }

  /// Play notification sound in loop until stopped
  static Future<void> playNotificationLoop() async {
    if (!_isEnabled) {
      debugPrint('🔊 Sound not enabled');
      return;
    }
    
    if (_isLooping) {
      debugPrint('🔊 Sound already looping');
      return;
    }
    
    try {
      debugPrint('🔊 Starting sound loop...');
      debugPrint('🔊 Attempting to load: sounds/notification.mp3');
      _isLooping = true;
      
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);
      
      final source = AssetSource('sounds/notification.mp3');
      await player.play(source);
      
      debugPrint('🔊 Sound loop started successfully');
      debugPrint('🔊 Player state: ${await player.getDuration()}');
    } catch (e, stackTrace) {
      _isLooping = false;
      debugPrint('🔊 ❌ Sound loop error: $e');
      debugPrint('🔊 ❌ This usually means:');
      debugPrint('🔊 ❌ 1. Sound file is missing from assets/sounds/notification.mp3');
      debugPrint('🔊 ❌ 2. Sound file format is not supported');
      debugPrint('🔊 ❌ 3. Browser blocked audio (check permissions)');
      if (kDebugMode) {
        print('Sound loop error: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Stop the looping notification sound
  static Future<void> stopNotificationLoop() async {
    try {
      debugPrint('🔊 Stopping sound loop...');
      _isLooping = false;
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      debugPrint('🔊 Sound loop stopped');
    } catch (e) {
      debugPrint('🔊 Sound stop error: $e');
      if (kDebugMode) {
        print('Sound stop error: $e');
      }
    }
  }

  /// Check if sound is currently looping
  static bool get isLooping => _isLooping;

  /// Dispose the audio player
  static Future<void> dispose() async {
    await player.dispose();
    _player = null;
  }
}
