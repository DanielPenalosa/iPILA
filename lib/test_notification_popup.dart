import 'package:flutter/material.dart';
import 'core/widgets/notification_popup.dart';

/// Test widget to manually trigger notification popup
/// Add this to a screen temporarily to test if popup works
class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        debugPrint('🧪 TEST: Manually triggering notification popup');
        NotificationPopup.show(
          context: context,
          title: 'Test Notification',
          message: 'This is a test popup with looping sound',
          type: 'new_report',
          reportId: 'test-123',
        );
      },
      child: const Icon(Icons.notification_add),
      tooltip: 'Test Notification Popup',
    );
  }
}
