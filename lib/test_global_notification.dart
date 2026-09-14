import 'package:flutter/material.dart';
import 'core/services/global_notification_manager.dart';

/// Temporary test widget - Add this to any admin screen to test notifications
/// Usage: Add TestGlobalNotificationButton() anywhere in your build method
class TestGlobalNotificationButton extends StatelessWidget {
  const TestGlobalNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 20,
      child: FloatingActionButton.extended(
        onPressed: () {
          debugPrint('🧪 TEST BUTTON CLICKED - Calling GlobalNotificationManager');
          GlobalNotificationManager.showNotification(
            title: 'Test Direct Call',
            message: 'Testing GlobalNotificationManager direct call!',
            type: 'new_report',
            reportId: 'test-direct-123',
          );
        },
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.bug_report),
        label: const Text('Test Global Manager'),
      ),
    );
  }
}

/// Alternative: Simple button version
class TestGlobalNotificationButtonSimple extends StatelessWidget {
  const TestGlobalNotificationButtonSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        debugPrint('🧪 SIMPLE TEST CLICKED');
        GlobalNotificationManager.showNotification(
          title: 'Simple Test',
          message: 'If you see this popup, GlobalNotificationManager works!',
          type: 'new_report',
          reportId: null,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.science),
      label: const Text('Test Global Manager'),
    );
  }
}
