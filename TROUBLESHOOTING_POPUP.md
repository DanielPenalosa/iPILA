# Troubleshooting Notification Popup

## Steps to Debug

### 1. Check if notification listener is running

Open browser DevTools console and look for:
```
🔔 ===== STARTING NOTIFICATION LISTENER =====
🔔 User ID: [some-id]
🔔 Started at: [timestamp]
🔔 Global navigator key available: true
🔔 Global navigator context available: true
```

**If you don't see this:** The listener didn't start. Check:
- Is the user logged in as admin?
- Does the app reach the MaterialApp.router builder?

### 2. Submit a test report

From another browser/user account, submit a report.

### 3. Check for notification detection

Look for:
```
🔔 ----- Notification snapshot received -----
🔔 Number of notifications: X
🔔 Processing notification:
🔔   ID: [notification-id]
🔔   Title: New Report: [category]
🔔   Type: new_report
🔔   ReportId: [report-id]
🔔   Created: [timestamp]
🔔   Full data keys: [list of keys]
```

**If you see "⏰ Old notification":** The notification was created before the listener started. This is expected for existing notifications.

**If you see "🆕 NEW NOTIFICATION DETECTED!":** Good! Continue to step 4.

### 4. Check popup trigger

Look for:
```
🔔   📢 Triggering popup...
🔔   🎯 Post-frame callback executing...
🔔   ✅ Using global navigator context
🔔   🚀 Showing popup NOW!
```

**Then look for:**
```
🎯 NotificationPopup.show called
🎯   Title: [title]
🎯   Type: new_report
🎯   ReportId: [id]
🎯   Context mounted: true
🎯 Starting sound loop...
🎯 Inserting overlay into root...
🎯 ✅ Popup shown successfully
```

### 5. Common Issues

#### Issue: "❌ ERROR: No valid context available!"
**Solution:** The global navigator key isn't set properly.
- Check if `setNavigatorKey` was called in main.dart
- Verify the app is using the correct router configuration

#### Issue: "Old notification" for all notifications
**Solution:** The `_lastNotificationTime` is set to now when the listener starts, so it only shows NEW notifications after that point.
- This is by design to avoid showing old popups
- Wait for a NEW report to be submitted AFTER logging in as admin

#### Issue: Popup shows but disappears immediately
**Solution:** Check if there are multiple notification listeners or popup dismissal logic running

#### Issue: "🔔 Already listening for user: [id]"
**Solution:** Listener is already running. This is normal if you navigate between screens.

### 6. Manual Test

You can manually test the popup from the Reports screen test button:
1. Navigate to `/admin/reports`
2. Click the orange "Show Test Popup" button
3. If this works but real notifications don't, the issue is in the notification listener logic, not the popup itself

### 7. Check Firestore

Verify notifications are being created:
1. Open Firebase Console
2. Go to Firestore Database
3. Check `notifications` collection
4. Look for documents with:
   - `userId`: should match your admin UID
   - `type`: should be "new_report"
   - `reportId`: should exist
   - `createdAt`: should be recent

### 8. Check User Role

Verify the admin account has the correct role:
1. Open Firestore Database
2. Go to `users` collection
3. Find your admin user document
4. Check `role` field should be "admin" or "superadmin"

## Quick Fix: Force Show Popup

If debugging doesn't help, you can force show the popup by adding a button temporarily:

In any admin screen, add:
```dart
FloatingActionButton(
  onPressed: () {
    NotificationPopup.show(
      context: context,
      title: 'Force Test',
      message: 'Testing popup visibility',
      type: 'new_report',
      reportId: 'test-123',
    );
  },
  child: Icon(Icons.bug_report),
)
```

If this shows the popup, then the issue is with the notification listener, not the popup component.
